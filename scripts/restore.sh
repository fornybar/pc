STORAGE_ACCOUNT="devpcs5111c8c6"
CONTAINER="developer-pcs"
REMOTE=":azureblob,account=${STORAGE_ACCOUNT},env_auth:"

usage() {
  echo "Usage: $(basename "$0") [--dry-run] [--verbose] [--from-user USER] [--from-host HOST] [CATEGORY...]"
  echo ""
  echo "Restore developer PC state from Azure Blob Storage."
  echo "Requires: az login (Azure CLI authentication)"
  echo ""
  echo "Categories (default: all):"
  echo "  home       Home directory config and files"
  echo "  sops       SOPS age keys (/root/.config/sops)"
  echo "  system     System state (machine-id, /etc/nixos, sbctl)"
  echo ""
  echo "Options:"
  echo "  --dry-run              Show what would be restored without doing it"
  echo "  --verbose              Show detailed output for each step"
  echo "  --from-user USER       Restore from a different user's backup (default: current user)"
  echo "  --from-host HOST       Restore from a different hostname (default: current hostname)"
  echo "  --list                 List available backups and exit"
  echo "  -h, --help             Show this help"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") --dry-run                    # preview full restore"
  echo "  $(basename "$0") sops                         # restore only SOPS keys"
  echo "  $(basename "$0") --from-host old-pc home      # restore home from old machine"
  exit 0
}

DRY_RUN=""
VERBOSE=""
FROM_USER="$(whoami)"
FROM_HOST="$(hostname)"
LIST_ONLY=""
CATEGORIES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN="--dry-run"; shift ;;
    --verbose) VERBOSE=1; shift ;;
    --from-user) FROM_USER="$2"; shift 2 ;;
    --from-host) FROM_HOST="$2"; shift 2 ;;
    --list) LIST_ONLY=1; shift ;;
    -h|--help) usage ;;
    home|sops|system) CATEGORIES+=("$1"); shift ;;
    *) echo "Unknown option or category: $1"; usage ;;
  esac
done

if [[ ${#CATEGORIES[@]} -eq 0 ]]; then
  CATEGORIES=(home sops system)
fi

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

SRC_PATH="${FROM_USER}/${FROM_HOST}"
SRC="${REMOTE}${CONTAINER}/${SRC_PATH}"

if [[ -n "$LIST_ONLY" ]]; then
  echo "Available backups:"
  rclone lsd "${REMOTE}${CONTAINER}/" 2>/dev/null | awk '{print $NF}' | while read -r user; do
    rclone lsd "${REMOTE}${CONTAINER}/${user}/" 2>/dev/null | awk '{print $NF}' | while read -r host; do
      echo "  ${user}/${host}"
    done
  done
  exit 0
fi

echo "Restoring from: ${STORAGE_ACCOUNT}/${CONTAINER}/${SRC_PATH}/"
[[ -n "$DRY_RUN" ]] && echo "(DRY RUN)"

# Verify the source exists
if ! rclone lsd "${SRC}/" &>/dev/null; then
  echo "Error: backup not found at ${SRC_PATH}/"
  echo "Run with --list to see available backups."
  exit 1
fi

for cat in "${CATEGORIES[@]}"; do
  case "$cat" in
    home)
      echo ""
      echo "==> Restoring home directory"
      rclone copy \
        $DRY_RUN \
        --progress \
        "${SRC}/home/" "$HOME/"
      ;;
    sops)
      echo ""
      echo "==> Restoring SOPS age keys"
      sops_tmp="$(mktemp -d)"
      trap '/run/wrappers/bin/sudo rm -rf "$sops_tmp"' EXIT
      rclone copy \
        $DRY_RUN \
        --progress \
        "${SRC}/sops/" "$sops_tmp/"
      if [[ -z "$DRY_RUN" ]]; then
        /run/wrappers/bin/sudo mkdir -p /root/.config/sops
        /run/wrappers/bin/sudo cp -a "$sops_tmp/." /root/.config/sops/
        echo "  Restored to /root/.config/sops/"
      fi
      ;;
    system)
      echo ""
      echo "==> Restoring system state"
      if rclone lsd "${SRC}/system/nixos/" &>/dev/null; then
        echo "  /etc/nixos/"
        /run/wrappers/bin/sudo rclone copy \
          $DRY_RUN \
          --progress \
          "${SRC}/system/nixos/" /etc/nixos/ 2>/dev/null || \
          rclone copy $DRY_RUN --progress "${SRC}/system/nixos/" /tmp/restore-nixos/ && \
          echo "  (copied to /tmp/restore-nixos/ — move to /etc/nixos/ manually)"
      fi
      if rclone lsd "${SRC}/system/sbctl/" &>/dev/null; then
        echo "  /var/lib/sbctl/"
        sbctl_tmp="$(mktemp -d)"
        rclone copy \
          $DRY_RUN \
          --progress \
          "${SRC}/system/sbctl/" "$sbctl_tmp/"
        if [[ -z "$DRY_RUN" ]]; then
          /run/wrappers/bin/sudo mkdir -p /var/lib/sbctl
          /run/wrappers/bin/sudo cp -a "$sbctl_tmp/." /var/lib/sbctl/
          /run/wrappers/bin/sudo rm -rf "$sbctl_tmp"
          echo "  Restored to /var/lib/sbctl/"
        fi
      fi
      ;;
  esac
done

echo ""
echo "Restore complete."
