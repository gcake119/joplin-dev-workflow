#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
NO_JQ_BIN="$TMP_DIR/no-jq-bin"
mkdir -p "$FAKE_BIN"
mkdir -p "$NO_JQ_BIN"

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
ln -s "$FAKE_BIN/curl" "$NO_JQ_BIN/curl"
ln -s "$FAKE_BIN/pbpaste" "$NO_JQ_BIN/pbpaste"
ln -s /usr/bin/dirname "$NO_JQ_BIN/dirname"
ln -s /usr/bin/readlink "$NO_JQ_BIN/readlink"

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

run_doctor() {
    local scenario="$1"
    local token="${2-test-token}"
    local path_value="${3-$FAKE_BIN:$PATH}"
    if [ "$#" -ge 3 ]; then
        shift 3
    else
        set --
    fi
    local curl_log="$TMP_DIR/curl.log"
    local joplin_log="$TMP_DIR/joplin.log"
    : > "$curl_log"
    : > "$joplin_log"

    env \
        PATH="$path_value" \
        HOME="$TMP_DIR/home" \
        JOPLIN_API_TOKEN="$token" \
        JOPLIN_API_BASE_URL="http://fixture.local" \
        FAKE_CURL_SCENARIO="$scenario" \
        FAKE_CURL_LOG="$curl_log" \
        JOPLIN_CALL_LOG="$joplin_log" \
        CLIPBOARD_CONTENT="${CLIPBOARD_CONTENT-Fixture clipboard}" \
        "$ROOT_DIR/bin/joplin-workflow-doctor" "$@" > "$TMP_DIR/out" 2> "$TMP_DIR/err"
}

test_doctor_happy_path() {
    CLIPBOARD_CONTENT="Doctor clipboard" run_doctor happy
    local output curl_log
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    assert_contains "$output" "Doctor checks passed" "doctor reports healthy base mode"
    assert_contains "$output" "daily: Daily Notes" "doctor resolves daily notebook"
    assert_not_contains "$curl_log" $'POST\t' "doctor does not create data"
}

test_doctor_missing_jq() {
    local no_jq_path="$NO_JQ_BIN"
    if CLIPBOARD_CONTENT="Doctor clipboard" run_doctor happy test-token "$no_jq_path"; then
        echo "not ok - doctor should fail when jq is missing" >&2
        exit 1
    fi
    assert_contains "$(cat "$TMP_DIR/err")" "jq is required" "doctor reports missing jq"
}

test_doctor_missing_token() {
    if CLIPBOARD_CONTENT="Doctor clipboard" run_doctor happy ""; then
        echo "not ok - doctor should fail when token is missing" >&2
        exit 1
    fi
    assert_contains "$(cat "$TMP_DIR/err")" "Joplin Data API token is not configured" "doctor reports missing token"
}

test_doctor_unavailable_api() {
    if CLIPBOARD_CONTENT="Doctor clipboard" run_doctor unavailable; then
        echo "not ok - doctor should fail when Data API is unavailable" >&2
        exit 1
    fi
    assert_contains "$(cat "$TMP_DIR/err")" "Joplin Data API is not responding" "doctor reports unavailable explicit base URL"
}

test_doctor_ambiguous_notebook() {
    if CLIPBOARD_CONTENT="Doctor clipboard" run_doctor duplicate_folder; then
        echo "not ok - doctor should fail when notebook title is ambiguous" >&2
        exit 1
    fi
    assert_contains "$(cat "$TMP_DIR/err")" "Multiple notebooks" "doctor surfaces ambiguous notebook"
}

