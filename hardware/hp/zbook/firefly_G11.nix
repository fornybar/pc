{ config, lib, modulesPath, nixos-hardware, ... }:
# Include https://github.com/NixOS/nixos-hardware in inputs when using

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    nixos-hardware.nixosModules.common-gpu-nvidia-sync
    "${nixos-hardware}/common/pc/laptop"
    "${nixos-hardware}/common/pc/laptop/ssd"
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/gpu/nvidia"
  ];

  # Path must be according to modules/fileSystems.nix
  fileSystems."/boot/efi".options = [ "fmask=0022" "dmask=0022" ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.intel-gpu-tools.enable = lib.mkDefault true; # For debugging

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];

  boot.kernelModules = [ "kvm-intel" ];


  hardware.intelgpu = {
    driver = lib.mkDefault "xe";
    loadInInitrd = lib.mkDefault false;
  };

  hardware.nvidia = {
    open = lib.mkDefault true;

    # default driver is broken for 6.12
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  hardware.nvidia.prime = {
    intelBusId = "PCI:0:2:0"; # pci@0000:00:02.0
    nvidiaBusId = "PCI:1:0:0"; # pci@0000:01:00.0
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Fix random crashes, make nvidia sync work but disable wayland and fallback to x11
  services.xserver.displayManager.gdm.wayland = lib.mkDefault false;
}
