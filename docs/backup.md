# Developer PC Backup & Restore

Back up and restore developer PC state to Azure Blob Storage using `rclone`. Each developer's backup is isolated to their own directory via ADLS Gen2 ACLs — only the user who created the backup (and admins) can access it.

## Prerequisites

- Azure CLI installed and authenticated: `az login`
- Your Entra ID account must be in the `yggdrasil-developers` or `yggdrasil-admins` group

## What gets backed up

| Category | Paths | Notes |
|---|---|---|
| Home directory | `~/` (entire home) | Excludes caches, build artifacts, docker volumes, `.git/objects/`, disk images, LLM models |
| SOPS age keys | `/root/.config/sops/` | Elevated via sudo; critical for secret decryption |
| System state | `/etc/machine-id`, `/etc/nixos/` | Machine identity and NixOS config |
| Secure Boot | `/var/lib/sbctl/` | Only if Secure Boot is enabled; elevated via sudo |
| Browser profiles | Firefox, Chrome, Chromium, Edge | Excluded by default — prompted interactively with size estimate |

## Running a backup

From this repo:

```bash
nix run .#backup
```

Or with options:

```bash
nix run .#backup -- --dry-run            # preview without transferring
nix run .#backup -- --include-browser    # skip the interactive browser prompt
nix run .#backup -- --verbose            # show detailed output for each step
```

## Restoring from backup

```bash
nix run .#restore
```

Or with options:

```bash
nix run .#restore -- --list                          # list available backups
nix run .#restore -- --dry-run                       # preview full restore
nix run .#restore -- sops                            # restore only SOPS keys
nix run .#restore -- home sops                       # restore home and SOPS keys
nix run .#restore -- --from-host old-pc home         # restore home from a different machine
nix run .#restore -- --from-user alice --from-host x # restore from another user's backup (admins only)
```

Available categories: `home`, `sops`, `system`. If none specified, all are restored.

Restore uses `rclone copy` (additive) — it only adds or updates files, never deletes local files that aren't in the backup.

## Where backups are stored

Backups are synced to the `devpcs5111c8c6` Azure storage account (dev subscription) in the `developer-pcs` container:

```
developer-pcs/
  <username>/
    <hostname>/
      home/
      sops/
      system/
        etc/
        nixos/
        sbctl/
```

Each backup run uses `rclone sync`, so the destination always reflects the current state of the machine.

## Access control

The storage account uses ADLS Gen2 (hierarchical namespace). No RBAC data-plane roles are assigned to developers — access is controlled entirely via ACLs:

- The container root ACL grants `rwx` to both the developers and admins groups (set in Terraform)
- On first backup, the script creates `<username>/<hostname>/` directories and sets ACLs to only allow the current user's Entra ID identity
- Admins inherit `rwx` via the default ACL on the container root

This means developers can create their own backup directories but cannot read other developers' backups.

## Infrastructure

The storage account and ACL configuration are defined in [yggdrasil](https://github.com/fornybar/yggdrasil) at `ginnungagap/devpcs.dev.tf.nix` (dev-only).
