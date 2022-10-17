{ self, pkgs, lib, sops-nix, midgardUsers, ... }:
{

  imports = [ 
    sops-nix.nixosModules.sops
  ];

  environment.systemPackages = [ pkgs.sops ];

  sops.age.keyFile = "/root/.config/sops/age/keys.txt";
  sops.defaultSopsFile = "${self}/secrets.yaml";

  sops.secrets = lib.mkMerge ([
    { github-token = { }; } # github-token for root/system
  ] ++ (map (name:{
    "${name}/github-token".owner = name;
    "${name}/password".neededForUsers = true;
  }) midgardUsers));

}