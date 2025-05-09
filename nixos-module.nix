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

      snapshot-sync = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
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

    users.groups.near-validator = { };
    users.users.near-validator = {
      isSystemUser = true;
      group = "near-validator";
    };

    systemd.services.near-validator =
      let
        stateDir = "/var/lib/near-validator";
      in
      {
        wantedBy = [ "multi-user.target" ];
        description = "Near Protocol Validator.";
        after = [ "network.target" ];
        serviceConfig = {
          Type = "exec";
          StateDirectory = "near-validator";
          User = "near-validator";
          Group = "near-validator";
          Restart = "on-failure";
        };
        path =
          [
            pkgs.curl
            pkgs.jq
            pkgs.gawk
          ]
          ++ lib.optionals cfg.snapshot-sync [
            pkgs.bash
            pkgs.rclone
          ];
        environment = {
          HOME = stateDir;
        };
        script =
          let
            nearDir = "${stateDir}/.near";
            neard = lib.getExe (pkgs.callPackage ./package.nix { });
          in
          ''
            rm -rf ${nearDir}/genesis.json ${nearDir}/config.json
            ${neard} init --chain-id=mainnet --account-id="${cfg.pool.id}.${cfg.pool.version}.near" --download-genesis --download-config validator
            if ${if cfg.snapshot-sync then "[ -z \"$( ls -A '${nearDir}/data')\" ]" else "false"}; then
              curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/down_rclone.sh | DATA_PATH=${nearDir}/data CHAIN_ID=mainnet RPC_TYPE=fast-rpc bash
            fi
            ${neard} run --boot-nodes "$(curl -s -X POST https://rpc.mainnet.fastnear.com -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "network_info", "params": [], "id": "0"}' | jq '.result.active_peers as $list1 | .result.known_producers as $list2 | $list1[] as $active_peer | $list2[] | select(.peer_id == $active_peer.id) | "\(.peer_id)@\($active_peer.addr)"' | awk 'NR>2 {print ","} length($0) {print p} {p=$0}' ORS="" | sed 's/"//g')"
          '';
      };

    users.groups.near-validator-pinger = { };
    users.users.near-validator-pinger = {
      isSystemUser = true;
      group = "near-validator-pinger";
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

    systemd.services.near-validator-pinger = lib.mkIf cfg.pinger.enable (
      let
        stateDir = "/var/lib/near-validator-pinger";
      in
      {
        wantedBy = [ "multi-user.target" ];
        description = "Near Protocol Validator Pinger.";
        after = [ "network.target" ];
        serviceConfig = {
          Type = "exec";
          StateDirectory = "near-validator-pinger";
          User = "near-validator";
          Group = "near-validator";
          Restart = "on-failure";
          RestartSec = "1m";
        };
        environment = {
          HOME = stateDir;
        };
        script =
          let
            credentialsDir = "${stateDir}/.near-credentials/mainnet";
            near = lib.getExe near-cli.packages.${pkgs.system}.default;
            account = "$( ls -A '${credentialsDir}' | sed -e 's/\.json$//')";
          in
          ''
            if [ -z "$( ls -A '${credentialsDir}' )" ]; then
              ${near} account create-account fund-later use-auto-generation save-to-folder ${credentialsDir}
            fi

            ${near} call ${cfg.pool.id}.${cfg.pool.version}.near ping '{}' --accountId="${account}" --gas=300000000000000 --network-id=mainnet
          '';
      }
    );
  };
}
