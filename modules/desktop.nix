{ config, pkgs, lib, mapHomeManagerUsers, ...}:
with lib;
let
  cfg = config.midgard.pc;
in {
  options.midgard.pc = {
    desktop = mkOption {
      type = with types; nullOr (enum [ "gnome" "plasma" "sway" ]);
      default = "gnome";
      description = ''Which dekstop to use "gnome", "plasma" or null'';
    };
  };

  config = mkIf (cfg.desktop != null) (
    mkMerge [
      { services.xserver.enable = true; }

      (mkIf (cfg.desktop == "gnome") {
        services.xserver = {
          desktopManager.gnome.enable = true;
          displayManager.gdm.enable = true;
        };

        # Remove unused programs
        environment.gnome.excludePackages = (with pkgs; [
          epiphany # webbrowser use firefox
          geary # email reader
        ]);
      })

      (mkIf (cfg.desktop == "plasma") {
        services.xserver = {
          displayManager.sddm.enable = true;
          desktopManager.plasma5.enable = true;
        };
      })

      (mkIf (cfg.desktop == "sway") {
        security.polkit.enable = true;
        security.pam.services.swaylock = {};
        programs.light.enable = true;

        users.users = mapHomeManagerUsers (name: user: {
          extraGroups = [ "video" ];
        });
        environment.sessionVariables.GTK_USE_PORTAL = "1";
        home-manager.users = mapHomeManagerUsers (name: user: {
          wayland.windowManager.sway = {
            enable = true;
            config = rec {
              modifier = "Mod4"; # Super key

            };
            wrapperFeatures = {
              gtk = true;
            };
          };
          services = {
            swayidle = {
              enable = true;
            };
          };
          programs = {
            swaylock = {
              enable = true;
            };
          };
        });

        services.greetd = {
          enable = true;
          settings = {
          default_session.command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet \
              --time \
              --asterisks \
              --user-menu \
              --cmd sway
          '';
          };
        };

        environment.etc."greetd/environments".text = ''
          sway
        '';
      })

    ]
  );

}
