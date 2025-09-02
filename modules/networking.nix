{ config, lib, options, ...}:
with lib;
{
  options.midgard.pc = {
    hostName = mkOption {
      type = options.networking.hostName.type;
      description = "Hostname for computer";
    };
  };

  config = {
    networking.hostName = config.midgard.pc.hostName;

    #networking.networkmanager.enable = true;
  };
}
