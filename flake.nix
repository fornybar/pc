{
  nixConfig.flake-registry = "https://raw.githubusercontent.com/bkkp/flake-registry/main/flake-registry.json";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";

  outputs = { self, nixpkgs, ... }@inputs:
  {
    nixosModules = import ./hardware;
  };
}
