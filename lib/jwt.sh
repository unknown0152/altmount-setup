#!/usr/bin/env bash
# JWT secret file: generate once, keep across re-runs.

jwt::ensure() {
  local path=$1
  if [[ -s "$path" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  openssl rand -hex 32 > "$path"
  chmod 600 "$path"
}
