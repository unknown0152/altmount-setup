#!/usr/bin/env bash
# Import Usenet providers from an nzbdav SQLite db.
# Public: nzbdav::import_providers <db-path> → YAML on stdout.

nzbdav::import_providers() {
  local db=$1
  [[ -f "$db" ]] || { log::error "nzbdav db not found: $db"; return 1; }

  local tsv
  tsv=$(sqlite3 -separator $'\t' "$db" \
    "SELECT ConfigName, ConfigValue FROM ConfigItems
     WHERE ConfigName LIKE 'usenet.providers.%';" 2>/dev/null) || return 1

  if [[ -z "$tsv" ]]; then
    printf 'providers: []\n'
    return 0
  fi

  python3 - "$tsv" <<'PY'
import sys, collections

raw = sys.argv[1]
providers = collections.defaultdict(dict)
for line in raw.splitlines():
    if not line.strip():
        continue
    key, _, val = line.partition('\t')
    parts = key.split('.')
    if len(parts) < 4 or parts[0] != 'usenet' or parts[1] != 'providers':
        continue
    idx, field = parts[2], parts[3]
    providers[idx][field] = val

print('providers:')
for idx in sorted(providers, key=lambda x: int(x) if x.isdigit() else x):
    p = providers[idx]
    host = p.get('host', '')
    port = p.get('port', '119')
    user = p.get('user', '')
    pw   = p.get('pass', '')
    conn = p.get('conn', '20')
    ssl  = p.get('ssl', 'false').lower() in ('1','true','yes')
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
