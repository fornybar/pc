{ pkgs, mapHomeManagerUsers, ... }:
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
      bat.enable = true;

      vscode = {
        enable = true;
        mutableExtensionsDir = false;
        extensions = with pkgs.vscode-extensions; [ 
          bbenoist.nix
          hashicorp.terraform
          redhat.vscode-yaml
          ms-python.python
        ];
        userSettings = {
          "[nix]".editor.tabSize = 2;
        };
      };
    };
  });
}