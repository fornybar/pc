{ pkgs, mapHomeManagerUsers, ... }:
{
  home-manager.users = mapHomeManagerUsers (name: user: {
    programs = {
      chromium = {
        enable = true;
        package = pkgs.google-chrome;
      };
    };
  });
}