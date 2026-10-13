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
    invite_url="$(${pkgs.coreutils}/bin/cat -- ${escapeShellArg cfg.inviteUrlFile})"
    exec ${pkgs.paretosecurity}/bin/paretosecurity link "$invite_url"
  '';
in
{
  options.midgard.pc.security.paretosecurity = {
    enable = mkEnableOption "ParetoSecurity agent";

    inviteUrlFile = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Path to a file containing the team invite URL for automatic device enrollment.
        Format: paretosecurity://linkDevice?invite_id=<ID>
        Obtain from the ParetoSecurity team dashboard or Keeper vault.
        Use a sops-nix secret path to keep the URL out of the Nix store.
        If unset, run paretosecurity link <url> manually after install.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.paretosecurity ];

    # Install Pareto's systemd units so its root helper can run privileged checks.
    systemd.packages = [ pkgs.paretosecurity ];
    systemd.sockets.paretosecurity = {
      wantedBy = [ "sockets.target" ];
      startLimitIntervalSec = 300;
      startLimitBurst = 100;
    };

    # Run checks and send a team report each weekday at 10:00 local time.
    systemd.user.timers.paretosecurity-user = {
      description = "Run ParetoSecurity Check on weekdays";
      wantedBy = [ "timers.target" ];
      startLimitIntervalSec = 300;
      startLimitBurst = 5;
      timerConfig = {
        # Clear the package's hourly trigger before replacing it with the weekday schedule.
        OnCalendar = [
          ""
          "Mon..Fri *-*-* 10:00:00"
        ];
        # Run a missed check when the user session starts if the PC was off at 10:00.
        Persistent = true;
      };
    };

    systemd.user.services.paretosecurity-link = mkIf (cfg.inviteUrlFile != null) {
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
