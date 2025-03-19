{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    near-validator = {
      url = "path:/home/plopmenz/git/openmesh/near-validator"; # "github:Openmesh-Network/near-validator";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

              # https://github.com/near/nearcore/blob/master/scripts/set_kernel_params.sh
              # Not allowed to change these settings in container, should be set in host configuration instead
              boot.kernel.sysctl = {
                "net.core.rmem_max" = 8388608;
                "net.core.wmem_max" = 8388608;
                "net.ipv4.tcp_rmem" = "4096 87380 8388608";
                "net.ipv4.tcp_wmem" = "4096 16384 8388608";
                "net.ipv4.tcp_slow_start_after_idle" = 0;
              };

              services.near-validator = {
                enable = true;
                pool = {
                  id = "openmesh";
                  version = "pool";
                };
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
