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

    sops.age.keyFile = "/root/.config/sops/age/keys.txt";
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
    def cmd(command):
      print(f"+{command}")
      r = os.system(command)
      if r != 0:
        raise Exception(f"Command {command} failed with exit code {r}")

    machine.start(True)

    # Copy age secret into machine
    cmd('echo "AGE-SECRET-KEY-1EGD55T6D8AUD7G03UDDKHMDDCQKKF4H93TEJ207G3RN85UDWMN7SYYPTTG" > keys.txt')
    machine.copy_from_host("keys.txt", "/root/.config/sops/age/keys.txt")

    # Reboot machine with age secret key loaded
    machine.wait_for_file("/root/.config/sops/age/keys.txt")
    machine.reboot()

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
      assert stdout == "600\n", f"{stdout}"
  '';
}