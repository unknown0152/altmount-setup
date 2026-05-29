#!/usr/bin/env bash
# Pre-flight host checks. Public: preflight::run

: "${FUSE_DEVICE:=/dev/fuse}"

preflight::check_command() {
  local cmd=$1
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log::error "missing required command: $cmd"
    return 1
  fi
  return 0
}

preflight::check_fuse() {
  if [[ ! -c "$FUSE_DEVICE" && ! -e "$FUSE_DEVICE" ]]; then
    log::error "FUSE device not found at $FUSE_DEVICE — install fuse3 or load the kernel module"
    return 1
  fi
  return 0
}

preflight::check_docker_usable() {
  if ! docker info >/dev/null 2>&1; then
    log::error "cannot talk to Docker daemon — is the current user in the docker group?"
    return 1
  fi
  return 0
}

preflight::run() {
  local rc=0
  for cmd in docker jq sqlite3 python3 openssl; do
    preflight::check_command "$cmd" || rc=1
  done
  preflight::check_fuse || rc=1
  preflight::check_docker_usable || rc=1
  return $rc
}
