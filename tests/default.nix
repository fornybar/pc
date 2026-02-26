inputs: {
  # test-nix-module-with-nix-input is disabled: the custom nix input (2.23.0)
  # uses separateDebugInfo without __structuredAttrs, which nixpkgs 25.11's
  # mkDerivation now rejects. Re-enable when the nix input is updated to a
  # version compatible with 25.11.
  inherit (import ./test-nix.nix inputs) test-nix-module-no-nix-input;
  test-module-users = import ./test-users.nix inputs;
  test-nix-access-tokens = import ./test-nix-access-tokens.nix inputs;
}
