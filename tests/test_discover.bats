#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/log.sh"
  source "$SCRIPT_DIR/lib/discover.sh"
}

@test "discover::network_for_containers prefers non-bridge network" {
  docker() { echo '{"NetworkSettings":{"Networks":{"bridge":{},"media-stack":{}}}}'; }
  export -f docker
  run discover::network_for_containers nzbdav
  assert_success
  assert_output "media-stack"
}

@test "discover::network_for_containers fails when container missing" {
  docker() { return 1; }
  export -f docker
  run discover::network_for_containers nzbdav
  assert_failure
}

@test "discover::host_path_for_container_volume returns bind source" {
  docker() {
    cat <<'JSON'
[{"Mounts":[{"Type":"bind","Source":"/srv/config/nzbdav","Destination":"/config"}]}]
JSON
  }
  export -f docker
  run discover::host_path_for_container_volume nzbdav /config
  assert_success
  assert_output "/srv/config/nzbdav"
}
