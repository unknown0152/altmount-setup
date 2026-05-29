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

render::compose_docker() {
  # Args: tmpl, network, config_dir, data_dir, media_dir, mount_dir, uid, gid, tz, jwt
  local tmpl=$1 net=$2 cfg=$3 dat=$4 med=$5 mnt=$6 uid=$7 gid=$8 tz=$9 jwt=${10}
  [[ -f "$tmpl" ]] || { log::error "template missing: $tmpl"; return 1; }
  python3 - "$tmpl" "$net" "$cfg" "$dat" "$med" "$mnt" "$uid" "$gid" "$tz" "$jwt" <<'PY'
import sys
tmpl, net, cfg, dat, med, mnt, uid, gid, tz, jwt = sys.argv[1:11]
with open(tmpl) as f:
    text = f.read()
for k, v in [
    ('__NETWORK__', net), ('__CONFIG_DIR__', cfg), ('__DATA_DIR__', dat),
    ('__MEDIA_DIR__', med), ('__MOUNT_DIR__', mnt),
    ('__UID__', uid), ('__GID__', gid), ('__TZ__', tz), ('__JWT_SECRET__', jwt),
]:
    text = text.replace(k, v)
sys.stdout.write(text)
PY
}