test_setup_existing_persists_ids_without_creating_folders() {
    CLIPBOARD_CONTENT="Doctor clipboard" run_doctor happy test-token "$FAKE_BIN:$PATH" --setup-existing
    local output curl_log config_file
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    config_file="$TMP_DIR/home/.config/joplin-workflow/config"
    assert_contains "$output" "Existing notebooks configured" "setup existing reports success"
    assert_contains "$(cat "$config_file")" 'NOTEBOOK_DAILY_ID="daily-id"' "setup existing writes daily ID"
    assert_contains "$(cat "$config_file")" 'NOTEBOOK_POST_ID="post-id"' "setup existing writes post ID"
    assert_contains "$(cat "$config_file")" 'NOTEBOOK_WEEKLY_ID="weekly-id"' "setup existing writes weekly ID"
    assert_not_contains "$curl_log" $'POST\thttp://fixture.local/folders' "setup existing does not create folders"
}

test_setup_create_defaults_creates_empty_folders_and_persists_ids() {
    CLIPBOARD_CONTENT="Doctor clipboard" run_doctor setup_create_defaults test-token "$FAKE_BIN:$PATH" --setup-create-defaults
    local output curl_log config_file
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    config_file="$TMP_DIR/home/.config/joplin-workflow/config"
    assert_contains "$output" "Default empty notebooks created" "setup create defaults reports success"
    assert_contains "$curl_log" $'POST\thttp://fixture.local/folders?token=test-token' "setup create defaults creates folders"
    assert_contains "$(cat "$config_file")" 'NOTEBOOK_DAILY_ID="created-daily"' "setup create defaults writes daily ID"
    assert_contains "$(cat "$config_file")" 'NOTEBOOK_POST_ID="created-post"' "setup create defaults writes post ID"
    assert_contains "$(cat "$config_file")" 'NOTEBOOK_WEEKLY_ID="created-weekly"' "setup create defaults writes weekly ID"
}

test_setup_create_defaults_refuses_duplicate_title() {
    if CLIPBOARD_CONTENT="Doctor clipboard" run_doctor setup_create_conflict test-token "$FAKE_BIN:$PATH" --setup-create-defaults; then
        echo "not ok - setup create defaults should fail on existing title" >&2
        exit 1
    fi
    assert_contains "$(cat "$TMP_DIR/err")" "already exists" "setup create defaults reports existing title conflict"
    assert_not_contains "$(cat "$TMP_DIR/curl.log")" $'POST\thttp://fixture.local/folders' "setup create defaults does not create duplicate folders"
}

test_setup_create_defaults_reports_partial_failure() {
    mkdir -p "$TMP_DIR/home/.config/joplin-workflow"
    printf '%s\n' 'KEEP_ME="yes"' > "$TMP_DIR/home/.config/joplin-workflow/config"
    if CLIPBOARD_CONTENT="Doctor clipboard" run_doctor setup_create_partial_fail test-token "$FAKE_BIN:$PATH" --setup-create-defaults; then
        echo "not ok - setup create defaults should fail on partial create failure" >&2
        exit 1
    fi
    local config_text error_output
    config_text=$(cat "$TMP_DIR/home/.config/joplin-workflow/config")
    error_output=$(cat "$TMP_DIR/err")
    assert_contains "$error_output" "created-daily" "partial failure reports created folder ID"
    assert_contains "$config_text" 'KEEP_ME="yes"' "partial failure preserves unrelated config"
}

test_learn_dry_run_resolves_target_without_mutation() {
    CLIPBOARD_CONTENT="Learning body" run_command happy learn --dry-run "Understanding React Hooks"
    local output curl_log
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    assert_contains "$output" "Dry run" "learn dry run reports non-mutating mode"
    assert_contains "$output" "Would create learning article" "learn dry run reports planned note creation"
    assert_contains "$output" "Notebook ID: post-id" "learn dry run reports resolved notebook ID"
    assert_not_contains "$curl_log" $'POST\t' "learn dry run does not create note or tags"
    assert_not_contains "$curl_log" $'PUT\t' "learn dry run does not update notes"
    assert_not_contains "$curl_log" $'DELETE\t' "learn dry run does not delete anything"
}

