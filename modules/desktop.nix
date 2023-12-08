{ config, pkgs, lib, ...}:
with lib;
let
  cfg = config.midgard.pc;
in {
  options.midgard.pc = {
    desktop = mkOption {
      type = with types; nullOr (enum [ "gnome" "hyprland" "plasma" ]);
      default = "gnome";
      description = ''Which dekstop to use "gnome", "hyprland", "plasma" or null'';
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
        environment.gnome.excludePackages = (with pkgs.gnome; [
          epiphany # webbrowser use firefox
          geary # email reader
        ]);
      })

      (mkIf (cfg.desktop == "hyprland") {
        programs.hyprland.enable = true;
      })

      (mkIf (cfg.desktop == "plasma") {
        services.xserver = {
          displayManager.sddm.enable = true;
          desktopManager.plasma5.enable = true;
        };
      })
    ]
  );

}
