{
  nixConfig.flake-registry = "https://raw.githubusercontent.com/bkkp/flake-registry/main/flake-registry.json";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";
  inputs.utils.inputs.nixpkgs.follows  = "nixpkgs";

  outputs = { self, nixpkgs, nix, sops-nix, utils, ... }@inputs:
  {
    nixosModules = import ./hardware // utils.lib.importDir ./modules
    // {
      default = {
        imports = [
          self.nixosModules.nix
          self.nixosModules.users
          self.nixosModules.system
          self.nixosModules.fileSystems
          self.nixosModules.keyboard
          self.nixosModules.sops
          self.nixosModules.desktop
          self.nixosModules.virtualisation
          self.nixosModules.home-manager
        ];
      };
    };


    checks."x86_64-linux" = import ./tests inputs;
  };
}
