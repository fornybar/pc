{ config, lib, midgardUsers, ... }:
with lib;
{
  # Add nix access-tokens for root user
  nix.extraOptions = ''
    !include /etc/nix/access-tokens
  '';

  system.activationScripts."nix-access-tokens" = {
    deps = [ "etc" "setupSecrets" ];
    text = ''
      echo "setting up nix access-tokens"
      mkdir -p /etc/nix
      echo "access-tokens = github.com=$(cat ${config.sops.secrets.github-token.path})" > /etc/nix/access-tokens
      chmod 400 /etc/nix/access-tokens
    '';
  };


  # Add access-token for each user
  system.userActivationScripts = mkMerge (map (name:
    {
      "nix-access-tokens-${name}" = {
        deps = [ ];
        text = ''
          echo "setting up nix access-tokens for ${name}"
          mkdir -p ~/.config/nix
          echo "access-tokens = github.com=$(cat ${config.sops.secrets."${name}/github-token".path})" > ~/.config/nix/nix.conf
          chmod 400 ~/.config/nix/nix.conf
        '';
      };
    }) midgardUsers
  );
}