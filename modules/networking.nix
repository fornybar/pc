{
  config,
  lib,
  options,
  ...
}:
with lib;
{
  options.midgard.pc = {
    hostName = mkOption {
      inherit (options.networking.hostName) type;
      description = "Hostname for computer";
    };

    # NixOS 25.11 no longer ships default VPN plugins with NetworkManager.
    # Users must explicitly list any required VPN plugins (e.g.,
    # pkgs.networkmanager-openconnect, pkgs.networkmanager-openvpn).
    networkmanager.vpnPlugins = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "List of NetworkManager VPN plugins to install.";
      example = literalExpression "[ pkgs.networkmanager-openconnect pkgs.networkmanager-openvpn ]";
    };
  };

  config = {
    networking = {
      inherit (config.midgard.pc) hostName;
      networkmanager.enable = true;
      networkmanager.plugins = config.midgard.pc.networkmanager.vpnPlugins;
    };
  };
}
