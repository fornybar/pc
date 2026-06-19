# PC NixOS setup reference

These detailed descriptions, background notes, and debugging steps supplement the
first time [setup guide](./main.md). Each section maps to a step in the guide; jump
to the part you need rather than reading top to bottom.

- [Glossary](#glossary)
- [Booting from USB](#booting-from-usb) — supplements step 1
- [Installing NixOS](#installing-nixos) — supplements step 2
- [Connecting to the internet](#connecting-to-the-internet) — supplements step 3.1
- [Setting up the sops age key](#setting-up-the-sops-age-key) — supplements step 3.3
- [Secure Boot with lanzaboote](#secure-boot-with-lanzaboote) — supplements step 3.5
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Glossary

| Term | Meaning |
|------|---------|
| Secure Boot | Firmware feature that only boots trusted boot files. |
| BIOS/UEFI | Machine firmware settings screen. This is where Secure Boot is enabled. |
| ESP | EFI System Partition. Usually mounted at `/boot` or `/boot/efi`. Boot files live here. |
| Lanzaboote | NixOS tool that creates signed boot entries for Secure Boot. |
| sbctl | Tool that creates, enrolls, and checks Secure Boot signing keys. |
| Setup Mode | Firmware state where new Secure Boot keys can be enrolled. Disabling Secure Boot is **not** the same as Setup Mode. |
| sops / age | Tools for encrypting secrets in the repo. The age key decrypts them at build time. |
| nixos-enter | NixOS-friendly way to enter an installed system from a Live USB. Similar to `chroot`, but made for NixOS. |

## Booting from USB

Supplements [step 1](./main.md#1-boot-from-usb).

### Creating the bootable USB

Create a bootable USB flash drive from a terminal on Linux. Download the recommended
Graphical ISO image from:

- https://nixos.org/download/ (NixOS: the Linux distribution, 64-bit Intel/AMD)

and create the bootable USB stick following:

- https://nixos.org/manual/nixos/stable/#sec-booting-from-usb-linux

### Checking the ISO version on the USB

1. `mkdir nix-usb`
2. `sudo mount /dev/sdb ~/nix-usb`
3. `cat nix-usb/version.txt`

Remember to run `sudo umount nix-usb` before disconnecting the USB.

## Installing NixOS

Supplements [step 2](./main.md#2-install-nix).

- Try the default installer first. If it fails, work down the list of installers.
- **Unfree:** allow this when prompted.
- **Partitions:** Erase disk. Choose either no swap, or swap with **no hibernate**.
  Swap with hibernate together with disk encryption is hard to set up.
- If you create a swap partition, remember to add `randomEncryption.enable = true;`
  to the matching `swapDevices` entry in your config (see step 3.2).

## Connecting to the internet

Supplements [step 3.1](./main.md#31-get-personal-pc-repo-from-github). The setup
script needs network access to fetch the flake and clone your repo.

- If the display is not working after startup, switch to a terminal with
  `ctrl+alt+F1` (the hotkey may vary between machines).
- To connect to Wi-Fi from a terminal:

  ```bash
  nmcli connection add type wifi con-name <NAME> ifname <DEVICE> ssid <SSID>
  ```

  For WPA-EAP networks without a certificate, add:

  ```bash
  nmcli connection modify <NAME> \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap ttls \
    802-1x.identity <USERNAME> \
    802-1x.password '<PASSWORD>' \
    802-1x.phase2-auth mschapv2
  nmcli connection up <NAME>
  ```

- On a fresh NixOS config, flake commands require extra flags because the feature
  is not enabled yet:

  ```bash
  --extra-experimental-features 'nix-command flakes'
  ```

## Setting up the sops age key

Supplements [step 3.3](./main.md#33-set-up-sops-age-key).

You can reuse an existing age key by copying it to
`/root/.config/sops/age/keys.txt`, or create a new one:

```bash
nix-shell -p age
sudo mkdir -p /root/.config/sops/age
sudo age-keygen -o /root/.config/sops/age/keys.txt
```

> The commands after `nix-shell -p age` are meant to run **inside** the shell it
> opens. `age-keygen` comes from that shell, so run the `sudo` commands from the
> same prompt.

To read the public key from a root-owned key file:

```bash
sudo grep 'public key' /root/.config/sops/age/keys.txt
```

Then, in `./personal_pc_repo`:

1. Fill out `.sops.yaml` with the public key part from `/root/.config/sops/age/keys.txt`.
2. Enter a shell with sops: `nix-shell -p sops`.
3. Run `sudo sops secrets.yaml`.
4. Delete all lines.
5. Fill out values according to the templates in this repo:
   [secrets.tmp.yaml](/templates/hardware/secrets.tmp.yaml):
   - **github-token:** generate a GitHub token with access *admin.org, repo,
     workflow*, and remember to authorize the fornybar organization.
   - **password:** run `mkpasswd -m sha-512 <password>` and paste the result.
   - **nixbuild-ssh:** `""` (leave empty).

The setup script verifies that root can actually decrypt `secrets.yaml` before it
rebuilds, so a missing key or a wrong recipient in `.sops.yaml` will stop the
script with a clear error.

## Secure Boot with lanzaboote

Supplements [step 3.5](./main.md#35-configure-secure-boot-keys). The setup script
already runs `sbctl create-keys` and `nixos-rebuild boot` for you; this section
explains what is happening, how to verify it, and how to recover.

### How Secure Boot works here

`sbctl create-keys` creates local signing keys in `/var/lib/sbctl`. Keep this
directory — if it is deleted, the machine can lose the keys needed for Secure Boot.

During `nixos-rebuild`, lanzaboote signs the **boot files** (bootloader, kernel,
initrd) with those keys. It does not sign the keys themselves. The order that keeps
the machine bootable is:

```diagram
╭───────────────────╮   ╭──────────────────────╮   ╭──────────────────────╮
│ sbctl create-keys │──▶│ nixos-rebuild signs  │──▶│ enroll keys + enable │
│ (/var/lib/sbctl)  │   │ boot files (rebuild) │   │ Secure Boot in BIOS  │
╰───────────────────╯   ╰──────────────────────╯   ╰──────────────────────╯
```

Never enable Secure Boot in firmware before the signed rebuild has happened — the
bootloader would be unsigned and the machine would not boot.

> **Prerequisite:** the chosen NixOS configuration must set
> `midgard.pc.security.secureboot.enable = true;`. The setup script checks this with
> `nix eval` and refuses to continue otherwise.

### Checking the lanzaboote pin

This matters mainly if you are editing `pc` itself. The shared `pc` flake pins
lanzaboote to a known working release:

```nix
inputs.lanzaboote.url = "github:nix-community/lanzaboote/v1.0.0";
```

Check the lock file uses `v1.0.0`:

```bash
jq '.nodes.lanzaboote.original' flake.lock
```

Expected shape:

```json
{
  "owner": "nix-community",
  "ref": "v1.0.0",
  "repo": "lanzaboote",
  "type": "github"
}
```

Unpinned lanzaboote versions can change boot behavior, so do not skip the pin.

### Creating and inspecting Secure Boot keys

To inspect key and Secure Boot state at any point:

```bash
sudo sbctl status
```

Check whether Microsoft/vendor keys are enrolled. If `Vendor Keys` does **not** say
`microsoft`, you need to [enter Setup Mode](#entering-setup-mode) and enroll keys.
If it already says `microsoft`, do not clear Secure Boot keys and do not enroll
again.

The `--microsoft` flag enrolls your own keys together with Microsoft/vendor keys,
which many PCs need for firmware, docks, GPUs, and other vendor-signed boot
components. `--firmware-builtins` additionally enrolls the firmware's built-in keys.

### Entering Setup Mode

Setup Mode lets firmware accept new Secure Boot keys. Use this only if `sbctl status`
shows that keys are not enrolled.

Open BIOS/UEFI settings and clear the Secure Boot key database. The exact menu is
machine-dependent; look for options like `Clear Secure Boot Keys`,
`Delete All Secure Boot Keys`, or `Reset Secure Boot Keys`.

On some HP machines this is locked by HP Sure Start:

1. Enter BIOS (often **F10**).
2. Set a BIOS administrator password if required.
3. Go to **HP Sure Start** and disable **Sure Start Key Protection**.
4. Go to **Security → Secure Boot Configuration**.
5. Clear Secure Boot keys.
6. Continue boot into Setup Mode.

After clearing keys, boot NixOS and enroll keys:

```bash
sudo sbctl enroll-keys --microsoft --firmware-builtins
sudo sbctl status
```

Expected after enrollment:

```text
Setup Mode: disabled
Vendor Keys: microsoft
```

### Verifying before enabling Secure Boot

Before turning Secure Boot on in BIOS, confirm the rebuild produced a signed
lanzaboote generation:

```bash
bootctl status
sudo sbctl status
sudo sbctl verify
```

`bootctl status` should show systemd-boot installed and the default entry as a
lanzaboote generation under `EFI/Linux`:

```text
Default Boot Loader Entry:
         type: Boot Loader Specification Type #2 (UKI, .efi)
       source: /boot//EFI/Linux/nixos-generation-...efi
     sort-key: lanza
```

`Secure Boot: disabled` is expected at this stage.

`sbctl verify` may report:

```text
✗ /boot/EFI/nixos/kernel-...efi is not signed
✓ /boot/EFI/BOOT/BOOTX64.EFI is signed
✓ /boot/EFI/Linux/nixos-generation-...efi is signed
✓ /boot/EFI/systemd/systemd-bootx64.efi is signed
```

The unsigned `kernel-*` (and `initrd-*`) line is **OK** for lanzaboote — do not sign
those manually. Firmware verifies the signed lanzaboote entry, then lanzaboote
verifies the kernel and initrd by hash. The files that must be signed are:

- `/boot/EFI/Linux/nixos-generation-*.efi`
- `/boot/EFI/BOOT/BOOTX64.EFI`
- `/boot/EFI/systemd/systemd-bootx64.efi`

If only `BOOTX64.EFI` or `systemd-bootx64.efi` is unsigned, sign just those:

```bash
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
```

If your ESP is mounted at `/boot/efi`, use `/boot/efi/...` paths instead.

**Stop and do not enable Secure Boot** if the generation files under
`/boot/EFI/Linux/` are unsigned, or if `bootctl status` does not show a lanzaboote
generation with `sort-key: lanza`. As an extra safety step, reboot once with Secure
Boot still disabled and re-check `bootctl status` before continuing.

### Enabling Secure Boot in BIOS

Open firmware settings:

```bash
systemctl reboot --firmware-setup
```

Then:

1. Find the Secure Boot settings.
2. Enable Secure Boot (re-enable **Sure Start Key Protection** on HP).
3. Do not clear keys if `sbctl status` already showed `Vendor Keys: microsoft`.
4. Save and boot.

After boot, verify:

```bash
sudo sbctl status
bootctl status | grep -i 'Secure Boot'
```

Both should report `Secure Boot: enabled`.

### Recovery if the machine will not boot

If the machine does not boot after enabling Secure Boot, get back in by temporarily
disabling the Secure Boot module from a Live USB.

1. Disable Secure Boot in BIOS.
2. Boot from a NixOS Live USB.
3. Find the installed root and boot partitions:

   ```bash
   lsblk -f
   ```

4. Mount the installed system (replace devices with the correct ones from `lsblk`).

   If root is encrypted, unlock it first:

   ```bash
   sudo cryptsetup open /dev/<encrypted-root-partition> cryptroot
   sudo mount /dev/mapper/cryptroot /mnt
   sudo mount /dev/<efi-partition> /mnt/boot
   ```

   If root is not encrypted:

   ```bash
   sudo mount /dev/<root-partition> /mnt
   sudo mount /dev/<efi-partition> /mnt/boot
   ```

5. Enter the installed system:

   ```bash
   sudo nixos-enter --root /mnt
   ```

6. In the host config repo, set:

   ```nix
   midgard.pc.security.secureboot.enable = false;
   ```

   This makes the machine bootable again without needing the `pc` repo from the
   Live USB.

7. Rebuild, exit, and reboot:

   ```bash
   sudo nixos-rebuild switch --flake .#<hostname>
   exit
   sudo reboot
   ```

8. Boot once with Secure Boot still disabled. Once the machine boots normally,
   update the host to the latest `pc` input, re-enable
   `midgard.pc.security.secureboot.enable = true;`, rebuild, and re-verify before
   enabling Secure Boot in BIOS again.

## Troubleshooting

- **Display broken on startup:** switch to a terminal with `ctrl+alt+F1` (hotkey may
  vary between machines).
- **No network:** see [Connecting to the internet](#connecting-to-the-internet).
- **Flake commands rejected:** add `--extra-experimental-features 'nix-command flakes'`.
- **Empty home directory after first boot:** if the username in the config differs
  from the username chosen during the graphical install, the machine boots with a
  new, empty `/home` directory. Files saved before the change are under
  `/home/<old_user>`. Pushing your config to git before rebooting avoids confusion
  here.
- **Re-running the setup script:** always run it from the same directory. It keeps
  state in `./personal_pc_repo` and `./.setup-config`, and reuses an existing
  GitHub login instead of prompting again.

## References

- [Lanzaboote repository](https://github.com/nix-community/lanzaboote)
- [NixOS Wiki: Lanzaboote](https://wiki.nixos.org/wiki/Lanzaboote)
