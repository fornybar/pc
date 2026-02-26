{ modulesPath, ... }:
{
  disabledModules = [ ../modules/local.nix ];

  programs.starship.settings = {
    container.disabled = true;
  };

  # >>> FROM /etc/nixos/configuration.nix in orbstack

  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  time.timeZone = "Europe/Oslo";

  # As this is intended as a stadalone image, undo some of the minimal profile stuff
  documentation.enable = true;
  documentation.nixos.enable = true;
  environment.noXlibs = false;

  networking = {
    networkmanager.enable = true;
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
  };

  # >>> FROM /etc/nixos/orbstack.nix in orbstack

  # add OrbStack CLI tools to PATH
  environment.shellInit = ''
    . /opt/orbstack-guest/etc/profile-early

    # add your customizations here

    . /opt/orbstack-guest/etc/profile-late
  '';

  # faster DHCP - OrbStack uses SLAAC exclusively
  networking.dhcpcd.extraConfig = ''
    noarp
    noipv6
  '';

  # disable sshd
  services.openssh.enable = false;

  # systemd
  systemd.services = {
    "systemd-oomd".serviceConfig.WatchdogSec = 0;
    "systemd-resolved".serviceConfig.WatchdogSec = 0;
    "systemd-userdbd".serviceConfig.WatchdogSec = 0;
    "systemd-udevd".serviceConfig.WatchdogSec = 0;
    "systemd-timesyncd".serviceConfig.WatchdogSec = 0;
    "systemd-timedated".serviceConfig.WatchdogSec = 0;
    "systemd-portabled".serviceConfig.WatchdogSec = 0;
    "systemd-nspawn@".serviceConfig.WatchdogSec = 0;
    "systemd-networkd".serviceConfig.WatchdogSec = 0;
    "systemd-machined".serviceConfig.WatchdogSec = 0;
    "systemd-localed".serviceConfig.WatchdogSec = 0;
    "systemd-logind".serviceConfig.WatchdogSec = 0;
    "systemd-journald@".serviceConfig.WatchdogSec = 0;
    "systemd-journald".serviceConfig.WatchdogSec = 0;
    "systemd-journal-remote".serviceConfig.WatchdogSec = 0;
    "systemd-journal-upload".serviceConfig.WatchdogSec = 0;
    "systemd-importd".serviceConfig.WatchdogSec = 0;
    "systemd-hostnamed".serviceConfig.WatchdogSec = 0;
    "systemd-homed".serviceConfig.WatchdogSec = 0;
  };

  # ssh config
  programs.ssh.extraConfig = ''
    Include /opt/orbstack-guest/etc/ssh_config
  '';

  # extra certificates
  security.pki.certificateFiles = [
    "/opt/orbstack-guest/run/extra-certs.crt"
  ];

  # indicate builder support for emulated architectures
  nix.extraOptions = "extra-platforms = x86_64-linux i686-linux";
}
