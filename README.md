# altmount-setup

One-line installer for [altmount](https://github.com/javi11/altmount) on any
Docker host running [nzbdav](https://github.com/nzbdav-dev/nzbdav) +
Radarr/Sonarr.

```bash
curl -fsSL https://raw.githubusercontent.com/unknown0152/altmount-setup/main/install.sh | bash
```

## What it does

1. Verifies dependencies (`docker`, `jq`, `sqlite3`, `python3`, `openssl`, `/dev/fuse`)
2. Auto-detects the Docker network shared by `nzbdav` + Radarr/Sonarr
3. Imports your Usenet providers from nzbdav's SQLite into altmount's YAML format
4. Reads Radarr/Sonarr API keys from each container's `config.xml`
5. Generates `/srv/config/altmount/config.yaml` with battle-tested defaults
6. Generates a JWT secret (kept across re-runs)
7. Writes a compose file (`cosmos-compose.json` if Cosmos detected, else `docker-compose.yml`)
8. Brings the container up and polls `/health`
9. Prints the random WebDAV password and next-step reminders

## Baked-in defaults

| Setting | Value | Why |
|---------|-------|-----|
| `streaming.failure_masking.threshold` | 3 | masks dead segments after 3 failed reads |
| `health.repair.interval_minutes` | 60 | self-heal dead posts hourly via Arrs |
| `health.repair.max_repair_retries` | 0 | unbounded with exponential_backoff |
| `streaming.max_size_gb` | 80 | segcache cap |
| `metadata.backup.enabled` | true | nightly SQLite snapshot |

## Flags

See `./install.sh --help` for the full list.

| Flag | Default | Effect |
|------|---------|--------|
| `--network NAME` | autodetected | Force Docker network |
| `--uid N` / `--gid N` | 1000 | Override PUID/PGID |
| `--config-dir PATH` | `/srv/config/altmount` | Override config location |
| `--data-dir PATH` | `/srv/data/altmount` | Override data location |
| `--media-dir PATH` | `/srv/media` | Library path mounted at /media |
| `--mount PATH` | `/mnt/altmount` | FUSE mount path |
| `--tz ZONE` | `$TZ` or `Etc/UTC` | Timezone |
| `--reset` | off | Wipe existing config.yaml before generating |
| `--no-start` | off | Generate files but don't start the container |
| `--dry-run` | off | Print actions only; write nothing |

## What it skips (YAGNI)

- Arr quality profiles / custom formats
- Plex / Jellyfin wiring
- rclone fallback config (altmount replaces rclone+nzbdav as FUSE)

## Uninstall

```bash
./uninstall.sh           # stop container only
./uninstall.sh --purge   # also wipe /srv/config/altmount + /srv/data/altmount
```

## Development

```bash
git clone --recurse-submodules https://github.com/unknown0152/altmount-setup
cd altmount-setup
./tests/bats/bin/bats tests/
```

## License

MIT
