{ lib, ... }@inputs:
with lib;
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  # If nix is a input use nix version from it
  nixpkgs.overlays = optional (inputs ? "nix") inputs.nix.overlays.default;

  # Garbage collect once every week
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
}