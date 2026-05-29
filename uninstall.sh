#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/log.sh"

CONFIG_DIR="/srv/config/altmount"
DATA_DIR="/srv/data/altmount"
PURGE=0

usage() {
  cat <<'USAGE'
Usage: uninstall.sh [flags]

Flags:
  --config-dir PATH   Config directory to remove on --purge (default: /srv/config/altmount)
  --data-dir PATH     Data directory to remove on --purge   (default: /srv/data/altmount)
  --purge             Also delete config + data on disk (destructive)
  -h, --help          Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config-dir) CONFIG_DIR=$2; shift 2 ;;
    --data-dir)   DATA_DIR=$2;   shift 2 ;;
    --purge)      PURGE=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            log::error "unknown flag: $1"; usage; exit 2 ;;
  esac
done

log::info "stopping altmount container..."
docker rm -f altmount 2>/dev/null || log::warn "container not running"

if (( PURGE )); then
  log::warn "purging $CONFIG_DIR and $DATA_DIR"
  rm -rf "$CONFIG_DIR" "$DATA_DIR"
fi

log::info "done"
