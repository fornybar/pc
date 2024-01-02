{ pkgs, mapHomeManagerUsers, ... }:
{
  home-manager.users = mapHomeManagerUsers (name: user: {
    programs = {
      # Shells
      bash.enable = true;
      fish.enable = true;
      zsh.enable = true;

      fzf.enable = true;
      bat.enable = true;
    };
  });
}