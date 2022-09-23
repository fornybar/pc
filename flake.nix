{
  nixConfig.flake-registry = "https://raw.githubusercontent.com/bkkp/flake-registry/main/flake-registry.json";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";
  inputs.utils.inputs.nixpkgs.follows  = "nixpkgs";

  outputs = { self, nixpkgs, nix, utils, ... }@inputs:
  {
    nixosModules = import ./hardware // utils.lib.importDir ./modules;

    checks."x86_64-linux" = import ./tests inputs;
  };
}
