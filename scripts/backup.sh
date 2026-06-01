STORAGE_ACCOUNT="devpcs5111c8c6"
CONTAINER="developer-pcs"
HOSTNAME="$(hostname)"
REMOTE=":azureblob,account=${STORAGE_ACCOUNT},env_auth:"

usage() {
  echo "Usage: $(basename "$0") [--dry-run] [--include-browser] [--verbose]"
  echo ""
  echo "Backup developer PC state to Azure Blob Storage."
  echo "Requires: az login (Azure CLI authentication)"
  echo ""
  echo "Options:"
  echo "  --dry-run           Show what would be transferred without doing it"
  echo "  --include-browser   Include browser profiles (can be large)"
  echo "  --verbose           Show detailed output for each step"
  echo "  -h, --help          Show this help"
  exit 0
}

DRY_RUN=""
INCLUDE_BROWSER=""
VERBOSE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN="--dry-run"; shift ;;
    --include-browser) INCLUDE_BROWSER=1; shift ;;
    --verbose) VERBOSE=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

log() {
  if [[ -n "$VERBOSE" ]]; then
    echo "  $1"
  fi
}

log "Checking Azure CLI authentication..."
if ! az account show &>/dev/null; then
  echo "Error: not logged in to Azure CLI. Run 'az login' first."
  exit 1
fi
log "Authenticated to subscription: $(az account show --query name -o tsv)"

USERNAME="$(whoami)"
DEST_PATH="${USERNAME}/${HOSTNAME}"
DEST="${REMOTE}${CONTAINER}/${DEST_PATH}"

# Set up per-user ACL on first run only — default ACL propagates to children
echo "==> Ensuring directory ACL for ${DEST_PATH}/"
if az storage fs directory show \
  --file-system "$CONTAINER" \
  --name "$USERNAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login &>/dev/null; then
  log "Directory ${USERNAME}/ already exists, skipping ACL setup"
else
  log "First run — creating directories and setting ACLs"
  log "Fetching Entra ID object ID..."
  USER_OID="$(az ad signed-in-user show --query id -o tsv)"
  log "Object ID: ${USER_OID}"

  log "Creating directory ${USERNAME}/..."
  az storage fs directory create \
    --file-system "$CONTAINER" \
    --name "$USERNAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login

  log "Setting ACL on ${USERNAME}/ (default ACL propagates to subdirectories)..."
  az storage fs access set \
    --acl "user:${USER_OID}:rwx,default:user:${USER_OID}:rwx" \
    --path "$USERNAME" \
    --file-system "$CONTAINER" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login

  log "Creating directory ${DEST_PATH}/..."
  az storage fs directory create \
    --file-system "$CONTAINER" \
    --name "$DEST_PATH" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login
fi

HOME_DIR="$HOME"

