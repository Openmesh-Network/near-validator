{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    near-validator.url = "path:/home/plopmenz/git/openmesh/near-validator"; # "github:Openmesh-Network/near-validator";
  };

  outputs =
    {
      self,
      nixpkgs,
      near-validator,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit near-validator;
        };
        modules = [
          (
            { near-validator, ... }:
            {
              imports = [
                near-validator.nixosModules.default
              ];

              boot.isContainer = true;

              services.near-validator = {
                enable = true;
                pool = {
                  id = "openmesh";
                  version = "pool";
                };
                fast-sync = false;
                pinger.enable = true;
              };

              networking = {
                firewall.allowedTCPPorts = [
                  3030
                  24567
                ];

                useHostResolvConf = nixpkgs.lib.mkForce false;
              };

              services.resolved.enable = true;

              system.stateVersion = "25.05";
            }
          )
        ];
      };
    };
}
