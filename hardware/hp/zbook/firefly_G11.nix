{
  config,
  lib,
  modulesPath,
  nixos-hardware,
  ...
}:
# Include https://github.com/NixOS/nixos-hardware in inputs when using

{
  imports = [
    nixos-hardware.nixosModules.common-gpu-nvidia-sync
    "${nixos-hardware}/common/pc/laptop"
    "${nixos-hardware}/common/pc/ssd"
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/gpu/nvidia"
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware = {
    intel-gpu-tools.enable = lib.mkDefault true; # For debugging

    intelgpu = {
      driver = lib.mkDefault "xe";
      loadInInitrd = lib.mkDefault false;
    };

    nvidia = {
      open = lib.mkDefault true;
      package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;

      prime = {
        intelBusId = "PCI:0:2:0"; # pci@0000:00:02.0
        nvidiaBusId = "PCI:1:0:0"; # pci@0000:01:00.0
      };
    };

    enableRedistributableFirmware = lib.mkDefault true;
  };


  # GNOME 49 (NixOS 25.11) is Wayland-only; the previous gdm.wayland=false
  # workaround no longer produces a functional session. NVIDIA+Wayland may
  # still be unstable on this hardware. If issues arise, consider switching
  # to a different desktop/session. The variables below are common
  # compatibility hints for NVIDIA on Wayland.
  environment.sessionVariables = {
    # Needed for some NVIDIA Wayland compatibility
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
