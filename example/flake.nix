{
  inputs = {
    near-validator.url = "github:Openmesh-Network/near-validator";
    nixpkgs.follows = "near-validator/nixpkgs";
  };

  nixConfig = {
    extra-substituters = [
      "https://openmesh.cachix.org"
    ];
    extra-trusted-public-keys = [
      "openmesh.cachix.org-1:du4NDeMWxcX8T5GddfuD0s/Tosl3+6b+T2+CLKHgXvQ="
    ];
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
