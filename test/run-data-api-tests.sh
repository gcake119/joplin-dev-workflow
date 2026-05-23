#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=test/data-api-fixtures.sh
source "$ROOT_DIR/test/data-api-fixtures.sh"
# shellcheck source=lib/joplin_data_api.sh
source "$ROOT_DIR/lib/joplin_data_api.sh"

PASS_COUNT=0

assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    if [ "$expected" != "$actual" ]; then
        echo "not ok - $message" >&2
        echo "  expected: $expected" >&2
        echo "  actual:   $actual" >&2
        exit 1
    fi
    PASS_COUNT=$((PASS_COUNT + 1))
}

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

assert_fails() {
    local message="$1"
    shift
    if "$@" >/tmp/jwf-test-out 2>/tmp/jwf-test-err; then
        echo "not ok - $message" >&2
        cat /tmp/jwf-test-out >&2
        cat /tmp/jwf-test-err >&2
        exit 1
    fi
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_api_init_explicit_base_url() {
    fixture_reset happy
    JOPLIN_API_BASE_URL="http://fixture.local"
    joplin_api_init >/tmp/jwf-test-out 2>/tmp/jwf-test-err
    assert_eq "http://fixture.local" "$JOPLIN_API_BASE_URL_RESOLVED" "explicit base URL is used"
}

test_api_init_port_probe() {
    fixture_reset happy
    joplin_api_init >/tmp/jwf-test-out 2>/tmp/jwf-test-err
    assert_eq "http://localhost:41184" "$JOPLIN_API_BASE_URL_RESOLVED" "port probing finds default API port"
}

test_api_init_unavailable() {
    fixture_reset unavailable
    assert_fails "unavailable API fails before writing" joplin_api_init
    assert_contains "$(cat /tmp/jwf-test-err)" "Joplin Data API is not available" "unavailable API message is actionable"
}

test_api_init_missing_token() {
    fixture_reset happy
    JOPLIN_API_TOKEN=""
    assert_fails "missing token fails before writing" joplin_api_init
    assert_contains "$(cat /tmp/jwf-test-err)" "Joplin Data API token is not configured" "missing token message is actionable"
}

test_api_invalid_json() {
    fixture_reset invalid_json
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    assert_fails "invalid JSON fails request" joplin_api_request GET "/folders?fields=id,title"
    assert_contains "$(cat /tmp/jwf-test-err)" "invalid JSON" "invalid JSON is surfaced"
}

test_folder_resolution_by_id() {
    fixture_reset happy
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    local folder_id
    folder_id=$(joplin_resolve_folder_id "post-id" "Blog Posts" "post")
    assert_eq "post-id" "$folder_id" "configured notebook ID wins"
}

test_folder_resolution_by_title() {
    fixture_reset happy
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    local folder_id
    folder_id=$(joplin_resolve_folder_id "" "Daily Notes" "daily")
    assert_eq "daily-id" "$folder_id" "unique notebook title resolves"
}

test_folder_resolution_missing_title() {
    fixture_reset missing_folder
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    assert_fails "missing title refuses write" joplin_resolve_folder_id "" "Daily Notes" "daily"
    assert_contains "$(cat /tmp/jwf-test-err)" "Notebook not found" "missing notebook title is surfaced"
}

test_folder_resolution_duplicate_title() {
    fixture_reset duplicate_folder
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    assert_fails "duplicate title refuses write" joplin_resolve_folder_id "" "Daily Notes" "daily"
    assert_contains "$(cat /tmp/jwf-test-err)" "Multiple notebooks" "duplicate notebook title is surfaced"
}

test_folder_resolution_invalid_id() {
    fixture_reset happy
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    assert_fails "invalid ID refuses write" joplin_resolve_folder_id "missing-id" "Daily Notes" "daily"
    assert_contains "$(cat /tmp/jwf-test-err)" "notebook ID was not found" "invalid notebook ID is surfaced"
}

test_note_helpers() {
    fixture_reset happy
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    local created body found
    created=$(joplin_create_note "Title" "Body" "post-id")
    assert_eq "note-id" "$(printf '%s' "$created" | jq -r '.id')" "note create returns note ID"
    body=$(joplin_get_note_body "note-id")
    assert_eq "Existing body" "$body" "note body read returns body"
    joplin_update_note_body "note-id" "Updated body" >/tmp/jwf-test-out
    found=$(joplin_find_note_by_title_in_folder "2026-05-23 Daily Notes" "daily-id")
    assert_eq "note-id" "$found" "note lookup is scoped to folder"
}

test_note_lookup_outside_folder() {
    fixture_reset note_outside_folder
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    local status
    set +e
    joplin_find_note_by_title_in_folder "2026-05-23 Daily Notes" "daily-id" >/tmp/jwf-test-out 2>/tmp/jwf-test-err
    status=$?
    set -e
    if [ "$status" -eq 0 ]; then
        echo "not ok - outside folder match should not update target folder" >&2
        exit 1
    fi
    assert_eq "2" "$status" "outside folder match returns not found"
}

test_note_lookup_duplicate() {
    fixture_reset note_duplicate
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    assert_fails "duplicate daily notes refuse update" joplin_find_note_by_title_in_folder "2026-05-23 Daily Notes" "daily-id"
    assert_contains "$(cat /tmp/jwf-test-err)" "Multiple notes" "duplicate daily note is surfaced"
}

test_tag_binding_failure() {
    fixture_reset tag_fail
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    assert_fails "tag binding failure is surfaced" joplin_apply_tags "note-id" "#til"
    assert_contains "$(cat /tmp/jwf-test-err)" "tag binding failed" "tag failure does not look successful"
}

test_http_error() {
    fixture_reset http_error
    JOPLIN_API_BASE_URL_RESOLVED="http://fixture.local"
    assert_fails "HTTP error fails request" joplin_api_request GET "/folders?fields=id,title"
    assert_contains "$(cat /tmp/jwf-test-err)" "HTTP 500" "HTTP status is surfaced"
}

test_api_init_explicit_base_url
test_api_init_port_probe
test_api_init_unavailable
test_api_init_missing_token
test_api_invalid_json
test_folder_resolution_by_id
test_folder_resolution_by_title
test_folder_resolution_missing_title
test_folder_resolution_duplicate_title
test_folder_resolution_invalid_id
test_note_helpers
test_note_lookup_outside_folder
test_note_lookup_duplicate
test_tag_binding_failure
test_http_error

rm -f /tmp/jwf-test-out /tmp/jwf-test-err
echo "ok - $PASS_COUNT data API adapter checks passed"
