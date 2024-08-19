{ config, lib, modulesPath, nixos-hardware, ... }:
# Include https://github.com/NixOS/nixos-hardware in inputs when using

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    nixos-hardware.nixosModules.hp-firefly-g11
    nixos-hardware.nixosModules.common-gpu-nvidia-sync
  ];

  # Path must be according to modules/fileSystems.nix
  fileSystems."/boot/efi".options = [ "fmask=0022" "dmask=0022" ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
