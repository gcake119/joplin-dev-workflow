#!/bin/bash
# Shared Joplin Desktop Data API adapter for joplin-dev-workflow commands.

JOPLIN_API_BASE_URL_RESOLVED=""
JOPLIN_API_LAST_STATUS=""
JOPLIN_API_LAST_BODY=""

jwf_error() {
    echo "❌ $1" >&2
}

jwf_redact_secrets() {
    local message="$1"
    local token
    token=$(joplin_api_token 2>/dev/null || true)

    if [ -n "$token" ]; then
        message="${message//$token/[REDACTED]}"
    fi

    printf '%s' "$message"
}

jwf_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "DEBUG: $(jwf_redact_secrets "$1")" >&2
    fi
}

jwf_require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        jwf_error "$1 is required"
        return 1
    fi
}

jwf_clipboard_read() {
    if [ -n "${CLIPBOARD_CMD:-}" ]; then
        sh -c "$CLIPBOARD_CMD"
        return $?
    fi

    if command -v pbpaste >/dev/null 2>&1; then
        pbpaste
        return $?
    fi

    if command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -o
        return $?
    fi

    if command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --output
        return $?
    fi

    jwf_error "Clipboard command not found"
    echo "Please install a clipboard tool or set CLIPBOARD_CMD in your config." >&2
    return 1
}

joplin_api_token() {
    if [ -n "${JOPLIN_API_TOKEN:-}" ]; then
        printf '%s' "$JOPLIN_API_TOKEN"
    elif [ -n "${JOPLIN_TOKEN:-}" ]; then
        printf '%s' "$JOPLIN_TOKEN"
    fi
}

joplin_api_urlencode() {
    jq -rn --arg value "$1" '$value|@uri'
}

joplin_api_url() {
    local path="$1"
    local token
    token=$(joplin_api_token)

    case "$path" in
        http://*|https://*) ;;
        *) path="${JOPLIN_API_BASE_URL_RESOLVED}${path}" ;;
    esac

    if printf '%s' "$path" | grep -q '?'; then
        printf '%s&token=%s' "$path" "$(joplin_api_urlencode "$token")"
    else
        printf '%s?token=%s' "$path" "$(joplin_api_urlencode "$token")"
    fi
}

joplin_api_request() {
    local method="$1"
    local path="$2"
    local payload="${3:-}"
    local timeout="${JOPLIN_API_TIMEOUT:-5}"
    local response_file status request_url

    JOPLIN_API_LAST_STATUS=""
    JOPLIN_API_LAST_BODY=""

    if ! jwf_require_command curl || ! jwf_require_command jq; then
        return 1
    fi

    response_file=$(mktemp)
    request_url=$(joplin_api_url "$path")

    if [ -n "$payload" ]; then
        status=$(curl -sS --connect-timeout "$timeout" --max-time "$timeout" \
            -X "$method" -H "Content-Type: application/json" \
            -o "$response_file" -w "%{http_code}" \
            --data "$payload" "$request_url") || {
            rm -f "$response_file"
            jwf_error "Joplin Data API request timed out or failed. Check Joplin Desktop and Web Clipper service."
            return 1
        }
    else
        status=$(curl -sS --connect-timeout "$timeout" --max-time "$timeout" \
            -X "$method" -o "$response_file" -w "%{http_code}" \
            "$request_url") || {
            rm -f "$response_file"
            jwf_error "Joplin Data API request timed out or failed. Check Joplin Desktop and Web Clipper service."
            return 1
        }
    fi

    JOPLIN_API_LAST_STATUS="$status"
    JOPLIN_API_LAST_BODY=$(cat "$response_file")
    rm -f "$response_file"

    case "$status" in
        2??) ;;
        401|403)
            jwf_error "Joplin Data API token is missing or invalid. Configure JOPLIN_API_TOKEN in your local config."
            jwf_debug "HTTP $status: $(printf '%s' "$JOPLIN_API_LAST_BODY" | head -c 300)"
            return 1
            ;;
        *)
            jwf_error "Joplin Data API request failed with HTTP $status."
            jwf_debug "HTTP $status: $(printf '%s' "$JOPLIN_API_LAST_BODY" | head -c 300)"
            return 1
            ;;
    esac

    if [ -n "$JOPLIN_API_LAST_BODY" ] && ! printf '%s' "$JOPLIN_API_LAST_BODY" | jq empty >/dev/null 2>&1; then
        jwf_error "Joplin Data API returned invalid JSON."
        jwf_debug "HTTP $status: $(printf '%s' "$JOPLIN_API_LAST_BODY" | head -c 300)"
        return 1
    fi

    printf '%s' "$JOPLIN_API_LAST_BODY"
}

