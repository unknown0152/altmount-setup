#!/usr/bin/env bash
# Mount prep, container bring-up, health polling.

: "${DEPLOY_HEALTH_TIMEOUT:=60}"
: "${DEPLOY_HEALTH_INTERVAL:=2}"

deploy::prep_dirs() {
  # Args: mount_dir, config_dir, data_dir, uid, gid
  local mnt=$1 cfg=$2 dat=$3 uid=$4 gid=$5
  mkdir -p "$mnt" "$cfg" "$dat" || return 1
  if [[ "$(id -u)" == "0" ]]; then
    chown "$uid:$gid" "$mnt" "$cfg" "$dat" || return 1
  fi
}

deploy::compose_up() {
  # Args: compose_yml_path
  local f=$1
  docker compose -f "$f" up -d
}

deploy::wait_health() {
  # Args: url
  local url=$1 deadline=$((SECONDS + DEPLOY_HEALTH_TIMEOUT))
  while (( SECONDS < deadline )); do
    if curl -s -o /dev/null -w '%{http_code}' "$url" | grep -q '^200$'; then
      return 0
    fi
    sleep "$DEPLOY_HEALTH_INTERVAL"
  done
  log::error "health check did not pass within ${DEPLOY_HEALTH_TIMEOUT}s"
  return 1
}

deploy::dump_logs_on_fail() {
  log::warn "altmount failed to come up — recent logs:"
  docker logs --tail 100 altmount 2>&1 | sed 's/^/    /' >&2 || true
}
