#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/log.sh"
  source "$SCRIPT_DIR/lib/render.sh"
  TMPL="$SCRIPT_DIR/templates/config.yaml.tmpl"
}

@test "render::config substitutes all required tokens" {
  out=$(render::config "$TMPL" "providers: []" "    []" "    []" "supersecret")
  [[ "$out" == *"password: supersecret"* ]]
  [[ "$out" == *"providers: []"* ]]
  [[ "$out" != *"__PROVIDERS_BLOCK__"* ]]
  [[ "$out" != *"__RADARR_INSTANCES__"* ]]
  [[ "$out" != *"__SONARR_INSTANCES__"* ]]
  [[ "$out" != *"__WEBDAV_PASSWORD__"* ]]
}

@test "render::config fails when template missing" {
  run render::config /tmp/__nope__ "providers: []" "[]" "[]" "pw"
  assert_failure
}
