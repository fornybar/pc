{
  config,
  lib,
  mapHomeManagerUsers,
  ...
}:
with lib;

let
  cfg = config.midgard.pc.users;

  gitOpts =
    { name, ... }:
    {
      options.git = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };

        userName = mkOption {
          type = types.str;
          description = "Your GitHub username";
        };

        githubTokenPath = mkOption {
          type = with types; nullOr path;
          description = "GitHub personal token";
        };

        editor = mkOption {
          type =
            with types;
            enum [
              "nano"
              "vim"
            ];
          description = "Default git text editor";
          default = "nano";
        };
      };

      config = {
        git.githubTokenPath = mkDefault (config.sops.secrets."${name}/github-token".path or null);
      };
    };

in
{

  options = {
    midgard.pc.users = mkOption {
      type = with types; attrsOf (submodule gitOpts);
    };
  };

  config = {
    assertions = [
      {
        assertion = !any id (lib.mapAttrsToList (name: user: isNull user.git.githubTokenPath) cfg);
        message = ''
          Sops secret <user>:github.token is missing from secrets.yaml for one or more users. Set it og change
          midgard.pc.users.<users>.git.githubTokenPath to a file with github-token.
        '';
      }
    ];

    home-manager.users = mapHomeManagerUsers (
      name: user:
      mkIf cfg.${name}.git.enable {
        programs = {
          gh.enable = true;
          gh.gitCredentialHelper.enable = true;

          git = {
            enable = true;
            settings = {
              user.name = user.git.userName;
              user.email = user.email;
              init.defaultBranch = "main";
              core.editor = cfg.${name}.git.editor;
              push.autoSetupRemote = true;
            };
          };
          #git.signing.key
          #git signing.signByDefault = true;
        };

        home.sessionVariablesExtra = ''
          export GH_TOKEN=''$(cat ${cfg.${name}.git.githubTokenPath})
        '';
      }
    );
  };
}
