#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/log.sh"
  source "$SCRIPT_DIR/lib/deploy.sh"
  TMPDIR=$(mktemp -d)
}

teardown() { rm -rf "$TMPDIR"; }

@test "deploy::wait_health succeeds when endpoint returns 200" {
  curl() { echo "200"; }
  export -f curl
  DEPLOY_HEALTH_TIMEOUT=2 deploy::wait_health http://fake/health
}

@test "deploy::wait_health fails after timeout" {
  curl() { echo "503"; }
  export -f curl
  run bash -c 'source /root/dev/altmount-setup/lib/log.sh; source /root/dev/altmount-setup/lib/deploy.sh; DEPLOY_HEALTH_TIMEOUT=2 DEPLOY_HEALTH_INTERVAL=1 deploy::wait_health http://fake/health'
  assert_failure
  assert_output --partial "health check did not pass"
}

@test "deploy::prep_dirs creates dirs with correct ownership" {
  run deploy::prep_dirs "$TMPDIR/mount" "$TMPDIR/config" "$TMPDIR/data" $(id -u) $(id -g)
  assert_success
  [[ -d "$TMPDIR/mount" && -d "$TMPDIR/config" && -d "$TMPDIR/data" ]]
}
