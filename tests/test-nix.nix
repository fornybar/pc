inputs:
with inputs;

let
  pkgs = import nixpkgs { system = "x86_64-linux"; };

  nixStandard = pkgs.nix.version;
  nixLatest = nix.packages.x86_64-linux.nix.version;

  withNixInput = import "${nixpkgs}/nixos/lib/testing-python.nix" {
    system = "x86_64-linux";
    specialArgs = { inherit (inputs) nix; };
  };

  noNixInput = import "${nixpkgs}/nixos/lib/testing-python.nix" {
    system = "x86_64-linux";
  };

  makeTest = { name, environment, expectedNixVersion}:
    environment.makeTest {
      name = "test-with-nix-input";

      nodes.machine = { 
        imports = [ self.nixosModules.nix ];
        environment.systemPackages = [ pkgs.jq ];
      };

      testScript = ''
        start_all()

        with subtest("Check nix version"):
          status, stdout = machine.execute("nix --version")
          assert stdout == "nix (Nix) ${expectedNixVersion}\n", f"Got {stdout.strip()} expected nix version ${expectedNixVersion}"

        with subtest("Check nix settings"):
          machine.succeed("""nix show-config --json | jq -e '."experimental-features".value as $val | $val == ["flakes", "nix-command"] or $val == [2, 3]'""")
      '';
    };

in {
  test-nix-module-with-nix-input = makeTest {
    name = "test-with-nix-input";
    environment = withNixInput;
    expectedNixVersion = nixLatest;
  };

  test-nix-module-no-nix-input = makeTest {
    name = "test-without-nix-input";
    environment = noNixInput;
    expectedNixVersion = nixStandard;
  };

}