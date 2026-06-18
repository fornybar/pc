#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash git gh jq sbctl

set -e

# Setup git with github

## Put config in tmp dir to avoid potential conflict with home-manager
setup_config_dir="$PWD/.setup-config"
mkdir -p "$setup_config_dir"
export GH_CONFIG_DIR="$setup_config_dir/gh-config"
export GIT_CONFIG_GLOBAL="$setup_config_dir/gitconfig"

if gh auth status >/dev/null 2>&1; then
    echo "Already logged into GitHub, skipping git setup"
else
    echo "Logging into GitHub and setting up git"
    gh auth login -s user
    gh auth setup-git

    user=$(gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /user | jq -r .login)
    email=$(gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /user/emails | jq -r '.[] | select(.primary == true) | .email')
    echo "Setting $user <$email> as the default Git user..."
    git config --global user.name "$user"
    git config --global user.email "$email"
fi


# Get personal pc config

personal_pc_repo_path="$PWD/personal_pc_repo"

if [ -d "$personal_pc_repo_path" ]; then
    echo "Personal pc repo already cloned, skipping cloning personal pc repo"
else
    read -rp "Enter organization/repo containing your pc config: " pc_repo_id
    gh repo clone "$pc_repo_id" "$personal_pc_repo_path"
fi

read -rp "Now copy /etc/nixos/hardware-configuration.nix into pc config, then press Enter to continue "
read -rp "Make sure you've included the hardware config in your nixos pc module, then press Enter to continue "

# Ensure root can actually decrypt the sops secrets before rebuilding

sops_age_key_file="/root/.config/sops/age/keys.txt"
secrets_file="$personal_pc_repo_path/secrets.yaml"
sops_bin=$(command -v sops)
if sudo env SOPS_AGE_KEY_FILE="$sops_age_key_file" "$sops_bin" decrypt "$secrets_file" >/dev/null 2>&1; then
    echo "Sops age is correctly set up"
else
    echo "ERROR: root could not decrypt $secrets_file"
    echo "Check that the age key at $sops_age_key_file exists and that its public"
    echo "key is listed as a recipient for $secrets_file (see .sops.yaml)."
    exit 1
fi

# Rebuild boot

echo "Building pc config and switching on boot"
read -rp "Enter name of nixosConfiguration in personal pc repo you want to use: " nixos_configuration_name


# Ensure sbctl is correctly set up

echo "Checking secureboot settings"
## Must be enabled for lanzaboote to sign boot files with new sbctl keys
secureboot_enabled=$(nix eval \
    "$personal_pc_repo_path#nixosConfigurations.$nixos_configuration_name.config.midgard.pc.security.secureboot.enable" \
    --option access-tokens "github.com=$(gh auth token)" 2>/dev/null) || secureboot_enabled="false"
if [ "$secureboot_enabled" != "true" ]; then
    echo "ERROR: midgard.pc.security.secureboot.enable is not true for $nixos_configuration_name"
    echo "Enable Secure Boot via lanzaboote in your personal pc config before continuing."
    exit 1
fi

## create-keys is idempotent: it's a no-op if keys already exist
sudo sbctl create-keys

## Verify that the locally created sbctl db key is actually enrolled in the EFI db.
## sbctl list-enrolled-keys lists from the EFI db, not /var/lib/sbctl/keys/db.
db_cert="/var/lib/sbctl/keys/db/db.pem"
local_db_cert=$(sudo sed -e '/-----/d' "$db_cert" | tr -d '\n')
if sudo sbctl list-enrolled-keys --json 2>/dev/null \
    | jq -e --arg cert "$local_db_cert" 'any(.DB[]?; .Raw == $cert)' >/dev/null; then
    echo "sbctl keys are enrolled"
    are_enrolled=1
else
    echo "WARNING: sbctl keys exist but are not enrolled in the EFI db."
    are_enrolled=0
fi

sudo nixos-rebuild boot --flake "$personal_pc_repo_path#$nixos_configuration_name" --option access-tokens "github.com=$(gh auth token)"

if [ "$are_enrolled" -eq 0 ]; then
    echo "WARNING: Must enroll sbctl keys. Reboot into Setup Mode and run"
    echo "  sudo sbctl enroll-keys --microsoft --firmware-builtins"
fi
