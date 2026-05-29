#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/log.sh"
source "$SCRIPT_DIR/lib/preflight.sh"
source "$SCRIPT_DIR/lib/discover.sh"
source "$SCRIPT_DIR/lib/nzbdav.sh"
source "$SCRIPT_DIR/lib/render.sh"
source "$SCRIPT_DIR/lib/jwt.sh"
source "$SCRIPT_DIR/lib/deploy.sh"

NETWORK=""
CONFIG_DIR="/srv/config/altmount"
DATA_DIR="/srv/data/altmount"
MEDIA_DIR="/srv/media"
MOUNT_DIR="/mnt/altmount"
UID_OPT=1000
GID_OPT=1000
TZ_OPT="${TZ:-Etc/UTC}"
RESET=0
NO_START=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage: install.sh [flags]

Flags:
  --network NAME       Force Docker network (autodetected from nzbdav/Arr containers if omitted)
  --uid N              PUID for the altmount container (default: 1000)
  --gid N              PGID for the altmount container (default: 1000)
  --config-dir PATH    Host path for /config (default: /srv/config/altmount)
  --data-dir PATH      Host path for /data   (default: /srv/data/altmount)
  --media-dir PATH     Host path for /media  (default: /srv/media)
  --mount PATH         FUSE mount path (default: /mnt/altmount)
  --tz ZONE            TZ env var (default: $TZ or Etc/UTC)
  --reset              Wipe existing config.yaml before generating
  --no-start           Generate files but do not bring up the container
  --dry-run            Print what would happen; write nothing
  -h, --help           Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --network)    NETWORK=$2; shift 2 ;;
    --uid)        UID_OPT=$2; shift 2 ;;
    --gid)        GID_OPT=$2; shift 2 ;;
    --config-dir) CONFIG_DIR=$2; shift 2 ;;
    --data-dir)   DATA_DIR=$2; shift 2 ;;
    --media-dir)  MEDIA_DIR=$2; shift 2 ;;
    --mount)      MOUNT_DIR=$2; shift 2 ;;
    --tz)         TZ_OPT=$2; shift 2 ;;
    --reset)      RESET=1; shift ;;
    --no-start)   NO_START=1; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            log::error "unknown flag: $1"; usage; exit 2 ;;
  esac
done

main() {
  log::info "altmount-setup starting"

  # Dry-run: light preflight (no docker daemon check) and skip all docker discovery
  if (( DRY_RUN )); then
    local rc=0
    for cmd in jq sqlite3 python3 openssl; do
      preflight::check_command "$cmd" || rc=1
    done
    (( rc == 0 )) || log::die "pre-flight failed"

    local config_file="$CONFIG_DIR/config.yaml"
    log::info "DRY RUN -- would write $config_file and start container"
    log::info "providers imported: 0 (dry-run skips docker discovery)"
    log::info "radarr instances:  0 (dry-run skips docker discovery)"
    log::info "sonarr instances:  0 (dry-run skips docker discovery)"
    exit 0
  fi

  log::info "pre-flight checks..."
  preflight::run || log::die "pre-flight failed"

  if [[ -z "$NETWORK" ]]; then
    log::info "auto-detecting Docker network from nzbdav..."
    NETWORK=$(discover::network_for_containers nzbdav) \
      || log::die "could not find nzbdav container; pass --network NAME"
  fi
  log::info "using network: $NETWORK"

  local providers_yaml="providers: []"
  local nzbdav_cfg
  if nzbdav_cfg=$(discover::host_path_for_container_volume nzbdav /config 2>/dev/null); then
    if [[ -f "$nzbdav_cfg/db.sqlite" ]]; then
      log::info "importing providers from $nzbdav_cfg/db.sqlite"
      providers_yaml=$(nzbdav::import_providers "$nzbdav_cfg/db.sqlite") \
        || log::warn "provider import failed; leaving empty"
    else
      log::warn "nzbdav db.sqlite not found at $nzbdav_cfg/db.sqlite"
    fi
  else
    log::warn "nzbdav container not found; providers must be added in UI"
  fi

  local radarr_block="" sonarr_block=""
  for c in $(discover::containers_by_image_prefix 'linuxserver/radarr'); do
    local p; p=$(discover::host_path_for_container_volume "$c" /config) || continue
    [[ -f "$p/config.xml" ]] && radarr_block+="$(discover::arr_info "$p/config.xml" "$c")
"
  done
  for c in $(discover::containers_by_image_prefix 'linuxserver/sonarr'); do
    local p; p=$(discover::host_path_for_container_volume "$c" /config) || continue
    [[ -f "$p/config.xml" ]] && sonarr_block+="$(discover::arr_info "$p/config.xml" "$c")
"
  done

  local webdav_pw; webdav_pw=$(openssl rand -hex 8)

  local jwt_file="$CONFIG_DIR/jwt.secret"
  local config_file="$CONFIG_DIR/config.yaml"

  mkdir -p "$CONFIG_DIR"
  jwt::ensure "$jwt_file"
  local jwt; jwt=$(<"$jwt_file")

  if (( RESET )) && [[ -f "$config_file" ]]; then
    log::warn "--reset: removing existing $config_file"
    rm -f "$config_file"
  fi

  if [[ -f "$config_file" ]]; then
    log::info "config.yaml already exists; leaving it untouched (use --reset to regenerate)"
  else
    render::config "$SCRIPT_DIR/templates/config.yaml.tmpl" \
      "$providers_yaml" "$radarr_block" "$sonarr_block" "$webdav_pw" > "$config_file"
    chmod 600 "$config_file"
    log::info "wrote $config_file"
  fi

  local compose_path
  if [[ -f "$HOME/.config/cosmos/api-key" ]]; then
    compose_path="$SCRIPT_DIR/cosmos-compose.json"
    render::compose_cosmos "$SCRIPT_DIR/templates/cosmos-compose.json.tmpl" \
      "$NETWORK" "$CONFIG_DIR" "$DATA_DIR" "$MEDIA_DIR" "$MOUNT_DIR" \
      "$UID_OPT" "$GID_OPT" "$TZ_OPT" "$jwt" > "$compose_path"
    log::info "Cosmos detected -- wrote $compose_path (apply via Cosmos UI/API)"
  else
    compose_path="$SCRIPT_DIR/docker-compose.yml"
    render::compose_docker "$SCRIPT_DIR/templates/docker-compose.yml.tmpl" \
      "$NETWORK" "$CONFIG_DIR" "$DATA_DIR" "$MEDIA_DIR" "$MOUNT_DIR" \
      "$UID_OPT" "$GID_OPT" "$TZ_OPT" "$jwt" > "$compose_path"
    log::info "wrote $compose_path"
  fi

  deploy::prep_dirs "$MOUNT_DIR" "$CONFIG_DIR" "$DATA_DIR" "$UID_OPT" "$GID_OPT"

  if (( NO_START )); then
    log::info "--no-start: skipping bring-up"
    exit 0
  fi

  if [[ -f "$HOME/.config/cosmos/api-key" ]]; then
    log::warn "Cosmos host: apply $compose_path via Cosmos market/API, then re-run with --no-start verified"
  else
    deploy::compose_up "$compose_path"
    deploy::wait_health "http://localhost:8080/health" \
      || { deploy::dump_logs_on_fail; log::die "altmount did not become healthy"; }
  fi

  cat <<DONE

altmount is up.
   UI:          http://$(hostname -I | awk '{print $1}'):8080
   WebDAV:      usenet / $webdav_pw   (change this in UI -> WebDAV)
   FUSE mount:  $MOUNT_DIR
   Config:      $config_file
DONE
}

main "$@"
