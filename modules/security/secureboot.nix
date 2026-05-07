{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  cfg = config.midgard.pc.security.secureboot;
in
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.midgard.pc.security.secureboot = {
    enable = mkEnableOption "Secure Boot via lanzaboote";

    pkiBundle = mkOption {
      type = types.str;
      default = "/var/lib/sbctl";
      description = "Path to the Secure Boot PKI bundle managed by sbctl";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sbctl ];

    boot.loader.systemd-boot.enable = mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = cfg.pkiBundle;
    };
  };
}
