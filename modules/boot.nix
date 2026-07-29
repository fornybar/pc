{ pkgs, lib, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      timeout = lib.mkDefault 1;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = lib.mkDefault "/boot";
      };
    };
    tmp.cleanOnBoot = true;
  };
}
