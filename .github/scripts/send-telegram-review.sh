#!/usr/bin/env bash
# Sends the review report to Telegram as a message (plus a document attachment
# when it does not fit into one message). Advisory only; always exits 0.
#
# Inputs (env): TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
# Args: [review_path] [message_text]
set -u

log() { printf '[telegram-review] %s\n' "$*"; }

bot_token="${TELEGRAM_BOT_TOKEN:-}"
chat_id="${TELEGRAM_CHAT_ID:-}"
review_path="${1:-}"
message_text="${2:-AI review finished with findings.}"
max_message_characters=3500

if [ -z "$bot_token" ] || [ -z "$chat_id" ]; then
    log "TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID is not configured; skipping notification."
    exit 0
fi

report_text=""
if [ -n "$review_path" ] && [ -f "$review_path" ]; then
    report_text="$(sed -e 's/[[:space:]]*$//' "$review_path")"
fi

send_api_uri="https://api.telegram.org/bot${bot_token}/sendMessage"
send_document_uri="https://api.telegram.org/bot${bot_token}/sendDocument"
message_body="$message_text"

report_length=$(( ${#report_text} + 0 ))
combined_length=$(( ${#message_body} + report_length + 2 ))
if [ -n "$report_text" ] && [ "$combined_length" -le "$max_message_characters" ]; then
    message_body="${message_text}
${report_text}"
elif [ "${#message_body}" -gt "$max_message_characters" ]; then
    message_body="${message_body:0:$((max_message_characters - 80))}

... truncated; see attached review report ..."
fi

if curl -fsS "$send_api_uri" \
    --data-urlencode "chat_id=${chat_id}" \
    --data-urlencode "text=${message_body}" \
    --data-urlencode "disable_web_page_preview=true" >/dev/null 2>&1; then
    log "Telegram notification sent."
else
    log "Telegram sendMessage failed."
fi

report_length=$(( ${#report_text} + 0 ))
combined_length=$(( ${#message_text} + report_length + 2 ))
if [ -n "$review_path" ] && [ -f "$review_path" ] && [ -n "$report_text" ] && [ "$combined_length" -gt "$max_message_characters" ]; then
    if curl -fsS "$send_document_uri" \
        -F "chat_id=${chat_id}" \
        -F "document=@${review_path}" \
        -F "caption=AI review report" >/dev/null 2>&1; then
        log "Telegram review report attached."
    else
        log "Telegram sendDocument failed."
    fi
fi

exit 0
