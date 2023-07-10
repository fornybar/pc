{ config, lib, home-manager, mapUsers, ... }:
with lib;

let
  cfg = config.midgard.pc.users;

  mapHomeManagerUsers = attrsFun: mapUsers (name: user:
    mkIf cfg."${name}".home-manager.enable (attrsFun name user)
  );

  userOpts = {
    options.home-manager = mkOption {
      type = with types; submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            example = true;
            default = true;
            description = "Enable home-manager";
          };
        };
      };
      default = { };
    };
  };
in {

  imports = [
    home-manager.nixosModules.home-manager
  ];

  options = {
    midgard.pc.users = mkOption {
      type = with types; attrsOf (submodule userOpts);
    };
  };

  config = {
    _module.args = { inherit mapHomeManagerUsers; };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.users = mapHomeManagerUsers (name: user: {
      home.stateVersion = "23.05";

      home.username = user.name;
      home.homeDirectory = config.users.users."${name}".home;
    });
  };
}
