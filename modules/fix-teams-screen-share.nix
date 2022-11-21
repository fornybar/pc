{ config, pkgs, lib, mapHomeManagerUsers, ...}:
with lib;

mkMerge [
  (mkIf (config.midgard.pc.desktop == "gnome") {
    # Turn of wayland to fix screen sharing in teams
    services.xserver.displayManager.gdm.wayland = false;
    home-manager.users = mapHomeManagerUsers (name: user: {
      # Need to turn on xsession when wayland is of to load enviroment variables
      # in terminal
      xsession.enable = true;
    });
  })
]