test_weekly_dry_run_resolves_target_without_mutation() {
    CLIPBOARD_CONTENT="Weekly summary" run_command happy weekly --dry-run "W07 Learning Summary"
    local output curl_log
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    assert_contains "$output" "Dry run" "weekly dry run reports non-mutating mode"
    assert_contains "$output" "Would create weekly review" "weekly dry run reports planned note creation"
    assert_contains "$output" "Notebook ID: weekly-id" "weekly dry run reports resolved notebook ID"
    assert_not_contains "$curl_log" $'POST\t' "weekly dry run does not create note or tags"
    assert_not_contains "$curl_log" $'PUT\t' "weekly dry run does not update notes"
    assert_not_contains "$curl_log" $'DELETE\t' "weekly dry run does not delete anything"
}

test_til_dry_run_append_existing_without_mutation() {
    rm -f "$TMP_DIR/home/.config/joplin-workflow/config"
    CLIPBOARD_CONTENT="Promise.all fails fast" run_command happy til --dry-run "Promise.all behavior"
    local output curl_log
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    assert_contains "$output" "Dry run" "til dry run reports non-mutating mode"
    assert_contains "$output" "Would append to today's note" "til dry run reports append action"
    assert_contains "$output" "Note ID: note-today" "til dry run reports resolved note ID"
    assert_not_contains "$curl_log" $'POST\t' "til append dry run does not create notes or tags"
    assert_not_contains "$curl_log" $'PUT\t' "til append dry run does not update notes"
    assert_not_contains "$curl_log" $'DELETE\t' "til append dry run does not delete anything"
}

test_til_dry_run_create_missing_without_mutation() {
    rm -f "$TMP_DIR/home/.config/joplin-workflow/config"
    CLIPBOARD_CONTENT="Array reduce note" run_command note_missing til --dry-run
    local output curl_log
    output=$(cat "$TMP_DIR/out")
    curl_log=$(cat "$TMP_DIR/curl.log")
    assert_contains "$output" "Would create today's note" "til dry run reports create action"
    assert_contains "$output" "Notebook ID: daily-id" "til create dry run reports resolved notebook ID"
    assert_not_contains "$curl_log" $'POST\t' "til create dry run does not create note or tags"
    assert_not_contains "$curl_log" $'PUT\t' "til create dry run does not update notes"
    assert_not_contains "$curl_log" $'DELETE\t' "til create dry run does not delete anything"
}

test_til_dry_run_duplicate_fails_before_mutation() {
    rm -f "$TMP_DIR/home/.config/joplin-workflow/config"
    if CLIPBOARD_CONTENT="Duplicate note" run_command note_duplicate_today til --dry-run "Duplicate"; then
        echo "not ok - til dry run should fail on duplicate target daily note" >&2
        exit 1
    fi
    assert_contains "$(cat "$TMP_DIR/err")" "Multiple notes named" "til dry run reports duplicate daily note"
    assert_not_contains "$(cat "$TMP_DIR/curl.log")" $'POST\t' "til duplicate dry run does not create note or tags"
    assert_not_contains "$(cat "$TMP_DIR/curl.log")" $'PUT\t' "til duplicate dry run does not update notes"
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
    assert_contains "$curl_log" $'PUT\thttp://fixture.local/notes/note-today?token=test-token' "til updates existing note through Data API"
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
test_doctor_happy_path
test_doctor_missing_jq
test_doctor_missing_token
test_doctor_unavailable_api
test_doctor_ambiguous_notebook
test_setup_existing_persists_ids_without_creating_folders
test_setup_create_defaults_creates_empty_folders_and_persists_ids
test_setup_create_defaults_refuses_duplicate_title
test_setup_create_defaults_reports_partial_failure
test_learn_dry_run_resolves_target_without_mutation
test_weekly_dry_run_resolves_target_without_mutation
test_til_dry_run_append_existing_without_mutation
test_til_dry_run_create_missing_without_mutation
test_til_dry_run_duplicate_fails_before_mutation

echo "ok - $PASS_COUNT command checks passed"
