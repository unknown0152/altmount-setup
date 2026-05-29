#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/log.sh"
  source "$SCRIPT_DIR/lib/preflight.sh"
}

@test "preflight::check_command succeeds when command exists" {
  run preflight::check_command bash
  assert_success
}

@test "preflight::check_command fails when command is missing" {
  run preflight::check_command this-command-does-not-exist
  assert_failure
  assert_output --partial "missing required command: this-command-does-not-exist"
}

@test "preflight::check_fuse fails when /dev/fuse is absent" {
  FUSE_DEVICE=/tmp/__no_such_fuse__ run preflight::check_fuse
  assert_failure
  assert_output --partial "FUSE device not found"
}

@test "preflight::run aggregates all checks" {
  run preflight::run
  [[ "$status" -eq 0 || "$output" == *"missing"* || "$output" == *"FUSE"* ]]
}
