{
  nixpkgs.config.allowUnfree = true;

  # Solve that nixpkgs is looked to system installation
  # See paragraph 4 in https://nixos.org/manual/nixos/stable/release-notes#sec-release-24.05-highlights
  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };
}