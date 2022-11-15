{ pkgs, mapUsers, ... }:
{
  virtualisation.docker.enable = true;

  users.users = mapUsers (_: _: {
    extraGroups = [ "docker" ];
  });
}