{
  nixConfig.flake-registry = "https://raw.githubusercontent.com/bkkp/flake-registry/nixos-22.05/flake-registry.json";

  inputs.utils.inputs.nixpkgs.follows  = "nixpkgs";

  outputs = { self, nixpkgs, nix, sops-nix, utils }@inputs:
  {
    nixosModules = import ./hardware // utils.lib.importDir ./modules
    // {
      default = {
        # Need to use path insted of self.nixosModules.xxxx
        # so it is possible to disable modules
        # https://github.com/NixOS/nixpkgs/pull/188289
        imports = [
          ./modules/nix.nix
          ./modules/users.nix
          ./modules/system.nix
          ./modules/fileSystems.nix
          ./modules/keyboard.nix
          ./modules/sops.nix
          ./modules/desktop.nix
          ./modules/virtualisation.nix
          ./modules/home-manager.nix
          ./modules/home-manager-git.nix
          ./modules/home-manager-programs.nix
          ./modules/nixbuild.nix
          ./modules/boot.nix
          ./modules/nixpkgs.nix
          ./modules/teams.nix
          ./modules/systemPackages.nix
          ./modules/services.nix
          ./modules/networking.nix
          ./modules/local.nix
          ./modules/nix-access-tokens.nix
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
