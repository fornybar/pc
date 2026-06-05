# Secure Boot Setup with Lanzaboote

Guide for enabling Secure Boot on NixOS hosts using lanzaboote.

## Prerequisites

- NixOS installed in UEFI mode
- systemd-boot as the current bootloader
- LUKS full disk encryption (recommended alongside Secure Boot)
- Backup or familiarity with recovery tools (Live USB)

## Supported Hardware

Tested and confirmed working on Lenovo ThinkPads and Framework notebooks.
HP ZBook hardware has been tested — see HP-specific notes in steps 4 and 6.

## Module

The `modules/security/secureboot.nix` module wraps lanzaboote with standard module options:

```nix
midgard.pc.security.secureboot.enable = true;
# Optional: override PKI bundle path (default: /var/lib/sbctl)
# midgard.pc.security.secureboot.pkiBundle = "/var/lib/sbctl";
```

The module is not included in the default imports — add `./modules/security` to your host
imports or ensure the `default` nixosModule is used and enable it explicitly.

## Step-by-Step

### 1. Import the module in the host config

```nix
imports = [
  # ...existing imports...
  ../../modules/security
];
```

### 2. Generate Secure Boot signing keys

Before enabling the module, create the keys on the target machine:

```bash
sudo sbctl create-keys
```

This creates keys in `/var/lib/sbctl/`. Verify:

```bash
sudo sbctl status
```

### 3. Enable the module

```nix
midgard.pc.security.secureboot.enable = true;
```

Rebuild:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

### 4. Verify signing

After rebuild, check that all boot files are signed:

```bash
sudo sbctl verify
```

Lanzaboote signs the files it manages (its stub, kernel, initrd), but not all EFI binaries.
Any entries still showing as unsigned must be signed manually:

```bash
sudo sbctl sign -s /boot/efi/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/efi/EFI/systemd/systemd-bootx64.efi
```

The `-s` flag saves the path to sbctl's database so it is re-signed automatically on future rebuilds.
Run `sbctl verify` again and confirm all entries are signed before continuing.

> **Do not rebuild after this point.** Lanzaboote bakes a hash of the kernel and initrd into
> each signed stub at build time. A rebuild after signing regenerates the stubs with new hashes,
> making the previously signed stubs stale. Booting a stale stub panics with
> "Failed to extract configuration from binary" at startup. If this happens, disable Secure Boot,
> rebuild once, re-sign stragglers, then proceed to key enrollment.

### 5. Reboot and check

Reboot and verify lanzaboote is working:

```bash
bootctl status
```

At this point, Secure Boot is still in setup mode (not enforcing).

### 6. Enable Secure Boot in UEFI

All files must be signed (step 4) before proceeding.

1. Reboot into UEFI firmware settings (`systemctl reboot --firmware-setup`)
2. Navigate to **Security → Secure Boot Configuration**
3. **Clear the Secure Boot key database** — this puts the firmware into Setup Mode.
   This is a separate action from disabling Secure Boot; look for options like:
   - *Reset Secure Boot Keys to Factory Defaults*
   - *Clear All Secure Boot Keys*
   - *Delete All Secure Boot Keys*

   On HP ZBook: enter BIOS with **F10**, then:
   1. **HP Sure Start** → disable *Sure Start Key Protection* (requires an admin password to be set)
   2. This unlocks Secure Boot key management — you can now clear keys, enable MS UEFI keys, etc.
   3. Navigate to **Security → Secure Boot Configuration** and clear the key database

   > Disabling Secure Boot is not the same as Setup Mode. `sbctl enroll-keys` will fail
   > with "Your system is not in Setup Mode" unless the key database has been cleared.
   > On HP ZBook, Sure Start Key Protection must be disabled first or the clear option is unavailable.

4. Save and exit
5. Boot into NixOS — sbctl auto-enrolls keys on this boot
6. Verify Setup Mode was active and keys enrolled: `sbctl status` should show `Secure Boot: disabled, Setup Mode: disabled`
7. Reboot into UEFI again
8. Enable Secure Boot enforcement
9. Save and boot

### 7. Confirm Secure Boot is active

```bash
bootctl status
# Should show: Secure Boot: enabled (user)

sbctl status
# Should show: Secure Boot: enabled
```

## Recovery

If the system fails to boot after enabling Secure Boot:

1. Enter UEFI firmware settings
2. Disable Secure Boot
3. Boot normally
4. Debug with `sudo sbctl verify` and check for unsigned files
5. Re-enable Secure Boot once resolved

Alternatively, boot from a Live USB and mount the root filesystem to inspect/fix the configuration.

## Persisting Keys

The PKI bundle at `/var/lib/sbctl` must persist across rebuilds. On standard NixOS installs
(non-impermanence), this directory persists by default. If using impermanence, add
`/var/lib/sbctl` to your persistent directories.

## References

- [lanzaboote repository](https://github.com/nix-community/lanzaboote)
- [NixOS Wiki: Lanzaboote](https://wiki.nixos.org/wiki/Lanzaboote)
