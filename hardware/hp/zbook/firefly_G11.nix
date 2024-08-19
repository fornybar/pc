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

  hardware.intel-gpu-tools.enable = lib.mkDefault true; # For debugging

  # Make nvidia less error prone (https://nixos.wiki/wiki/Nvidia)
  hardware.nvidia = {
    open = lib.mkDefault false;
    nvidiaSettings = lib.mkDefault true; # For debugging

    # nvidiaPackages.stable didn't build on nixos-24.05 so use newer version
    # However, we need to change it back when stable works again.
    package = lib.mkDefault (config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "555.58.02";
      sha256_64bit = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
      sha256_aarch64 = "sha256-wb20isMrRg8PeQBU96lWJzBMkjfySAUaqt4EgZnhyF8=";
      openSha256 = "sha256-8hyRiGB+m2hL3c9MDA/Pon+Xl6E788MZ50WrrAGUVuY=";
      settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
      persistencedSha256 = "sha256-a1D7ZZmcKFWfPjjH1REqPM5j/YLWKnbkP9qfRyIyxAw=";
    });

    powerManagement = {
      enable = lib.mkDefault false;
      finegrained = lib.mkDefault false;
    };
  };

  # Fix random crashes, make nvidia sync work but disable wayland and fallback to x11
  services.xserver.displayManager.gdm.wayland = lib.mkDefault false;
}
