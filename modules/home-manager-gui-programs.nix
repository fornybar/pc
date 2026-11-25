{ pkgs, mapHomeManagerUsers, ... }:
let
  vscodeSettings = pkgs.writeText "vscode-settings.json" (
    builtins.toJSON { "extensions.autoUpdate" = false; }
  );
in
{
  home-manager.users = mapHomeManagerUsers (
    _: _: {
      programs = {
        chromium = {
          enable = true;
          package = pkgs.google-chrome;
        };
      };
    }
  );

  # ParetoSecurity: no extension auto-updates. Only written if missing, so it stays editable.
  home-manager.sharedModules = [
    (
      { lib, ... }:
      {
        home.activation.vscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          f="$HOME/.config/Code/User/settings.json"
          [ -e "$f" ] || run install -Dm644 ${vscodeSettings} "$f"
        '';
      }
    )
  ];
}
