{ pkgs, mapHomeManagerUsers, ... }:
{
  home-manager.users = mapHomeManagerUsers (name: user: {
    programs = {
      # Shells
      bash.enable = true;
      fish.enable = true;
      zsh.enable = true;

      starship.enable = true;
      chromium = {
        enable = true;
        package = pkgs.google-chrome;
      };
      fzf.enable = true;
      bat.enable = true;
    };
  });
}