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

      bootnodes = lib.mkOption {
        type = lib.types.str;
        default = "ed25519:86EtEy7epneKyrcJwSWP7zsisTkfDRH5CFVszt4qiQYw@35.195.32.249:24567,ed25519:BFB78VTDBBfCY4jCP99zWxhXUcFAZqR22oSx2KEr8UM1@35.229.222.235:24567,ed25519:Cw1YyiX9cybvz3yZcbYdG7oDV6D7Eihdfc8eM1e1KKoh@35.195.27.104:24567,ed25519:33g3PZRdDvzdRpRpFRZLyscJdbMxUA3j3Rf2ktSYwwF8@34.94.132.112:24567,ed25519:CDQFcD9bHUWdc31rDfRi4ZrJczxg8derCzybcac142tK@35.196.209.192:24567";
        example = "ed25519:86EtEy7epneKyrcJwSWP7zsisTkfDRH5CFVszt4qiQYw@35.195.32.249:24567,ed25519:BFB78VTDBBfCY4jCP99zWxhXUcFAZqR22oSx2KEr8UM1@35.229.222.235:24567,ed25519:Cw1YyiX9cybvz3yZcbYdG7oDV6D7Eihdfc8eM1e1KKoh@35.195.27.104:24567,ed25519:33g3PZRdDvzdRpRpFRZLyscJdbMxUA3j3Rf2ktSYwwF8@34.94.132.112:24567,ed25519:CDQFcD9bHUWdc31rDfRi4ZrJczxg8derCzybcac142tK@35.196.209.192:24567";
        description = ''
          The bootnodes to use. Defaults to mainnet bootnodes.
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
      script =
        let
          dir = "/var/lib/near-validator";
          neard = lib.getExe (pkgs.callPackage ./nearcore.nix { });
        in
        ''
          ${neard} --home ${dir} init --chain-id=mainnet --account-id="${cfg.pool.id}.${cfg.pool.version}.near" --download-genesis --download-config validator
          ${neard} --home ${dir} run --boot-nodes=${cfg.bootnodes}
        '';
    };
  };
}
