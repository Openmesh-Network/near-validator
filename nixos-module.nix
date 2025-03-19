{
  nixpkgs,
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
        example = false;
        description = ''
          Download snapshot to data folder before starting near node.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
          neard = lib.getExe (pkgs.callPackage ./nearcore.nix { });
        in
        ''
          ${neard} --home ${dir} init --chain-id=mainnet --account-id="${cfg.pool.id}.${cfg.pool.version}.near" --download-genesis --download-config validator
          curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/update_boot_nodes.sh | bash -s -- mainnet ${dir}/config.json
          if ${if cfg.fast-sync then "true" else "false"}; then
            curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/down_rclone.sh | DATA_PATH=${dir}/data CHAIN_ID=mainnet RPC_TYPE=fast-rpc bash
          fi
          ${neard} --home ${dir} run
        '';
    };
  };
}
