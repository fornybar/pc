# Secure Boot Setup with Lanzaboote

Guide for enabling Secure Boot on NixOS hosts using lanzaboote.

## Prerequisites

- NixOS installed in UEFI mode
- systemd-boot as the current bootloader
- LUKS full disk encryption (recommended alongside Secure Boot)
- Backup or familiarity with recovery tools (Live USB)

## Supported Hardware

Tested and confirmed working on Lenovo ThinkPads and Framework notebooks.

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

All entries should show as signed. If any are unsigned, investigate before proceeding.

### 5. Reboot and check

Reboot and verify lanzaboote is working:

```bash
bootctl status
```

At this point, Secure Boot is still in setup mode (not enforcing).

### 6. Enable Secure Boot in UEFI

1. Reboot into UEFI firmware settings (`systemctl reboot --firmware-setup`)
2. Navigate to Security > Secure Boot
3. Reset Secure Boot to Setup Mode (clear existing keys)
4. Save and exit
5. Boot into NixOS — sbctl will auto-enroll keys on first boot
6. Reboot into UEFI again
7. Enable Secure Boot enforcement
8. Save and boot

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
