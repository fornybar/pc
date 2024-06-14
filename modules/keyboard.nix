{ config, lib, ... }:
with lib;
{
  # Configure console keymap
  console.keyMap = "no";

  # Configure keymap in X11
  services.xserver.xkb = mkIf config.services.xserver.enable {
    layout = "no";
    variant = "nodeadkeys";
  };
}
