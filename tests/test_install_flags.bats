#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/install.sh"
}

@test "install.sh --help shows usage" {
  run "$SCRIPT" --help
  assert_success
  assert_output --partial "Usage: install.sh"
  assert_output --partial "--network"
  assert_output --partial "--reset"
  assert_output --partial "--dry-run"
}

@test "install.sh --dry-run does not call docker" {
  docker() { echo "DOCKER_CALLED" >&2; return 1; }
  export -f docker
  run "$SCRIPT" --dry-run
  refute_output --partial "DOCKER_CALLED"
}

@test "install.sh rejects unknown flag" {
  run "$SCRIPT" --not-a-real-flag
  assert_failure
  assert_output --partial "unknown flag"
}
