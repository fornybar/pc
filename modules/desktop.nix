{ config, pkgs, lib, ...}:
with lib;
let
  cfg = config.midgard.pc;
in {
  options.midgard.pc = {
    desktop = mkOption {
      type = with types; nullOr (enum [ "gnome" "plasma" "hyperland"]);
      default = "gnome";
      description = ''Which dekstop to use "gnome", "plasma" or null'';
    };
  };

  config = mkIf (cfg.desktop != null) (
    mkMerge [
      (mkIf (cfg.desktop == "gnome") {
        services.xserver = {
          enable = true;
          desktopManager.gnome.enable = true;
          displayManager.gdm.enable = true;
        };

        # Remove unused programs
        environment.gnome.excludePackages = (with pkgs.gnome; [
          epiphany # webbrowser use firefox
          geary # email reader
        ]);
      })

      (mkIf (cfg.desktop == "plasma") {
        services.xserver = {
          enable = true;
          displayManager.sddm.enable = true;
          desktopManager.plasma5.enable = true;
        };
      })

      (mkIf (cfg.desktop == "hyperland") {
        programs.hyprland.enable = true;
        programs.hyprlock.enable = true;
        services.hypridle.enable = true;
        
      })
    ]
  );

}
