{ mapHomeManagerUsers, ... }:
{
  home-manager.users = mapHomeManagerUsers (name: user: {
    programs = {
      # Shells
      bash.enable = true;
      fish.enable = true;
      zsh.enable = true;

      starship.enable = true;
      firefox.enable = true;
      fzf.enable = true;
    };
  });
}