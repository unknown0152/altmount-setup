#!/usr/bin/env bash
# Docker network and container discovery helpers.

discover::network_for_containers() {
  # Args: one or more container names. Echoes a single network name shared by them all,
  # preferring non-bridge. Returns 1 if none found.
  local containers=("$@")
  local nets json
  json=$(docker inspect "${containers[0]}" 2>/dev/null) || return 1
  mapfile -t nets < <(printf '%s' "$json" \
    | jq -r '.[0].NetworkSettings.Networks // {} | keys[]' 2>/dev/null \
    || printf '%s' "$json" | jq -r '.NetworkSettings.Networks // {} | keys[]')
  if [[ ${#nets[@]} -eq 0 ]]; then
    return 1
  fi
  local pick=""
  for n in "${nets[@]}"; do
    if [[ "$n" != "bridge" ]]; then
      pick="$n"
      break
    fi
  done
  pick="${pick:-${nets[0]}}"
  printf '%s\n' "$pick"
}

discover::host_path_for_container_volume() {
  # Args: container_name, container_path. Echoes host-side bind source. Returns 1 if none.
  local container=$1 cpath=$2
  docker inspect "$container" 2>/dev/null \
    | jq -er --arg p "$cpath" '
        (if type=="array" then .[0] else . end).Mounts[]
        | select(.Type=="bind" and .Destination==$p)
        | .Source' \
    | head -n1
}

discover::containers_by_image_prefix() {
  # Args: image_substring (e.g. "linuxserver/radarr"). Echoes one container name per line.
  local needle=$1
  docker ps --format '{{.Names}} {{.Image}}' \
    | awk -v n="$needle" '$2 ~ n { print $1 }'
}

discover::arr_info() {
  # Args: <config.xml path>, <container_name>
  # Echoes 4 indented YAML lines: name/url/api_key/category
  local xml=$1 name=$2
  [[ -f "$xml" ]] || { log::error "config.xml not found: $xml"; return 1; }

  local port apikey
  port=$(python3 -c "
import sys, xml.etree.ElementTree as ET
print(ET.parse(sys.argv[1]).getroot().findtext('Port') or '')
" "$xml") || return 1
  apikey=$(python3 -c "
import sys, xml.etree.ElementTree as ET
print(ET.parse(sys.argv[1]).getroot().findtext('ApiKey') or '')
" "$xml") || return 1

  cat <<YAML
    - name: $name
      url: http://$name:$port
      api_key: $apikey
      category: ""
YAML
}
