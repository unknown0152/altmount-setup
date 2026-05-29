#!/usr/bin/env bash
# Import Usenet providers from an nzbdav SQLite db.
# Public: nzbdav::import_providers <db-path> → YAML on stdout.

nzbdav::import_providers() {
  local db=$1
  [[ -f "$db" ]] || { log::error "nzbdav db not found: $db"; return 1; }

  # nzbdav stores providers as a single JSON blob at key 'usenet.providers'
  local json
  json=$(sqlite3 "$db" \
    "SELECT ConfigValue FROM ConfigItems
     WHERE ConfigName = 'usenet.providers';" 2>/dev/null) || return 1

  if [[ -z "$json" ]]; then
    printf 'providers: []\n'
    return 0
  fi

  python3 - "$json" <<'PY'
import sys, json as _json

raw = sys.argv[1]
try:
    data = _json.loads(raw)
    providers = data.get('Providers', [])
except Exception:
    print('providers: []')
    sys.exit(0)

print('providers:')
for p in providers:
    host = p.get('Host', '')
    port = p.get('Port', 119)
    user = p.get('User', '')
    pw   = p.get('Pass', '')
    conn = p.get('MaxConnections', 20)
    ssl  = bool(p.get('UseSsl', False))
    print(f'  - id: ""')
    print(f'    host: {host}')
    print(f'    port: {port}')
    print(f'    username: {user}')
    print(f'    password: {pw}')
    print(f'    max_connections: {conn}')
    print(f'    tls: {"true" if ssl else "false"}')
    print(f'    enabled: true')
PY
}
