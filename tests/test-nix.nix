inputs:
with inputs;

let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
in
nixpkgs.lib.nixos.runTest {
  name = "test-nix-module";
  hostPkgs = pkgs;
  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ self.nixosModules.nix ];
      environment.systemPackages = [ pkgs.jq ];
    };

  testScript = ''
    start_all()

    with subtest("Check nix version"):
      status, stdout = machine.execute("nix --version")
      assert stdout == "nix (Nix) ${pkgs.nix.version}\n", f"Got {stdout.strip()} expected nix version ${pkgs.nix.version}"

    with subtest("Check nix settings"):
     machine.succeed("""nix show-config --json | jq -e '."experimental-features".value as $val | $val == ["flakes", "fetch-tree", "nix-command"] or $val == ["flakes", "nix-command"]'""")
  '';
}
