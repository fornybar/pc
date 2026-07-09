{ pkgs, lib, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
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
