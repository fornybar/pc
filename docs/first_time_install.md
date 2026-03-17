# First time NixOS install

Guide to fresh install Linux NixOS on computer. Will erase everything existing on PC.

## 0.1 USB-setup

Create bootable USB flash drive from terminal on Linux. Download recommended Graphical ISO image from

- https://nixos.org/download/ (NixOS : the Linux distribution, 64-bit Intel/AMD)

and create bootable USB stick here

- https://nixos.org/manual/nixos/stable/#sec-booting-from-usb-linux

To check which version available on the USB:
1. `mkdir nix-usb`
2. `sudo mount /dev/sdb ~/nix-usb`
3. `cat nix-usb/version.txt`
Remember to run `sudo umount nix-usb` before disconnecting the USB.

## 1. [Boot from USB](https://nixos.org/manual/nixos/stable/#sec-installation-booting)
- Turn on PC and enter boot menu.
  - For *HP Firefly G11* and *EliteBook Ultra* this is by pressing *F9* during startup
- Make sure *secure boot* is turned off. If not off:
  1. Turn off then save BIOS
  2. Restart and re-enter boot menu.
    For HP this is by:
    - Pressing esc to enter BIOS menu.
    - Then `Configuration -> Boot Option -> Secure Boot Configuration` and uncheck Secure Boot.
- Select UEFI USB disk in boot menu
- This will open a list of Nix installers to use

## 2. Install nix
- Try default installer first
  - If this fails you can try subsequently down the list
- Follow instructions from installer
  - Unfree: You can allow this
  - Partitions: We recommend Erase disk with Swap and hibernate
- Reboot when installer is done

## 2.5 Useful tips
- If something fails during startup and display is not working properly use `ctrl+alt+F1` to enter terminal. Hotkey may vary on machines.
- To connect to wifi from terminal run
  - `nmcli connection add type wifi con-name <NAME> ifname <DEVICE> ssid <SSID>`
  - Add this WPA EAP without certificate `wifi-sec.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.identity <USERNAME> 802-1x.password '<PASSWORD>' 802-1x.phase2-auth mschapv2`
- To use flake commands on basic NixIS config we must add the flags `--extra-experimental-features nix-command --extra-experimental-features flakes`. Flake commands have to be enabled specifically in NixOS config.

## 3. Label partitions
In order to use file system module in this repo we must configure disk labels.
- Run `lsblk -o name,label,size,path` to see partitions.
  One of the partitons (might start with with nvme), gives paths:
  * `<PATH-OF-BOOT-PARTITION>` has no label and of smaller size
  * `<PATH-OF-MAIN-PARTITION>` has label root
- Run `fatlabel <PATH-OF-BOOT-PARTITION> boot` as root
- Run `e2label <PATH-OF-MAIN-PARTITION> nixos` (probably needs restart to show)
- Make sure swap partition is labeled `swap` if you are using it


## 4. Setup git repo for NixOS config

### 4.1 Initialize repo

Either clone existing pc config repo to your new pc or make a new one. When making a new one, use the template from this repo with `nix flake init --template github:fornybar/pc`.

The repo should be called `pc.<your_name>`.
In github/fornybar search for pc, and each developer has their own pc repo you can use as guide/inspiration.

In your flake ( or often in hardware.nix) you need to ignore/comment this line, before rebuilding:
`# boot.loader.efi.efiSysMountPoint = lib.mkForce "/boot";`
After rebooting (the final step in this guide), you can add the line back.

### 4.2 Configure sops

Configure sops key as root user from git repo root folder created in [4.1]().

- `cd /path/of/repo/directory` to enter git repo root folder
- Add existing age key to `/root/.config/sops/age/keys.txt` or create new with

```bash
nix-shell -p age
sudo mkdir -p /root/.config/sops/age
sudo age-keygen -o /root/.config/sops/age/keys.txt
```

Then
1. Fill out `.sops.yaml` with the public key part from `/root/.config/sops/age/keys.txt`.
2. Enter shell with sops `nix-shell -p sops`
3. Run `sudo sops secrets.yaml`.
4. Delete all lines.
5. Fill out values according to the templates in this repo: [secrets.tmp.yaml](/templates/hardware/secrets.tmp.yaml):
   - github-token: generate github token with access *admin.org, repo, workflow*, and remember to authorize fornybar organization
   - password: run `mkpasswd -m sha-512 <passord>` and pass result
   - nixbuild-ssh: "" (leave empty)

### 4.3 Review your flake.nix

Make sure you
- Replace necessary values from the flake template with your own personal value.
- Utilize the useful modules from this repo by for instance adding `pc.nixosModules.hdw-<NAME-OF-MACHINE>` and `pc.nixosModules.default` in the nixos module list.
- If you have a swap partition you must include it manually by adding `swapDevices = [ { label = "swap"; } ];` to NixOS config.

## 5. Rebuild, reboot and rejoice!
- `sudo nixos-rebuild boot --flake .#<NAME-OF-NIXOSCONFIGURATION> --option access-tokens "github.com=........."`

  The first time you have to add access token option.

- If working, push your pc configuration upstream to git before rebooting.

  A problem that might happen if you dont push your config to git: A diff between username in the config and the username chosen in the GUI install phase, causes the machine to boot with a new (empty)  `home` directory. If you have stored any files prior to the username change then these are found in `/home/<old_user>`.This is not a big problem, just more tricky to find the config again.

- `reboot`

- The next time you do changes to the flake run:

  `sudo nixos-rebuild --flake .#<NAME-OF-NIXOSCONFIGURATION>`

