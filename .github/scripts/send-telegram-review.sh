#!/usr/bin/env bash
# Sends the review report to Telegram. A short report travels as the message
# body; a report that does not fit is sent as a document attachment together
# with a short header message, so long reviews are never silently truncated.
# If the upload fails, the report falls back to consecutive text messages.
# Advisory only; always exits 0.
#
# Inputs (env): TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
# Args: [review_path] [message_text]
set -u

log() { printf '[telegram-review] %s\n' "$*"; }

bot_token="${TELEGRAM_BOT_TOKEN:-}"
chat_id="${TELEGRAM_CHAT_ID:-}"
review_path="${1:-}"
message_text="${2:-AI review finished with findings.}"
# Telegram rejects text messages above 4096 characters. 3500 leaves room for
# the truncation note and for characters the API counts as two code units.
max_message_characters=3500

if [ -z "$bot_token" ] || [ -z "$chat_id" ]; then
    log "TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID is not configured; skipping notification."
    exit 0
fi

send_api_uri="https://api.telegram.org/bot${bot_token}/sendMessage"
send_document_uri="https://api.telegram.org/bot${bot_token}/sendDocument"

# Pull Telegram's own error description out of a JSON response; falls back to
# the raw body so a failure is never reported as an empty message.
describe_response() {
    local body="$1" description
    description="$(printf '%s' "$body" | sed -n 's/.*"description":"\([^"]*\)".*/\1/p' | head -n 1)"
    if [ -n "$description" ]; then
        printf '%s' "$description"
    else
        printf '%s' "$body" | tr '\n' ' ' | cut -c 1-200
    fi
}

# send_text <text>: one message; returns non-zero (and logs why) on failure.
send_text() {
    local text="$1" response status
    response="$(curl -sS --retry 2 --retry-delay 2 --max-time 60 "$send_api_uri" \
        --data-urlencode "chat_id=${chat_id}" \
        --data-urlencode "text=${text}" \
        --data-urlencode "disable_web_page_preview=true" 2>&1)"
    status=$?
    if [ "$status" -eq 0 ] && printf '%s' "$response" | grep -q '"ok":true'; then
        return 0
    fi
    log "Telegram sendMessage failed (curl exit ${status}): $(describe_response "$response")"
    return 1
}

# send_document <path> <caption>: the report as a file attachment.
send_document() {
    local path="$1" caption="$2" response status
    if [ ! -f "$path" ]; then
        log "Attachment '$path' does not exist; skipping document."
        return 1
    fi
    response="$(curl -sS --retry 2 --retry-delay 2 --max-time 300 "$send_document_uri" \
        -F "chat_id=${chat_id}" \
        -F "document=@${path}" \
        -F "caption=${caption}" 2>&1)"
    status=$?
    if [ "$status" -eq 0 ] && printf '%s' "$response" | grep -q '"ok":true'; then
        log "Telegram review report attached."
        return 0
    fi
    log "Telegram sendDocument failed (curl exit ${status}): $(describe_response "$response")"
    return 1
}

# send_chunked <text>: split on line boundaries into message-sized parts. Used
# when the attachment route is unavailable, so the report still reaches the
# chat instead of being dropped.
send_chunked() {
    local text="$1" chunk="" line
    while IFS= read -r line || [ -n "$line" ]; do
        # A single over-long line is hard-split before it can join a chunk.
        while [ "${#line}" -gt "$max_message_characters" ]; do
            send_text "${line:0:$max_message_characters}" || return 1
            line="${line:$max_message_characters}"
        done
        if [ -n "$chunk" ] && [ "$(( ${#chunk} + ${#line} + 1 ))" -gt "$max_message_characters" ]; then
            send_text "$chunk" || return 1
            chunk=""
        fi
        chunk="${chunk:+$chunk
}${line}"
    done <<<"$text"
    if [ -n "$chunk" ]; then
        send_text "$chunk" || return 1
    fi
    return 0
}

# The workflow passes the path reported by the review step; fall back to the
# well-known runner location when that output is empty, otherwise a long report
# would silently travel as a header-only message.
if [ -z "$review_path" ] && [ -n "${RUNNER_TEMP:-}" ] && [ -f "${RUNNER_TEMP}/review-output.md" ]; then
    review_path="${RUNNER_TEMP}/review-output.md"
    log "No report path passed; using '$review_path'."
fi

report_text=""
if [ -n "$review_path" ] && [ -f "$review_path" ]; then
    report_text="$(sed -e 's/[[:space:]]*$//' "$review_path")"
elif [ -n "$review_path" ]; then
    log "Review report '$review_path' not found; sending the notification only."
fi

if [ -n "$report_text" ] && [ "$(( ${#message_text} + ${#report_text} + 2 ))" -gt "$max_message_characters" ]; then
    # Too long for one message: short header, then the full report as a file.
    header="${message_text}

The report is too long for a single message; the full report is attached as a file."
    send_text "$header" || true
    if send_document "$review_path" "AI review report"; then
        log "Telegram notification sent."
        exit 0
    fi
    log "Falling back to sending the report as consecutive messages."
    if send_chunked "$report_text"; then
        log "Telegram notification sent in parts."
    else
        log "Telegram notification could not be delivered."
    fi
    exit 0
fi

message_body="$message_text"
if [ -n "$report_text" ]; then
    message_body="${message_text}
${report_text}"
fi
if [ "${#message_body}" -gt "$max_message_characters" ]; then
    message_body="${message_body:0:$((max_message_characters - 80))}

... truncated; the full report could not be delivered ..."
fi

if send_text "$message_body"; then
    log "Telegram notification sent."
else
    log "Telegram notification could not be delivered."
fi

exit 0
