{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.midgard.pc.users;

  mapUsers = attrsFun: builtins.mapAttrs (name: user: attrsFun name user) cfg;
  midgardUsers = lib.attrNames config.midgard.pc.users;

  userOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        description = "Username";
      };

      fullName = mkOption {
        type = types.str;
        description = "Full name of user";
      };

      email = mkOption {
        type = types.str;
        description = "E-mail of user";
      };

      hashedPassword = mkOption {
        type = with types; nullOr str;
        description = ''
          Hashed password for user, overrides passwsordFile. Make hashed password with
          `mkpasswd -m sha-512`.
        '';
        default = null;
      };

      hashedPasswordFile = mkOption {
        type = with types; nullOr str;
        description = ''
          File path to file contaning user password, made with `mkpasswd -m sha-512`.
          Option hashedPassword override hashedPasswordFile. Default to sops secret <usernam>/password

          # secrets.yaml
          <username>:
            password: my-password

          if it exist.
        '';
        default = config.sops.secrets."${name}/password".path or null;
      };
    };
  };

in {

  options = {
    midgard.pc = {
      users = mkOption {
        type = with types; attrsOf (submodule userOpts);
        default = { };
      };
    };
  };

  config = {
    _module.args = { inherit mapUsers midgardUsers; };

    #users.mutableUsers = false;

    #security.sudo.wheelNeedsPassword = false;

    users.users = mapUsers (_: user:
      {
        inherit (user) hashedPassword hashedPasswordFile;
        isNormalUser = true;
        description = user.fullName;
        extraGroups = [ "networkmanager" "wheel" ];
        packages = with pkgs; [ ];
      }
    );
  };

}