joplin_api_path_with_page() {
    local path="$1"
    local page="$2"

    if printf '%s' "$path" | grep -q '?'; then
        printf '%s&page=%s' "$path" "$page"
    else
        printf '%s?page=%s' "$path" "$page"
    fi
}

joplin_api_collect_pages() {
    local path="$1"
    local page=1
    local response has_more items

    items='[]'
    while :; do
        response=$(joplin_api_request GET "$(joplin_api_path_with_page "$path" "$page")") || return 1
        if ! printf '%s' "$response" | jq -e 'has("items") and (.items | type == "array")' >/dev/null 2>&1; then
            jwf_error "Joplin Data API returned an invalid response shape."
            jwf_debug "Expected paginated response with items array on page $page."
            return 1
        fi

        items=$(jq -cn --argjson existing "$items" --argjson response "$response" '$existing + $response.items')
        has_more=$(printf '%s' "$response" | jq -r '.has_more // false')
        [ "$has_more" = "true" ] || break
        page=$((page + 1))
    done

    jq -cn --argjson items "$items" '{items: $items}'
}

joplin_api_ping() {
    local base_url="$1"
    local timeout="${JOPLIN_API_TIMEOUT:-5}"
    curl -sS --connect-timeout "$timeout" --max-time "$timeout" "${base_url}/ping" 2>/dev/null | grep -q "JoplinClipperServer"
}

joplin_api_init() {
    local token base_url port start_port end_port
    token=$(joplin_api_token)

    if [ -z "$token" ]; then
        jwf_error "Joplin Data API token is not configured."
        echo "Set JOPLIN_API_TOKEN in ~/.config/joplin-workflow/config or your environment." >&2
        return 1
    fi

    if ! jwf_require_command curl || ! jwf_require_command jq; then
        return 1
    fi

    if [ -n "${JOPLIN_API_BASE_URL:-}" ]; then
        base_url="${JOPLIN_API_BASE_URL%/}"
        if joplin_api_ping "$base_url"; then
            JOPLIN_API_BASE_URL_RESOLVED="$base_url"
            return 0
        fi

        jwf_error "Joplin Data API is not responding at $base_url."
        echo "Open Joplin Desktop, enable Web Clipper service, and check JOPLIN_API_BASE_URL." >&2
        return 1
    fi

    start_port="${JOPLIN_API_PORT_START:-41184}"
    end_port="${JOPLIN_API_PORT_END:-41194}"
    port="$start_port"
    jwf_debug "Probing Joplin Data API ports ${start_port}-${end_port}."

    while [ "$port" -le "$end_port" ]; do
        base_url="http://localhost:${port}"
        if joplin_api_ping "$base_url"; then
            JOPLIN_API_BASE_URL_RESOLVED="$base_url"
            return 0
        fi
        jwf_debug "No /ping response at $base_url."
        port=$((port + 1))
    done

    jwf_error "Joplin Data API is not available."
    echo "Open Joplin Desktop and enable Web Clipper service, then retry." >&2
    return 1
}

