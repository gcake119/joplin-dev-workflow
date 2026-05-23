#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
mkdir -p "$FAKE_BIN"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cat > "$FAKE_BIN/curl" << EOF
#!/bin/bash
ROOT_DIR="$ROOT_DIR"
source "\$ROOT_DIR/test/data-api-fixtures.sh"
fixture_reset "\${FAKE_CURL_SCENARIO:-happy}"
JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
curl "\$@"
EOF

cat > "$FAKE_BIN/pbpaste" << 'EOF'
#!/bin/bash
printf '%s' "${CLIPBOARD_CONTENT:-}"
EOF

cat > "$FAKE_BIN/joplin" << 'EOF'
#!/bin/bash
echo "$@" >> "${JOPLIN_CALL_LOG:-/tmp/jwf-joplin-called}"
exit 99
EOF

chmod +x "$FAKE_BIN/curl" "$FAKE_BIN/pbpaste" "$FAKE_BIN/joplin"

PASS_COUNT=0

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    if ! printf '%s' "$haystack" | grep -Fq "$needle"; then
        echo "not ok - $message" >&2
        echo "  expected to contain: $needle" >&2
        echo "  actual: $haystack" >&2
        exit 1
    fi
    PASS_COUNT=$((PASS_COUNT + 1))
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    if printf '%s' "$haystack" | grep -Fq "$needle"; then
        echo "not ok - $message" >&2
        echo "  did not expect: $needle" >&2
        echo "  actual: $haystack" >&2
        exit 1
    fi
    PASS_COUNT=$((PASS_COUNT + 1))
}

run_command() {
    local scenario="$1"
    local command="$2"
    shift 2
    local curl_log="$TMP_DIR/curl.log"
    local joplin_log="$TMP_DIR/joplin.log"
    : > "$curl_log"
    : > "$joplin_log"

    env \
        PATH="$FAKE_BIN:$PATH" \
        HOME="$TMP_DIR/home" \
        JOPLIN_API_TOKEN="test-token" \
        JOPLIN_API_BASE_URL="http://fixture.local" \
        FAKE_CURL_SCENARIO="$scenario" \
        FAKE_CURL_LOG="$curl_log" \
        JOPLIN_CALL_LOG="$joplin_log" \
        CLIPBOARD_CONTENT="${CLIPBOARD_CONTENT-Fixture clipboard}" \
        "$ROOT_DIR/bin/$command" "$@" > "$TMP_DIR/out" 2> "$TMP_DIR/err"
}

test_learn_happy_path() {
    CLIPBOARD_CONTENT="Learning body" run_command happy learn "Understanding React Hooks"
    local output curl_log joplin_log
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    joplin_log=$(cat "$TMP_DIR/joplin.log")
    assert_contains "$output" "Learning article created" "learn reports successful Data API write"
    assert_contains "$curl_log" $'POST\thttp://fixture.local/notes?token=test-token' "learn creates a note through Data API"
    assert_contains "$curl_log" '"parent_id": "post-id"' "learn payload uses post folder parent_id"
    assert_not_contains "$joplin_log" "sync" "learn does not call joplin sync"
}

test_til_append_happy_path() {
    CLIPBOARD_CONTENT="Promise.all fails fast" run_command happy til "Promise.all behavior"
    local output curl_log joplin_log
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    joplin_log=$(cat "$TMP_DIR/joplin.log")
    assert_contains "$output" "TIL appended" "til appends existing daily note"
    assert_contains "$curl_log" $'PUT\thttp://fixture.local/notes/note-id?token=test-token' "til updates existing note through Data API"
    assert_not_contains "$joplin_log" "sync" "til does not call joplin sync"
}

test_til_create_when_missing() {
    CLIPBOARD_CONTENT="Array reduce note" run_command note_missing til
    local output curl_log
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    assert_contains "$output" "Today's note created with TIL" "til creates daily note when none exists in target folder"
    assert_contains "$curl_log" $'POST\thttp://fixture.local/notes?token=test-token' "til creates note through Data API"
    assert_contains "$curl_log" '"parent_id": "daily-id"' "til create payload uses daily folder parent_id"
}

test_weekly_happy_path() {
    CLIPBOARD_CONTENT="Weekly summary" run_command happy weekly "W07 Learning Summary"
    local output curl_log joplin_log
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    joplin_log=$(cat "$TMP_DIR/joplin.log")
    assert_contains "$output" "Weekly review created" "weekly reports successful Data API write"
    assert_contains "$output" "Week:" "weekly reports computed date range"
    assert_contains "$curl_log" '"parent_id": "weekly-id"' "weekly payload uses weekly folder parent_id"
    assert_not_contains "$joplin_log" "sync" "weekly does not call joplin sync"
}

test_empty_clipboard_fails() {
    if CLIPBOARD_CONTENT="" run_command happy learn "Empty"; then
        echo "not ok - empty clipboard should fail" >&2
        exit 1
    fi
    assert_contains "$(cat "$TMP_DIR/err")" "Clipboard is empty" "empty clipboard error remains"
}

test_learn_happy_path
test_til_append_happy_path
test_til_create_when_missing
test_weekly_happy_path
test_empty_clipboard_fails

echo "ok - $PASS_COUNT command checks passed"
