{ config, ... }:
# See for docs: https://nixos.wiki/wiki/Nvidia
# We try to make this module as robust as possible, potentially at the cost of performance.
# Nvidia on NixOS is hard so users must enable extra features themselves.
{
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
  boot.initrd.kernelModules = [ "i915" "nvidia" "nvidia_drm" "nvidia_modeset" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.opengl.enable = true;

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;

    powerManagement = {
      enable = false;
      finegrained = false;
    };

    nvidiaSettings = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # # TODO: User must find and set these manually with
      # # sudo nix run nixpkgs#lshw -- -C display
      # # Convert hexadecimal to decimal, remove padding, leading 4 zeros and set like so
      # intelBusId = "PCI:0:2:0"; # pci@0000:00:02.0 (driver=i915)
      # nvidiaBusId = "PCI:1:0:0"; # pci@0000:01:00.0 (driver=nvidia)
    };

    # nvidiaPackages.stable didn't build on nixos-24.05 so use newer version
    # However, we need to change it back when stable works again.
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "555.58.02";
      sha256_64bit = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
      sha256_aarch64 = "sha256-wb20isMrRg8PeQBU96lWJzBMkjfySAUaqt4EgZnhyF8=";
      openSha256 = "sha256-8hyRiGB+m2hL3c9MDA/Pon+Xl6E788MZ50WrrAGUVuY=";
      settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
      persistencedSha256 = "sha256-a1D7ZZmcKFWfPjjH1REqPM5j/YLWKnbkP9qfRyIyxAw=";
    };
  };
}