joplin_resolve_folder_id() {
    local id_value="$1"
    local title_value="$2"
    local label="$3"
    local response matches count folder_id

    if [ -n "$id_value" ]; then
        if joplin_api_request GET "/folders/${id_value}" >/dev/null; then
            printf '%s' "$id_value"
            return 0
        fi

        jwf_error "Configured ${label} notebook ID was not found: $id_value"
        return 1
    fi

    if [ -z "$title_value" ]; then
        jwf_error "${label} notebook is not configured."
        return 1
    fi

    response=$(joplin_api_collect_pages "/folders?fields=id,title,parent_id&limit=100") || return 1
    matches=$(printf '%s' "$response" | jq --arg title "$title_value" '[.items[] | select(.title == $title)]')
    count=$(printf '%s' "$matches" | jq 'length')

    if [ "$count" -eq 0 ]; then
        jwf_error "Notebook not found: $title_value"
        echo "Create it in Joplin Desktop or configure the ${label} notebook ID." >&2
        return 1
    fi

    if [ "$count" -gt 1 ]; then
        jwf_error "Multiple notebooks named '$title_value' were found."
        echo "Set the ${label} notebook ID in your local config to avoid writing to the wrong notebook." >&2
        printf '%s' "$response" | jq -r --arg title "$title_value" '
            .items as $folders |
            def folder_for($id): first($folders[] | select(.id == $id)) // null;
            def folder_path($id):
                (folder_for($id)) as $folder |
                if $folder == null then $id
                elif (($folder.parent_id // "") == "") then $folder.title
                else (folder_path($folder.parent_id) + " / " + $folder.title)
                end;
            $folders[] | select(.title == $title) | "  - " + .id + " " + folder_path(.id)
        ' >&2
        return 1
    fi

    folder_id=$(printf '%s' "$matches" | jq -r '.[0].id')
    printf '%s' "$folder_id"
}

joplin_create_note() {
    local title="$1"
    local body="$2"
    local parent_id="$3"
    local payload

    payload=$(jq -n --arg title "$title" --arg body "$body" --arg parent_id "$parent_id" \
        '{title: $title, body: $body, parent_id: $parent_id}')
    joplin_api_request POST "/notes" "$payload"
}

joplin_create_folder() {
    local title="$1"
    local payload

    payload=$(jq -n --arg title "$title" '{title: $title}')
    joplin_api_request POST "/folders" "$payload"
}

joplin_get_note_body() {
    local note_id="$1"
    joplin_api_request GET "/notes/${note_id}?fields=id,title,body,parent_id" | jq -r '.body'
}

joplin_update_note_body() {
    local note_id="$1"
    local body="$2"
    local payload

    payload=$(jq -n --arg body "$body" '{body: $body}')
    joplin_api_request PUT "/notes/${note_id}" "$payload"
}

joplin_find_note_by_title_in_folder() {
    local title="$1"
    local parent_id="$2"
    local encoded_title response matches count

    encoded_title=$(joplin_api_urlencode "$title")
    response=$(joplin_api_collect_pages "/search?query=${encoded_title}&type=note&fields=id,title,parent_id&limit=100") || return 1
    matches=$(printf '%s' "$response" | jq --arg title "$title" --arg parent_id "$parent_id" \
        '[.items[] | select(.title == $title and .parent_id == $parent_id)]')
    count=$(printf '%s' "$matches" | jq 'length')

    if [ "$count" -eq 0 ]; then
        return 2
    fi

    if [ "$count" -gt 1 ]; then
        jwf_error "Multiple notes named '$title' exist in the target notebook."
        echo "Resolve duplicate daily notes in Joplin Desktop before appending." >&2
        return 3
    fi

    printf '%s' "$matches" | jq -r '.[0].id'
}

joplin_apply_tags() {
    local note_id="$1"
    local tags="$2"
    local tag token title encoded response matches count tag_id payload

    for tag in $tags; do
        title="${tag#\#}"
        [ -z "$title" ] && continue

        encoded=$(joplin_api_urlencode "$title")
        response=$(joplin_api_collect_pages "/search?query=${encoded}&type=tag&fields=id,title&limit=100") || return 1
        matches=$(printf '%s' "$response" | jq --arg title "$title" '[.items[] | select(.title == $title)]')
        count=$(printf '%s' "$matches" | jq 'length')

        if [ "$count" -eq 0 ]; then
            payload=$(jq -n --arg title "$title" '{title: $title}')
            response=$(joplin_api_request POST "/tags" "$payload") || return 1
            tag_id=$(printf '%s' "$response" | jq -r '.id')
        else
            tag_id=$(printf '%s' "$matches" | jq -r '.[0].id')
        fi

        payload=$(jq -n --arg id "$note_id" '{id: $id}')
        if ! joplin_api_request POST "/tags/${tag_id}/notes" "$payload" >/dev/null; then
            jwf_error "Note was written, but tag binding failed for #$title."
            return 1
        fi
    done
}

jwf_desktop_sync_message() {
    if [ "${AUTO_SYNC:-true}" = "true" ]; then
        echo ""
        echo "Sync: Written to local Joplin. Cloud sync follows your Joplin Desktop sync settings."
    fi
}
