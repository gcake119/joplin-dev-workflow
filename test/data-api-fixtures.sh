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

    local path query page
    path="${url#http://fixture.local}"
    path="${path#http://localhost:41184}"
    query="${path#*\?}"
    path="${path%%\?*}"
    page=$(printf '%s' "$query" | tr '&' '\n' | awk -F= '$1 == "page" { print $2; found=1 } END { if (!found) print "1" }')
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
            if [ "$method" = "POST" ]; then
                case "$payload" in
                    *"Daily Notes"*) body='{"id":"created-daily","title":"Daily Notes"}' ;;
                    *"Blog Posts"*)
                        if [ "$FAKE_CURL_SCENARIO" = "setup_create_partial_fail" ]; then
                            body='{"error":"create failed"}'
                            status='500'
                        else
                            body='{"id":"created-post","title":"Blog Posts"}'
                        fi
                        ;;
                    *"Weekly Reviews"*) body='{"id":"created-weekly","title":"Weekly Reviews"}' ;;
                    *) body='{"id":"created-folder","title":"Created"}' ;;
                esac
            else
                case "$FAKE_CURL_SCENARIO" in
                    setup_create_defaults|setup_create_partial_fail|missing_folder) body='{"items":[]}' ;;
                    setup_create_conflict) body='{"items":[{"id":"daily-existing","title":"Daily Notes","parent_id":""}]}' ;;
                    duplicate_folder) body='{"items":[{"id":"a","title":"Daily Notes","parent_id":""},{"id":"b","title":"Daily Notes","parent_id":""}]}' ;;
                    invalid_shape) body='{"unexpected":[]}' ;;
                    folder_later_page)
                        if [ "$page" = "1" ]; then
                            body='{"items":[{"id":"post-id","title":"Blog Posts","parent_id":""}],"has_more":true}'
                        else
                            body='{"items":[{"id":"daily-page-2","title":"Daily Notes","parent_id":""}],"has_more":false}'
                        fi
                        ;;
                    folder_duplicate_across_pages)
                        if [ "$page" = "1" ]; then
                            body='{"items":[{"id":"daily-page-1","title":"Daily Notes","parent_id":""}],"has_more":true}'
                        else
                            body='{"items":[{"id":"daily-page-2","title":"Daily Notes","parent_id":""}],"has_more":false}'
                        fi
                        ;;
                    folder_hierarchy_duplicate)
                        body='{"items":[{"id":"work","title":"Work","parent_id":""},{"id":"personal","title":"Personal","parent_id":""},{"id":"daily-work","title":"Daily Notes","parent_id":"work"},{"id":"daily-personal","title":"Daily Notes","parent_id":"personal"}]}'
                        ;;
                    *)
                        body='{"items":[{"id":"daily-id","title":"Daily Notes","parent_id":""},{"id":"post-id","title":"Blog Posts","parent_id":""},{"id":"weekly-id","title":"Weekly Reviews","parent_id":""}]}'
                        ;;
                esac
            fi
            ;;
        /notes)
            body='{"id":"note-id","title":"Created","parent_id":"post-id"}'
            ;;
        /notes/note-id|/notes/note-today)
            if [ "$method" = "GET" ]; then
                body='{"id":"note-id","title":"2026-05-23 Daily Notes","body":"Existing body","parent_id":"daily-id"}'
            else
                body='{"id":"note-id","updated_time":1}'
            fi
            ;;
        /search)
            if printf '%s' "$url" | grep -q 'type=tag'; then
                case "$FAKE_CURL_SCENARIO" in
                    tag_later_page)
                        if [ "$page" = "1" ]; then
                            body='{"items":[],"has_more":true}'
                        else
                            body='{"items":[{"id":"tag-page-2","title":"til"}],"has_more":false}'
                        fi
                        ;;
                    *) body='{"items":[]}' ;;
                esac
            else
                case "$FAKE_CURL_SCENARIO" in
                    note_missing) body='{"items":[]}' ;;
                    note_duplicate) body='{"items":[{"id":"note-a","title":"2026-05-23 Daily Notes","parent_id":"daily-id"},{"id":"note-b","title":"2026-05-23 Daily Notes","parent_id":"daily-id"}]}' ;;
                    note_duplicate_today) body='{"items":[{"id":"note-a","title":"2026-05-24 Daily Notes","parent_id":"daily-id"},{"id":"note-b","title":"2026-05-24 Daily Notes","parent_id":"daily-id"}]}' ;;
                    note_outside_folder) body='{"items":[{"id":"outside","title":"2026-05-23 Daily Notes","parent_id":"other-id"}]}' ;;
                    note_duplicate_across_pages)
                        if [ "$page" = "1" ]; then
                            body='{"items":[{"id":"note-a","title":"2026-05-23 Daily Notes","parent_id":"daily-id"}],"has_more":true}'
                        else
                            body='{"items":[{"id":"note-b","title":"2026-05-23 Daily Notes","parent_id":"daily-id"}],"has_more":false}'
                        fi
                        ;;
                    *) body='{"items":[{"id":"note-id","title":"2026-05-23 Daily Notes","parent_id":"daily-id"},{"id":"note-today","title":"2026-05-24 Daily Notes","parent_id":"daily-id"}]}' ;;
                esac
            fi
            ;;
        /tags)
            body='{"id":"tag-id","title":"til"}'
            ;;
        /tags/tag-id/notes|/tags/tag-page-2/notes)
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

    if [ "$FAKE_CURL_SCENARIO" = "http_error_token_body" ]; then
        body="{\"error\":\"token ${JOPLIN_API_TOKEN} rejected\"}"
        status='500'
    fi

    if [ -n "$output_file" ]; then
        printf '%s' "$body" > "$output_file"
        printf '%s' "$status"
    else
        printf '%s' "$body"
    fi
}
