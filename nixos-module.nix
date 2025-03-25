{
  near-cli,
  ...
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.near-validator;
in
{
  options = {
    services.near-validator = {
      enable = lib.mkEnableOption "Enable the near validator.";

      pool = {
        id = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "openmesh";
          description = ''
            The staking pool the validator is running as.
          '';
        };

        version = lib.mkOption {
          type = lib.types.str;
          default = "poolv1";
          example = "pool";
          description = ''
            The staking pool factory used to create the staking contract.
          '';
        };
      };

      fast-sync = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Download snapshot to data folder before starting near node.
        '';
      };

      pinger = {
        enable = lib.mkEnableOption "Enable pinging the staking pool contract automatically on a fixed schedule.";

        schedule = {
          minimum-wait = lib.mkOption {
            type = lib.types.str;
            default = "12h";
            example = "8h";
            description = ''
              Minimum amount of time to wait between pings. See systemd timers OnUnitInactiveSec for valid options.
            '';
          };

          random-delay = lib.mkOption {
            type = lib.types.str;
            default = "1h";
            example = "0";
            description = ''
              Maximum amount of time to added to the wait between pings (randomized). See systemd timers RandomizedDelaySec for valid options.
            '';
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # https://github.com/near/nearcore/blob/master/scripts/set_kernel_params.sh
    # Not allowed to change these settings in container, should be set in host configuration instead
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 8388608;
      "net.core.wmem_max" = 8388608;
      "net.ipv4.tcp_rmem" = "4096 87380 8388608";
      "net.ipv4.tcp_wmem" = "4096 16384 8388608";
      "net.ipv4.tcp_slow_start_after_idle" = 0;
    };

    systemd.services.near-validator = {
      wantedBy = [ "multi-user.target" ];
      description = "Near Protocol Validator.";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "exec";
        StateDirectory = "near-validator";
        DynamicUser = true;
        Restart = "on-failure";
      };
      path = [
        pkgs.curl
        pkgs.bash
        pkgs.jq
        pkgs.gawk
      ] ++ lib.optionals cfg.fast-sync [ pkgs.rclone ];
      script =
        let
          dir = "/var/lib/near-validator";
          neard = lib.getExe (pkgs.callPackage ./package.nix { });
        in
        ''
          ${neard} --home ${dir} init --chain-id=mainnet --account-id="${cfg.pool.id}.${cfg.pool.version}.near" --download-genesis --download-config validator
          curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/update_boot_nodes.sh | bash -s -- mainnet ${dir}/config.json
          if ${if cfg.fast-sync then "[ -z \"$( ls -A '${dir}/data')\" ]" else "false"}; then
            curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/down_rclone.sh | DATA_PATH=${dir}/data CHAIN_ID=mainnet RPC_TYPE=fast-rpc bash
          fi
          ${neard} --home ${dir} run
        '';
    };

    systemd.timers.near-validator-pinger = lib.mkIf cfg.pinger.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnUnitInactiveSec = cfg.pinger.schedule.minimum-wait;
        RandomizedDelaySec = cfg.pinger.schedule.random-delay;
        Unit = "near-validator-pinger.service";
        Persistent = true;
      };
    };

    systemd.services.near-validator-pinger = lib.mkIf cfg.pinger.enable {
      wantedBy = [ "multi-user.target" ];
      description = "Near Protocol Validator Pinger.";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "exec";
        StateDirectory = "near-validator-pinger";
        DynamicUser = true;
        Restart = "on-failure";
      };
      environment = {
        HOME = "/var/lib/near-validator-pinger";
      };
      script =
        let
          credentialsdir = "/var/lib/near-validator-pinger/.near-credentials/mainnet";
          near = lib.getExe near-cli.packages.${pkgs.system}.default;
          account = "$( ls -A '${credentialsdir}' | sed -e 's/\.json$//')";
        in
        ''
          if [ -z "$( ls -A '${credentialsdir}' )" ]; then
            ${near} account create-account fund-later use-auto-generation save-to-folder ${credentialsdir}
          fi

          ${near} call ${cfg.pool.id}.${cfg.pool.version}.near ping '{}' --accountId ${account} --gas=300000000000000 --network-id=mainnet
        '';
    };
  };
}
