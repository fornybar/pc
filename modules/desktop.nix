{ config, lib, ...}: 
with lib;
let
  cfg = config.midgard.pc;
in {
  options.midgard.pc = {
    desktop = mkOption {
      type = with types; nullOr (enum [ "none" "gnome" "plasma" ]);
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