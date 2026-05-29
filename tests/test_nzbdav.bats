#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/log.sh"
  source "$SCRIPT_DIR/lib/nzbdav.sh"
  FIXTURES="$SCRIPT_DIR/tests/fixtures"
}

@test "nzbdav::import_providers emits one YAML block per provider" {
  run nzbdav::import_providers "$FIXTURES/nzbdav-with-providers.sqlite"
  assert_success
  assert_output --partial "host: news.newshosting.com"
  assert_output --partial "host: news.easynews.com"
  assert_output --partial "port: 563"
  assert_output --partial "tls: true"
  assert_output --partial "tls: false"
  assert_output --partial "max_connections: 50"
}

@test "nzbdav::import_providers returns empty list on empty DB" {
  run nzbdav::import_providers "$FIXTURES/nzbdav-empty.sqlite"
  assert_success
  assert_output "providers: []"
}

@test "nzbdav::import_providers fails on missing file" {
  run nzbdav::import_providers /tmp/__no_such_db__
  assert_failure
}
