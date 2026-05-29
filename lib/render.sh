#!/usr/bin/env bash
# Template substitution helpers for altmount config + compose files.

render::config() {
  # Args: tmpl_path, providers_block, radarr_block, sonarr_block, webdav_password
  local tmpl=$1 providers=$2 radarr=$3 sonarr=$4 password=$5
  [[ -f "$tmpl" ]] || { log::error "template missing: $tmpl"; return 1; }

  python3 - "$tmpl" "$providers" "$radarr" "$sonarr" "$password" <<'PY'
import sys
tmpl, providers, radarr, sonarr, password = sys.argv[1:6]
with open(tmpl) as f:
    text = f.read()
text = (text
    .replace('__PROVIDERS_BLOCK__', providers)
    .replace('__RADARR_INSTANCES__', radarr or '    []')
    .replace('__SONARR_INSTANCES__', sonarr or '    []')
    .replace('__WEBDAV_PASSWORD__', password))
sys.stdout.write(text)
PY
}
