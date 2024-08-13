# First time NixOS install

Guide to fresh install Linux NixOS on computer. Will erase everything existing on PC.

## 0.1 USB-setup

Create bootable USB flash drive from terminal on Linux. Download recommended Graphical ISO image from

- https://nixos.org/download/

and create bootable USB stick here

- https://nixos.org/manual/nixos/stable/#sec-booting-from-usb-linux


## 1. [Boot from USB](https://nixos.org/manual/nixos/stable/#sec-installation-booting)
- Turn on PC and enter boot menu.
  - For HP Firefly G11 this is by pressing F9 during startup
- Make sure secure boot is turned off. If not off, turn off then save BIOS, restart and re-enter boot menu.
  - For HP this is by pressing esc to enter BIOS menu. Then Security -> Secure Boot Configuration and uncheck Secure Boot.
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
- Run `lsblk -o name,label,size,path` to see partitions
- Run `fatlabel <PATH-OF-BOOT-PARTITION> boot` as root
- Run `e2label <PATH-OF-MAIN-PARTITION> nixos` (probably needs restart to show)
- Make sure swap partition is labeled `swap` if you are using it


## 4. Setup git repo for NixOS config

### 4.1 Initialize repo

Either clone existing pc config repo to your new pc or make a new one. When making a new one, use the template from this repo with `nix flake init --template github:fornybar/pc`.

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
- Fill out `.sops.yaml` with the public key part from `/root/.config/sops/age/keys.txt`.
- Enter shell with sops `nix-shell -p sops`
- Run `sudo sops .secrets.yaml` and fill out values according to the templates in this repo.

### 4.3 Review your flake.nix

Make sure you
- Replace necessary values from the flake template with your own personal value.
- Utilize the useful modules from this repo by for instance adding `pc.nixosModules.hdw-<NAME-OF-MACHINE>` and `pc.nixosModules.default` in the nixos module list.
- If you have a swap partition you must include it manually by adding `swapDevices = [ { label = "swap"; } ];` to NixOS config.

## 5. Rebuild, reboot and rejoice!
- `sudo nixos-rebuild boot --flake .#<NAME-OF-NIXOSCONFIGURATION>`
- `reboot`

