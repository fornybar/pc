{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    jq
    tree
    tig
    age
    azure-cli
    git-absorb
    neofetch
    starship
  ];

  programs.starship.enable = true;
}