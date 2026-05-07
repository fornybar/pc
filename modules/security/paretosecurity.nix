{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  cfg = config.midgard.pc.security.paretosecurity;

  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };

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
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable ParetoSecurity agent";
    };

    inviteUrl = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Team invite URL for automatic device enrollment.
        Format: paretosecurity://linkDevice?invite_id=<ID>
        Obtain from the ParetoSecurity team dashboard.
      '';
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (_: _: { paretosecurity = pkgs-unstable.paretosecurity; })
    ];

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
