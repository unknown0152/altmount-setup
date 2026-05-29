#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/uninstall.sh"
}

@test "uninstall.sh --help shows usage" {
  run "$SCRIPT" --help
  assert_success
  assert_output --partial "Usage: uninstall.sh"
  assert_output --partial "--purge"
}

@test "uninstall.sh refuses unknown flag" {
  run "$SCRIPT" --not-real
  assert_failure
}
