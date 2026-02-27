{ pkgs, mapHomeManagerUsers, ... }:
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
}
