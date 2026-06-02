{
  nixConfig.flake-registry = "https://raw.githubusercontent.com/fornybar/registry/main/registry.json";

  inputs = {
    # Ensure sops-nix uses our nixpkgs to avoid duplicate nixpkgs evaluations.
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };
      # Local importDir using path concatenation (dir + "/${n}") instead of
      # string interpolation ("${dir}/${n}"). String interpolation copies the
      # directory to a separate store path that can be garbage-collected,
      # breaking `nix flake check`. Path concatenation keeps it as a subpath
      # of the flake source.
      importDir =
        dir:
        lib.mapAttrs' (n: _: lib.nameValuePair (lib.removeSuffix ".nix" n) (import (dir + "/${n}"))) (
          builtins.readDir dir
        );
    in
    {
      nixosModules =
        import ./hardware
        // importDir ./modules
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
        };

      checks."x86_64-linux" = import ./tests inputs;

      formatter."x86_64-linux" = treefmtEval.config.build.wrapper;

      templates = import ./templates;

      apps."x86_64-linux".backup =
        let
          script = pkgs.writeShellApplication {
            name = "pc-backup";
            runtimeInputs = with pkgs; [
              azure-cli
              rclone
              coreutils
              gawk
              sudo
            ];
            text = builtins.readFile ./scripts/backup.sh;
          };
        in
        {
          type = "app";
          program = "${script}/bin/pc-backup";
        };

      apps."x86_64-linux".restore =
        let
          script = pkgs.writeShellApplication {
            name = "pc-restore";
            runtimeInputs = with pkgs; [
              azure-cli
              rclone
              coreutils
              gawk
            ];
            text = builtins.readFile ./scripts/restore.sh;
          };
        in
        {
          type = "app";
          program = "${script}/bin/pc-restore";
        };

      herculesCI = { };

      devShells."x86_64-linux".default = pkgs.mkShell {
        packages = with pkgs; [
          age
          sops
        ];
      };
    };
}
