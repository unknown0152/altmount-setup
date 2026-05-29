#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/log.sh"
  source "$SCRIPT_DIR/lib/jwt.sh"
  TMPDIR=$(mktemp -d)
}

teardown() { rm -rf "$TMPDIR"; }

@test "jwt::ensure creates new secret when missing" {
  run jwt::ensure "$TMPDIR/jwt.secret"
  assert_success
  [[ -f "$TMPDIR/jwt.secret" ]]
  [[ $(wc -c < "$TMPDIR/jwt.secret") -ge 64 ]]
}

@test "jwt::ensure leaves existing secret untouched" {
  echo -n "ABCDEF" > "$TMPDIR/jwt.secret"
  run jwt::ensure "$TMPDIR/jwt.secret"
  assert_success
  [[ "$(cat "$TMPDIR/jwt.secret")" == "ABCDEF" ]]
}

@test "jwt::ensure sets file mode 600" {
  run jwt::ensure "$TMPDIR/jwt.secret"
  mode=$(stat -c '%a' "$TMPDIR/jwt.secret")
  [[ "$mode" == "600" ]]
}
