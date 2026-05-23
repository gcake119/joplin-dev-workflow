#!/bin/bash

fixture_reset() {
    FAKE_CURL_SCENARIO="${1:-happy}"
    FAKE_CURL_CALLS=""
    JOPLIN_API_BASE_URL=""
    JOPLIN_API_TOKEN="test-token"
    JOPLIN_API_PORT_START=41184
    JOPLIN_API_PORT_END=41186
    JOPLIN_API_TIMEOUT=1
    DEBUG=false
    JOPLIN_API_BASE_URL_RESOLVED=""
}

curl() {
    local output_file=""
    local method="GET"
    local payload=""
    local url=""
    local arg

    while [ "$#" -gt 0 ]; do
        arg="$1"
        case "$arg" in
            -o)
                output_file="$2"
                shift 2
                ;;
            -X)
                method="$2"
                shift 2
                ;;
            --data)
                payload="$2"
                shift 2
                ;;
            -sS|--connect-timeout|--max-time|-w|-H)
                if [ "$arg" = "--connect-timeout" ] || [ "$arg" = "--max-time" ] || [ "$arg" = "-w" ] || [ "$arg" = "-H" ]; then
                    shift 2
                else
                    shift
                fi
                ;;
            http://*|https://*)
                url="$arg"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    FAKE_CURL_CALLS="${FAKE_CURL_CALLS}${method} ${url}
"
    if [ -n "${FAKE_CURL_LOG:-}" ]; then
        printf '%s\t%s\t%s\n' "$method" "$url" "$payload" >> "$FAKE_CURL_LOG"
    fi

    if printf '%s' "$url" | grep -q '/ping'; then
        if [ "$FAKE_CURL_SCENARIO" = "unavailable" ]; then
            return 7
        fi
        printf 'JoplinClipperServer'
        return 0
    fi

    local path
    path="${url#http://fixture.local}"
    path="${path#http://localhost:41184}"
    path="${path%%\?*}"
    local body='{}'
    local status='200'

    case "$path" in
        /folders/post-id|/folders/daily-id|/folders/weekly-id)
            body='{"id":"folder-id","title":"Configured"}'
            ;;
        /folders/missing-id)
            body='{"error":"not found"}'
            status='404'
            ;;
        /folders)
            case "$FAKE_CURL_SCENARIO" in
                missing_folder) body='{"items":[]}' ;;
                duplicate_folder) body='{"items":[{"id":"a","title":"Daily Notes","parent_id":""},{"id":"b","title":"Daily Notes","parent_id":""}]}' ;;
                *) body='{"items":[{"id":"daily-id","title":"Daily Notes","parent_id":""},{"id":"post-id","title":"Blog Posts","parent_id":""},{"id":"weekly-id","title":"Weekly Reviews","parent_id":""}]}' ;;
            esac
            ;;
        /notes)
            body='{"id":"note-id","title":"Created","parent_id":"post-id"}'
            ;;
        /notes/note-id)
            if [ "$method" = "GET" ]; then
                body='{"id":"note-id","title":"2026-05-23 Daily Notes","body":"Existing body","parent_id":"daily-id"}'
            else
                body='{"id":"note-id","updated_time":1}'
            fi
            ;;
        /search)
            if printf '%s' "$url" | grep -q 'type=tag'; then
                body='{"items":[]}'
            else
                case "$FAKE_CURL_SCENARIO" in
                    note_missing) body='{"items":[]}' ;;
                    note_duplicate) body='{"items":[{"id":"note-a","title":"2026-05-23 Daily Notes","parent_id":"daily-id"},{"id":"note-b","title":"2026-05-23 Daily Notes","parent_id":"daily-id"}]}' ;;
                    note_outside_folder) body='{"items":[{"id":"outside","title":"2026-05-23 Daily Notes","parent_id":"other-id"}]}' ;;
                    *) body='{"items":[{"id":"note-id","title":"2026-05-23 Daily Notes","parent_id":"daily-id"}]}' ;;
                esac
            fi
            ;;
        /tags)
            body='{"id":"tag-id","title":"til"}'
            ;;
        /tags/tag-id/notes)
            if [ "$FAKE_CURL_SCENARIO" = "tag_fail" ]; then
                body='{"error":"tag failed"}'
                status='500'
            else
                body='{"id":"note-id"}'
            fi
            ;;
        *)
            body='{"error":"unknown path"}'
            status='404'
            ;;
    esac

    if [ "$FAKE_CURL_SCENARIO" = "invalid_json" ]; then
        body='not-json'
    fi

    if [ "$FAKE_CURL_SCENARIO" = "http_error" ]; then
        body='{"error":"server"}'
        status='500'
    fi

    if [ -n "$output_file" ]; then
        printf '%s' "$body" > "$output_file"
        printf '%s' "$status"
    else
        printf '%s' "$body"
    fi
}
