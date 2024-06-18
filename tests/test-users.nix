inputs:
with inputs;

let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
in
pkgs.nixosTest {
  name = "test-creation-of-users";

  nodes.machine = {
    imports = [
      self.nixosModules.users
      sops-nix.nixosModules.sops
    ];

    sops.age.keyFile = "/root/.config/sops/age/keys.txt";
    sops.defaultSopsFile = ./data/users/secrets.yaml;
    sops.secrets."user3/password".neededForUsers = true;

    midgard.pc.users = {
      # user without password
      user1 = {
        fullName = "User1";
        email = "user1@email.no";
      };

      # user with ahsed password
      user2 = {
        fullName = "User2";
        email = "user2@email.no";
        hashedPassword = "$6$c4MUWTrdpejuO.gA$AAiGWlNRWnt4dKZnT6mcs.JZoK.zKjAOWUYOgU7fiB4ZVU6qEqOcQjWpEXTzd/qC04nd69sB23Ml61mVxL7Lu/";
      };

      # user with password from sops
      user3 = {
        fullName = "User3";
        email = "user2@email.no";
      };
    };
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

        with subtest("Check user creation"):
          assert machine.succeed("getent passwd | grep user1") == 'user1:x:1000:100:User1:/home/user1:/run/current-system/sw/bin/bash\n', "user1 not created"
          assert machine.succeed("getent shadow | grep user1") == 'user1:!:1::::::\n', "Password creation for user1, whent wrong. Should be !, meaning disabled"

          assert machine.succeed("getent passwd | grep user2") == 'user2:x:1001:100:User2:/home/user2:/run/current-system/sw/bin/bash\n', "user2 not created"
          assert machine.succeed("getent shadow | grep user2") == 'user2:$6$c4MUWTrdpejuO.gA$AAiGWlNRWnt4dKZnT6mcs.JZoK.zKjAOWUYOgU7fiB4ZVU6qEqOcQjWpEXTzd/qC04nd69sB23Ml61mVxL7Lu/:1::::::\n', "Password creation for user3, whent wrong"

          assert machine.succeed("getent passwd | grep user3") == 'user3:x:1002:100:User3:/home/user3:/run/current-system/sw/bin/bash\n', "user3 not created"
          assert machine.succeed("getent shadow | grep user3") == 'user3:$6$gHR1CXIrV.g8yoM0$AnaJpnAKIvOHOP0y8d9jlEEyMsMSpFyYmSOtyXHoLiO0c49kVEH.DWy8Vn0t0zJEYWSPxV.tfKjRhprOyuoF60:1::::::\n', "Password creation for user3, whent wrong"

      '';
}
