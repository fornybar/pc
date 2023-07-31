inputs:
with inputs;

let
  pkgs = import nixpkgs { system = "x86_64-linux"; };

  nixStandard = pkgs.nix.version;
  nixLatest = nix.packages.x86_64-linux.nix.version;

  makeTest = { expectedNixVersion, specialArgs ? { } }:
  (nixpkgs.lib.nixos.runTest {
    name = "test-nix-module";
    hostPkgs = pkgs;
    node.specialArgs = specialArgs;
    nodes.machine = ({ pkgs, ... }:{
      imports = [ self.nixosModules.nix ];
      environment.systemPackages = [ pkgs.jq ];
    });

    testScript = ''
      start_all()

      with subtest("Check nix version"):
        status, stdout = machine.execute("nix --version")
        assert stdout == "nix (Nix) ${expectedNixVersion}\n", f"Got {stdout.strip()} expected nix version ${expectedNixVersion}"

      with subtest("Check nix settings"):
       machine.succeed("""nix show-config --json | jq -e '."experimental-features".value as $val | $val == ["flakes", "nix-command"] or $val == [2, 3]'""")
    '';
  });

in {
  test-nix-module-with-nix-input = makeTest {
    expectedNixVersion = nixLatest;
    specialArgs = { nix = inputs.nix; };
  };

  test-nix-module-no-nix-input = makeTest {
    expectedNixVersion = nixStandard;
  };

}
