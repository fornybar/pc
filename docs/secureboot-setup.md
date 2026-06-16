# Secure Boot with Lanzaboote

This guide explains the safe way to enable Secure Boot on NixOS with Lanzaboote.

The short version:

1. Update the host flake to the latest shared `pc` config.
2. Check that `pc` pins Lanzaboote to `v1.0.0`.
3. Create Secure Boot keys.
4. Enable the NixOS module and rebuild.
5. Verify that the default boot entry is a Lanzaboote generation.
6. Reboot once while Secure Boot is still disabled in BIOS.
7. Enable Secure Boot in BIOS.
8. Verify that Secure Boot is enabled.

## Before you start

Make sure:

- NixOS already boots in UEFI mode.
- The machine uses the shared `pc` config.
- The ESP is mounted at `/boot` or `/boot/efi`.
- You have a NixOS Live USB nearby in case recovery is needed.

## Terms you need to know

| Term | Meaning |
|------|---------|
| Secure Boot | Firmware feature that only boots trusted boot files. |
| BIOS/UEFI | Machine firmware settings screen. This is where Secure Boot is enabled. |
| ESP | EFI System Partition. This is usually mounted at `/boot` or `/boot/efi`. Boot files live here. |
| Lanzaboote | NixOS tool that creates signed boot entries for Secure Boot. |
| sbctl | Tool that creates, enrolls, and checks Secure Boot signing keys. |
| Setup Mode | Firmware state where new Secure Boot keys can be enrolled. Disabling Secure Boot is not the same as Setup Mode. |
| nixos-enter | NixOS-friendly way to enter an installed system from a Live USB. Similar purpose as `chroot`, but made for NixOS. |

## 1. Update the host to the latest `pc`

Before enabling Secure Boot, make sure the host flake follows the latest `pc` version:

```bash
nix flake update pc
```

Then rebuild once:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

This is important because `pc` pins Lanzaboote to a known working release.

Do not skip this step. Unpinned Lanzaboote versions can change boot behavior.

## 2. Check the Lanzaboote pin

Most users only need step 1. This step is mainly for people editing `pc` itself.

The shared `pc` flake should use a tagged Lanzaboote release:

```nix
inputs.lanzaboote.url = "github:nix-community/lanzaboote/v1.0.0";
```

If you are editing `pc` itself, update its lock file:

```bash
nix flake update lanzaboote
```

Check that the `pc` lock file uses `v1.0.0`:

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

## 3. Create Secure Boot keys

Run this on the target machine:

```bash
sudo sbctl create-keys
sudo sbctl status
```

`sbctl create-keys` creates local signing keys. It does not by itself enable Secure Boot in BIOS.

Keys are stored in:

```text
/var/lib/sbctl
```

Keep this directory. If it is deleted, the machine can lose the keys needed for Secure Boot.

Check whether Microsoft/vendor keys are enrolled:

```bash
sudo sbctl status
```

