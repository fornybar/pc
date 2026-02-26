{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Garbage collect once every week
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
}
