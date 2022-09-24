inputs: {
  inherit (import ./test-nix.nix inputs) test-nix-module-with-nix-input test-nix-module-no-nix-input;
  test-module-users = import ./test-users.nix inputs;
}