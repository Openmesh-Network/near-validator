{
  description = "Nix flake to run a near validator with minimal setup.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    {
      nixosModules.default = import ./nixos-module.nix inputs;
    };
}
