{ self, pkgs, lib, sops-nix, midgardUsers, ... }:
{

  imports = [
    sops-nix.darwinModules.sops
  ];

  environment.systemPackages = [ pkgs.sops ];

  sops.age.keyFile = "/etc/sops/age/keys.txt";
  sops.defaultSopsFile = "${self}/secrets.yaml";

  sops.secrets = lib.mkMerge ([
    { github-token = { }; } # github-token for root/system
  ] ++ (map (name:{
    "${name}/github-token".owner = name;
    "${name}/password".neededForUsers = true;
  }) midgardUsers));

}
