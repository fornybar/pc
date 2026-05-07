{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.midgard.pc.security.paretosecurity;

  linkScript = pkgs.writeShellScript "paretosecurity-link" ''
    config="$HOME/.config/pareto.toml"
    if [ -f "$config" ]; then
      team_id=$(grep '^TeamID' "$config" | cut -d'"' -f2)
      [ -n "$team_id" ] && exit 0
    fi
    exec ${pkgs.paretosecurity}/bin/paretosecurity link '${cfg.inviteUrl}'
  '';
in
{
  options.midgard.pc.security.paretosecurity = {
    enable = mkEnableOption "ParetoSecurity agent";

    inviteUrl = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Team invite URL for automatic device enrollment.
        Format: paretosecurity://linkDevice?invite_id=<ID>
        Obtain from the ParetoSecurity team dashboard or Keeper vault.
        If unset, run paretosecurity link <url> manually after install.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.paretosecurity ];

    systemd.user.services.paretosecurity-link = mkIf (cfg.inviteUrl != null) {
      description = "Link device to ParetoSecurity team";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = linkScript;
        Restart = "on-failure";
        RestartSec = "30s";
      };
      startLimitIntervalSec = 300;
      startLimitBurst = 5;
    };
  };
}
