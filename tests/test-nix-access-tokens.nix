inputs:
with inputs;

let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
in
pkgs.nixosTest {
  name = "test-nix-access-tokens";

  nodes.machine = {
    imports = [
      self.nixosModules.nix-access-tokens
      self.nixosModules.users
      sops-nix.nixosModules.sops
    ];

    sops.age.keyFile = ./data/keys.txt;
    sops.defaultSopsFile = ./data/nix-access-tokens/secrets.yaml;
    sops.secrets.github-token = { };
    sops.secrets."user1/github-token".owner = "user1";

    midgard.pc.users = {
      # user without password
      user1 = {
        fullName = "User1";
        email = "user1@email.no";
      };
    };
    users.users.user1.initialPassword = "pass";
  };

  testScript = ''
    start_all()

    with subtest("Check access-token file creation"):
      stdout = machine.succeed("cat /etc/nix/access-tokens")
      assert stdout == "access-tokens = github.com=root-github-token\n", f"{stdout}"

    with subtest("Check file mode for access-token"):
      stdout = machine.succeed("stat -c '%a' /etc/nix/access-tokens")
      assert stdout == "400\n", "File mode for /etc/nix/access-tokens should be 400"

    with subtest("Login as user1"):
      machine.wait_until_tty_matches("1", "login: ")
      machine.send_chars("user1\n")
      machine.wait_until_tty_matches("1", "Password: ")
      machine.send_chars("pass\n")
      machine.wait_for_file("/home/user1/.config/nix/nix.conf")

    with subtest("Check user access-token file creation"):
      stdout = machine.succeed("cat /home/user1/.config/nix/nix.conf")
      assert stdout == "access-tokens = github.com=user1-github-token\n", f"{stdout}"

    with subtest("Check file mode for access-token"):
      stdout = machine.succeed("stat -c '%a' /home/user1/.config/nix/nix.conf")
      assert stdout == "400\n", f"{stdout}"
  '';
}