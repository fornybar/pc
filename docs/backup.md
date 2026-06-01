# Developer PC Backup

Back up developer PC state to Azure Blob Storage using `rclone`. Each developer's backup is isolated to their own directory via ADLS Gen2 ACLs — only the user who created the backup (and admins) can access it.

## Prerequisites

- Azure CLI installed and authenticated: `az login`
- Your Entra ID account must be in the `yggdrasil-developers` or `yggdrasil-admins` group

## What gets backed up

| Category | Paths | Notes |
|---|---|---|
| Home directory | `~/` (entire home) | Excludes caches, `node_modules`, `target/`, `.venv/`, `.git/objects/`, disk images, Nix store paths |
| SOPS age keys | `/root/.config/sops/` | Requires `sudo` |
| System state | `/etc/machine-id`, `/etc/nixos/` | Machine identity and NixOS config |
| Secure Boot | `/var/lib/sbctl/` | Only if Secure Boot is enabled; requires `sudo` |
| Browser profiles | `~/.mozilla/firefox/`, `~/.config/google-chrome/`, `~/.config/chromium/` | Excluded by default — prompted interactively with size estimate |

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

## Where backups are stored

Backups are synced to the `devpcs` Azure storage account in the `developer-pcs` container:

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

Each run uses `rclone sync`, so the destination always reflects the current state of the machine. Azure Blob versioning can be enabled on the storage account if historical snapshots are needed.

## Access control

The storage account uses ADLS Gen2 (hierarchical namespace). No RBAC data-plane roles are assigned to developers — access is controlled entirely via ACLs:

- The container root ACL grants `rwx` to both the developers and admins groups (set in Terraform)
- On first backup, the script creates `<username>/<hostname>/` directories and sets ACLs to only allow the current user's Entra ID identity
- Admins inherit `rwx` via the default ACL on the container root

This means developers can create their own backup directories but cannot read other developers' backups.

## Restoring from backup

To restore files from a backup, use `rclone copy` in the opposite direction:

```bash
# Set up auth (same as the backup script)
export RCLONE_AZUREBLOB_ACCOUNT="devpcs$(az account show --query 'id' -o tsv | cut -c1-8)"
export RCLONE_AZUREBLOB_ENV_AUTH="true"

# List what's in your backup
rclone ls "azureblob:developer-pcs/$(whoami)/$(hostname)/"

# Restore specific files
rclone copy "azureblob:developer-pcs/$(whoami)/$(hostname)/home/.ssh/" ~/.ssh/
rclone copy "azureblob:developer-pcs/$(whoami)/$(hostname)/sops/" /root/.config/sops/ --sudo
```

## Infrastructure

The storage account and ACL configuration are defined in [yggdrasil](https://github.com/fornybar/yggdrasil) at `ginnungagap/main.tf.nix`.
