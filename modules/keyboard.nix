{ lib, ... }:
with lib;
{
  # Configure console keymap
  console.keyMap = "no";

  # Set XKB layout unconditionally. Even on Wayland-only desktops, some
  # display managers (notably SDDM for Plasma 6) read
  # services.xserver.xkb.{layout,variant} to configure the login screen
  # keyboard. GNOME/GDM manages keyboard layout via ibus/dconf, and Sway
  # uses its own config — but setting these values is harmless and ensures
  # consistency for any desktop that reads them.
  services.xserver.xkb = {
    layout = "no";
    variant = "nodeadkeys";
  };
}