home_excludes() {
  cat <<'EXCLUDES'
- .cache/**
- .nix-defexpr/**
- .nix-profile/**
- .local/state/**
- .local/share/Trash/**
- .local/share/docker/**
- .local/share/uv/**
- .local/share/nvim/**
- .local/share/pnpm/**
- .local/share/opencode/**
- .git/objects/**
- .direnv/**
- node_modules/**
- .npm/**
- .bun/install/**
- .cargo/registry/**
- .cargo/git/**
- .rustup/toolchains/**
- .rustup/tmp/**
- target/**
- __pycache__/**
- .venv/**
- .local/share/pip/**
- .local/share/virtualenvs/**
- .cache/pip/**
- go/pkg/**
- .go/pkg/**
- .cache/go-build/**
- .gradle/**
- .m2/repository/**
- .nuget/**
- .kube/cache/**
- .mozilla/firefox/*/cache2/**
- .mozilla/firefox/*/startupCache/**
- .config/google-chrome/**/Cache/**
- .config/google-chrome/**/Service Worker/**
- .config/google-chrome/**/Code Cache/**
- .config/google-chrome/**/GPUCache/**
- .config/google-chrome/**/GrShaderCache/**
- .config/chromium/**/Cache/**
- .config/chromium/**/Service Worker/**
- .config/chromium/**/Code Cache/**
- .config/chromium/**/GPUCache/**
- .config/chromium/**/GrShaderCache/**
- .config/microsoft-edge/**/Cache/**
- .config/microsoft-edge/**/Service Worker/**
- .config/microsoft-edge/**/Code Cache/**
- .config/microsoft-edge/**/GPUCache/**
- .config/microsoft-edge/**/GrShaderCache/**
- .config/obsidian/Cache/**
- .config/Slack/Cache/**
- .config/Slack/Code Cache/**
- .config/Slack/GPUCache/**
- .config/Slack/Service Worker/**
- .claude/file-history/**
- .claude/plugins/cache/**
- .amp/**
- .fopencode/**
- .codex-personal/**
- .copilot/**
- .gemini/**
- .docker/buildx/**
- **/docker/volumes/**
- **/docker-compose/**/data/**
- .duckdb/extensions/**
- .bun/bin/**
- .claude/plugins/marketplaces/**
- docker-data/**
- result
- *.qcow2
- *.iso
- *.img
- *.gguf
EXCLUDES
}

browser_dirs=(
  ".mozilla/firefox"
  ".config/google-chrome"
  ".config/chromium"
  ".config/microsoft-edge"
)

has_browser=0
browser_size=0
for bdir in "${browser_dirs[@]}"; do
  if [[ -d "$HOME_DIR/$bdir" ]]; then
    has_browser=1
    size=$(du -sb "$HOME_DIR/$bdir" 2>/dev/null | cut -f1)
    browser_size=$((browser_size + size))
  fi
done

if [[ -z "$INCLUDE_BROWSER" && "$has_browser" -eq 1 ]]; then
  browser_mb=$((browser_size / 1024 / 1024))
  echo ""
  echo "Browser profiles found (~${browser_mb} MB before cache exclusions)."
  read -rp "Include browser profiles in backup? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    INCLUDE_BROWSER=1
  fi
fi

browser_exclude=""
if [[ -z "$INCLUDE_BROWSER" ]]; then
  browser_exclude="- .mozilla/**
- .config/google-chrome/**
- .config/chromium/**
- .config/microsoft-edge/**"
fi

echo ""
echo "Backing up to: ${STORAGE_ACCOUNT}/${CONTAINER}/${DEST_PATH}/"
[[ -n "$DRY_RUN" ]] && echo "(DRY RUN)"
echo ""

echo "==> Home directory"
rclone sync \
  --filter-from <(home_excludes; echo "$browser_exclude") \
  --ignore-errors \
  --retries 1 \
  $DRY_RUN \
  --progress \
  "$HOME_DIR" "${DEST}/home/" || echo "  (completed with some permission errors — skipped unreadable paths)"

echo ""
echo "==> SOPS age keys"
sops_dir="/root/.config/sops"
sops_tmp="$(mktemp -d)"
trap '/run/wrappers/bin/sudo rm -rf "$sops_tmp"' EXIT
if /run/wrappers/bin/sudo cp -a "$sops_dir/." "$sops_tmp/" 2>/dev/null; then
  rclone sync \
    $DRY_RUN \
    --progress \
    "$sops_tmp" "${DEST}/sops/"
else
  echo "  (skipped — could not read $sops_dir, run with sudo access)"
fi

echo ""
echo "==> System state"
rclone sync \
  --include "/etc/machine-id" \
  $DRY_RUN \
  --progress \
  /etc "${DEST}/system/etc/"

if [[ -d /etc/nixos ]]; then
  rclone sync \
    $DRY_RUN \
    --progress \
    /etc/nixos "${DEST}/system/nixos/"
fi

if [[ -d /var/lib/sbctl ]]; then
  sbctl_tmp="$(mktemp -d)"
  trap '/run/wrappers/bin/sudo rm -rf "$sops_tmp" "$sbctl_tmp"' EXIT
  if /run/wrappers/bin/sudo cp -a /var/lib/sbctl/. "$sbctl_tmp/" 2>/dev/null; then
    rclone sync \
      $DRY_RUN \
      --progress \
      "$sbctl_tmp" "${DEST}/system/sbctl/"
  else
    echo "  (skipped — could not read /var/lib/sbctl, run with sudo access)"
  fi
fi

echo ""
echo "Backup complete."
