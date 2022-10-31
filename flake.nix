{
  nixConfig.flake-registry = "https://raw.githubusercontent.com/bkkp/flake-registry/nixos-22.05/flake-registry.json";

  inputs.utils.inputs.nixpkgs.follows  = "nixpkgs";

  outputs = { self, nixpkgs, nix, sops-nix, utils }@inputs:
  {
    nixosModules = import ./hardware // utils.lib.dirToAttrs ./modules
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
          self.nixosModules.home-manager-git
          self.nixosModules.home-manager-programs
          self.nixosModules.nixbuild
          self.nixosModules.boot
          self.nixosModules.nixpkgs
          self.nixosModules.teams
          self.nixosModules.systemPackages
          self.nixosModules.services
          self.nixosModules.networking
          self.nixosModules.local
          self.nixosModules.nix-access-tokens
        ];
      };
    };

    checks."x86_64-linux" = import ./tests inputs;

    templates.default = {
      path = ./templates;
      description = "Example setup for nixos pc";
      welcomeText = ''
      # Nixos config setup
      Setup a simple nixos pc
      ''; # Can use markdown here
    };

    devShells."x86_64-linux".default = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
      pkgs.mkShell {
        packages = with pkgs; [ age sops ];
      };
  };
}
