{
  config,
  pkgs,
  lib,
  mapHomeManagerUsers,
  ...
}:
with lib;
let
  cfg = config.midgard.pc;
in
{
  options.midgard.pc = {
    desktop = mkOption {
      type =
        with types;
        nullOr (enum [
          "gnome"
          "plasma6"
          "sway"
        ]);
      default = "gnome";
      description = ''Which desktop to use: "gnome", "plasma6", "sway", or null'';
    };
  };

  config = mkIf (cfg.desktop != null) (mkMerge [
    # NixOS 25.11: All desktop options (GNOME 49, Plasma 6, Sway) are
    # Wayland-based and do not require services.xserver.enable. XWayland
    # is provided automatically where needed. If a future desktop option
    # requires X11, add services.xserver.enable inside that specific block.

    (mkIf (cfg.desktop == "gnome") {
      services = {
        desktopManager.gnome.enable = true;
        displayManager.gdm.enable = true;
      };

      # Remove unused programs
      environment.gnome.excludePackages = with pkgs; [
        epiphany # webbrowser use firefox
        geary # email reader
      ];
    })

    (mkIf (cfg.desktop == "plasma6") {
      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    })

    (mkIf (cfg.desktop == "sway") {
      security.polkit.enable = true;
      security.pam.services.swaylock = { };
      programs.light.enable = true;

      users.users = mapHomeManagerUsers (_: _: { extraGroups = [ "video" ]; });
      environment.sessionVariables.GTK_USE_PORTAL = "1";
      home-manager.users = mapHomeManagerUsers (
        _: _: {
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
        }
      );

      services.greetd = {
        enable = true;
        settings = {
          default_session.command = ''
            ${pkgs.tuigreet}/bin/tuigreet \
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

  ]);

}
