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
  ];
}