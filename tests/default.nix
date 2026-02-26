inputs: {
  test-nix-module = import ./test-nix.nix inputs;
  test-module-users = import ./test-users.nix inputs;
  test-nix-access-tokens = import ./test-nix-access-tokens.nix inputs;
}
