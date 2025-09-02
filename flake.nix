{
  nixConfig.flake-registry = "https://raw.githubusercontent.com/fornybar/registry/main/registry.json";

  outputs = { self, nixpkgs, nix, sops-nix, midgard-lib }@inputs:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ midgard-lib.overlays.default ];
    };
    inherit (pkgs.midgard.lib) importDir;
  in {
    nixosModules = import ./hardware // importDir ./modules
    // {
      default = {
        # Need to use path insted of self.nixosModules.xxxx
        # so it is possible to disable modules
        # https://github.com/NixOS/nixpkgs/pull/188289
        imports = [
          ./modules/nix.nix
          ./modules/users.nix
          ./modules/fileSystems.nix
          ./modules/keyboard.nix
          ./modules/sops.nix
          ./modules/desktop.nix
          ./modules/virtualisation.nix
          ./modules/home-manager.nix
          ./modules/home-manager-git.nix
          ./modules/home-manager-programs.nix
          ./modules/home-manager-gui-programs.nix
          ./modules/nixbuild.nix
          ./modules/boot.nix
          ./modules/nixpkgs.nix
          ./modules/systemPackages.nix
          ./modules/systemPackagesGui.nix
          ./modules/services.nix
          ./modules/networking.nix
          ./modules/local.nix
          ./modules/nix-access-tokens.nix
          ./modules/ssh.nix
        ];
      };
      terminal = {
        imports = [
          ./modules/docker.nix
          ./modules/home-manager-git.nix
          ./modules/home-manager-programs.nix
          ./modules/home-manager.nix
          ./modules/keyboard.nix
          ./modules/local.nix
          ./modules/networking.nix
          ./modules/nix-access-tokens.nix
          ./modules/nix.nix
          ./modules/nixbuild.nix
          ./modules/nixpkgs.nix
          ./modules/sops.nix
          ./modules/ssh.nix
          ./modules/systemPackages.nix
          ./modules/users.nix
        ];

        # Make vscode remote to work
       programs.nix-ld.enable = true;
      };
      mac = {
        imports = [
          ./modules/nix.nix
          # ./modules/nixbuild.nix
          # ./modules/nixpkgs.nix
          ./modules/sops.nix
          # ./modules/ssh.nix
          # ./modules/systemPackages.nix
          ./modules/users.nix
          ./modules/networking.nix
        ];
      };
    };

    checks."x86_64-linux" = import ./tests inputs;

    templates = import ./templates;

    herculesCI = { };

    devShells."x86_64-linux".default = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
      pkgs.mkShell {
        packages = with pkgs; [ age sops ];
      };
  };
}