If `Vendor Keys` does not say `microsoft`, go to [Entering Setup Mode](#entering-setup-mode) and enroll Microsoft keys.

If `Vendor Keys` already says `microsoft`, do not clear Secure Boot keys and do not enroll again.

## Entering Setup Mode

Use this section only if `Vendor Keys` does not say `microsoft` in `sudo sbctl status`. Setup Mode lets firmware accept new Secure Boot keys.

Check status with:

```bash
sudo sbctl status
```

If `Vendor Keys` already says `microsoft`, skip this section and continue with step 4. If it does not say `microsoft`, follow the steps below.

### 1. Enter Setup Mode

Open BIOS/UEFI settings and clear the Secure Boot key database. The exact menu is PC-dependent. Look for options like:

- `Clear Secure Boot Keys`
- `Delete All Secure Boot Keys`
- `Reset Secure Boot Keys`

On some HP machines this option may be locked by HP Sure Start:

1. Enter BIOS with **F10**.
2. Set a BIOS administrator password if required.
3. Go to **HP Sure Start**.
4. Disable **Sure Start Key Protection**.
5. Go to **Security → Secure Boot Configuration**.
6. Clear Secure Boot keys.

### 2. Enroll Microsoft keys

After clearing keys, boot NixOS and enroll keys:

```bash
sudo sbctl enroll-keys --microsoft
sudo sbctl status
```

The `--microsoft` flag enrolls your own Secure Boot keys together with Microsoft/vendor keys. This is needed on many PCs for firmware, docks, GPUs, and other vendor-signed boot components.

Expected `sbctl status` after enrollment:

```text
Setup Mode: disabled
Vendor Keys: microsoft
```

Then continue with step 4. Do not enable Secure Boot in BIOS yet. First rebuild, verify, and complete one reboot with Secure Boot still disabled.

## 4. Enable the NixOS module

In the host config:

```nix
midgard.pc.security.secureboot.enable = true;
```

Rebuild:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

If you are testing local changes in `~/fornybar/pc`, use:

```bash
sudo nixos-rebuild switch --flake .#<hostname> --override-input pc ~/fornybar/pc
```

## 5. Verify before rebooting

Run:

```bash
bootctl status
sudo sbctl status
sudo sbctl verify
```

`bootctl status` should show that systemd-boot is installed and that the default boot entry is a Lanzaboote generation under `EFI/Linux`:

```text
Current Boot Loader:
       Product: systemd-boot ...

Default Boot Loader Entry:
         type: Boot Loader Specification Type #2 (UKI, .efi)
       source: /boot//EFI/Linux/nixos-generation-...efi
     sort-key: lanza
```

`Secure Boot: disabled` is expected here if it has not been enabled in BIOS yet.

Stop here if `bootctl status` does not show a Lanzaboote generation under `EFI/Linux` with `sort-key: lanza`. Do not enable Secure Boot in BIOS until this looks right.

Before Secure Boot is enabled in BIOS, `sbctl status` may show:

```text
Secure Boot: disabled
Setup Mode: disabled
```

That is OK.

`sbctl verify` may show this:

```text
✗ /boot/EFI/nixos/kernel-...efi is not signed
✓ /boot/EFI/BOOT/BOOTX64.EFI is signed
✓ /boot/EFI/Linux/nixos-generation-...efi is signed
✓ /boot/EFI/systemd/systemd-bootx64.efi is signed
```

The unsigned `kernel-*` line is OK for Lanzaboote. Do not sign it manually. Also do not manually sign `initrd-*`.

Lanzaboote stores the kernel and initrd as separate files. Firmware verifies the signed Lanzaboote boot entry first. Then Lanzaboote verifies the kernel and initrd by checking their hashes. Do not try to "fix" the unsigned kernel line manually. In this setup, the confirmed fix for boot trouble was updating `pc`, which pins Lanzaboote to `v1.0.0`.

The important signed files are:

- `/boot/EFI/Linux/nixos-generation-*.efi`
- `/boot/EFI/BOOT/BOOTX64.EFI`
- `/boot/EFI/systemd/systemd-bootx64.efi`

Stop here if the generation files under `/boot/EFI/Linux/` are unsigned. Do not enable Secure Boot in BIOS yet.

If `BOOTX64.EFI` or `systemd-bootx64.efi` is unsigned, sign only those files:

```bash
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
```

If your ESP is mounted at `/boot/efi`, use `/boot/efi/...` paths instead.

## 6. Reboot once before enabling Secure Boot

This is the most important safety step. Do not enable Secure Boot in BIOS before this reboot works.

Keep Secure Boot disabled in BIOS and reboot:

```bash
systemctl reboot
```

After boot, check:

```bash
bootctl status
```

Expected shape:

```text
System:
   Secure Boot: disabled

Current Boot Loader:
       Product: systemd-boot ...

Default Boot Loader Entry:
         type: Boot Loader Specification Type #2 (UKI, .efi)
        title: NixOS ... (Generation ...)
           id: nixos-generation-...
       source: /boot//EFI/Linux/nixos-generation-...efi
     sort-key: lanza
        linux: /boot//EFI/Linux/nixos-generation-...efi
```

The important parts are:

- `Secure Boot: disabled` because BIOS Secure Boot is still off
- `type: Boot Loader Specification Type #2 (UKI, .efi)`
- `source: /boot//EFI/Linux/nixos-generation-...efi`
- `sort-key: lanza`

If this boot works and `bootctl status` looks like this, Lanzaboote works.

Stop here if this reboot fails or if `bootctl status` no longer shows the Lanzaboote generation. Do not enable Secure Boot in BIOS yet.

## 7. Enable Secure Boot in BIOS

Open firmware settings:

```bash
systemctl reboot --firmware-setup
```

Then:

1. Find Secure Boot settings.
2. Enable Secure Boot.
3. Do not clear keys if `sbctl status` already showed `Vendor Keys: microsoft`. If it did not, complete [Entering Setup Mode](#entering-setup-mode) before enabling Secure Boot.
4. Save and boot.

After boot, verify:

```bash
sudo sbctl status
bootctl status | grep -i 'Secure Boot'
```

Expected:

```text
Secure Boot: enabled
```

Final success checklist:

- `sudo sbctl status` shows `Secure Boot: enabled`.
- `bootctl status` shows `Secure Boot: enabled`.
- Default boot entry is under `/boot/EFI/Linux/nixos-generation-...efi`.
- The machine has rebooted successfully after Secure Boot was enabled.

## Recovery notes

Use this if the machine does not boot after enabling Secure Boot. Goal: get back into the installed system by temporarily disabling the Secure Boot module. After the machine boots normally, update `pc` and re-enable Secure Boot.

Use a NixOS Live USB to enter the installed system and rebuild it.

1. Disable Secure Boot in BIOS.
2. Boot from a NixOS Live USB.
3. Find the installed root and boot partitions:

   ```bash
   lsblk -f
   ```

4. Mount the installed system. Replace the devices with the correct ones from `lsblk`.

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

   Example shape:

   ```bash
   sudo mount /dev/nvme0n1p2 /mnt
   sudo mount /dev/nvme0n1p1 /mnt/boot
   ```

5. Enter the installed system:

   ```bash
   sudo nixos-enter --root /mnt
   ```

6. Go to the host config repo and temporarily disable Secure Boot:

   ```bash
   cd /home/<user>/<host-config-repo>
   ```

   Set this in the host config:

   ```nix
   midgard.pc.security.secureboot.enable = false;
   ```

   This gets the machine bootable again without needing access to the `pc` repo from the Live USB.

7. Rebuild:

   ```bash
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

8. Exit and reboot:

   ```bash
   exit
   sudo reboot
   ```

9. Boot once with Secure Boot still disabled.
10. After the machine boots normally, update the host to the latest `pc` input, re-enable `midgard.pc.security.secureboot.enable = true;`, rebuild, and test again before enabling Secure Boot in BIOS.

## References

- [Lanzaboote repository](https://github.com/nix-community/lanzaboote)
- [NixOS Wiki: Lanzaboote](https://wiki.nixos.org/wiki/Lanzaboote)
