const DISPATCH_EVENT_TYPE = "telegram-review-fix";

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
    },
  });
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function getMessage(update) {
  return update?.message || update?.edited_message || null;
}

function getMessageText(message) {
  return message?.text || message?.caption || "";
}

function getRunContext(text, expectedRepository) {
  const match = text.match(/https?:\/\/[^/\s]+\/([^/\s]+)\/([^/\s]+)\/actions\/runs\/([0-9]+)/i);
  if (!match) {
    return null;
  }

  const repository = `${match[1]}/${match[2]}`;
  if (expectedRepository && repository.toLowerCase() !== expectedRepository.toLowerCase()) {
    return null;
  }

  return {
    runId: match[3],
    runUrl: match[0],
    repository,
  };
}

function isFixCommand(text, message, botUsername) {
  const fixPattern = /\b(?:fix\s+it|(?:make|create|open)\s+a\s+pr\s+to\s+fix\s+it)\b/i;
  if (!fixPattern.test(text)) {
    return false;
  }

  const mentionsBot = new RegExp(`@${escapeRegExp(botUsername)}\\b`, "i").test(text);
  const replyUsername = message?.reply_to_message?.from?.username || "";
  const isReplyToBot = replyUsername.toLowerCase() === botUsername.toLowerCase();

  return mentionsBot || isReplyToBot;
}

async function sendTelegramMessage(env, chatId, text, replyToMessageId) {
  if (!env.TELEGRAM_BOT_TOKEN) {
    return;
  }

  const body = {
    chat_id: chatId,
    text,
    disable_web_page_preview: true,
  };

  if (replyToMessageId) {
    body.reply_parameters = {
      message_id: replyToMessageId,
    };
  }

  await fetch(`https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/sendMessage`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

async function dispatchGitHub(env, payload) {
  const response = await fetch(`https://api.github.com/repos/${env.GITHUB_REPOSITORY}/dispatches`, {
    method: "POST",
    headers: {
      accept: "application/vnd.github+json",
      authorization: `Bearer ${env.GITHUB_TOKEN}`,
      "content-type": "application/json",
      "user-agent": "red-review-telegram-webhook",
      "x-github-api-version": "2022-11-28",
    },
    body: JSON.stringify({
      event_type: DISPATCH_EVENT_TYPE,
      client_payload: payload,
    }),
  });

  if (response.status !== 204) {
    const errorText = await response.text();
    const error = new Error(`GitHub dispatch failed with ${response.status}: ${errorText}`);
    error.status = response.status;
    throw error;
  }
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === "GET") {
      return jsonResponse({ ok: true, service: "red-review-telegram-webhook" });
    }

    if (request.method !== "POST") {
      return jsonResponse({ ok: false, error: "method_not_allowed" }, 405);
    }

    const expectedSecret = env.TELEGRAM_WEBHOOK_SECRET || "";
    const actualSecret = request.headers.get("x-telegram-bot-api-secret-token") || "";
    if (!expectedSecret || actualSecret !== expectedSecret) {
      return jsonResponse({ ok: false, error: "unauthorized" }, 401);
    }

    let update;
    try {
      update = await request.json();
    } catch {
      return jsonResponse({ ok: false, error: "invalid_json" }, 400);
    }

    const message = getMessage(update);
    const chatId = message?.chat?.id;
    const expectedChatId = env.TELEGRAM_CHAT_ID || "";

    if (!message || String(chatId) !== String(expectedChatId)) {
      return jsonResponse({ ok: true, ignored: "wrong_chat_or_no_message" });
    }

    const botUsername = env.TELEGRAM_BOT_USERNAME || "Red_Code_Review_bot";
    const text = getMessageText(message);
    if (!isFixCommand(text, message, botUsername)) {
      return jsonResponse({ ok: true, ignored: "not_a_fix_command" });
    }

    const replyText = getMessageText(message.reply_to_message);
    const runContext = getRunContext(`${text}\n${replyText}`, env.GITHUB_REPOSITORY);
    if (!runContext) {
      ctx.waitUntil(sendTelegramMessage(
        env,
        chatId,
        `Please reply to an AI review report that contains a GitHub Actions run URL, then send: @${botUsername} fix it`,
        message.message_id,
      ));
      return jsonResponse({ ok: true, ignored: "missing_run_url" });
    }

    const payload = {
      run_id: runContext.runId,
      run_url: runContext.runUrl,
      command_text: text,
      telegram_chat_id: String(chatId),
      telegram_message_id: String(message.message_id || ""),
    };

    try {
      await dispatchGitHub(env, payload);
    } catch (error) {
      const shouldRetry = error.status === 429 || error.status >= 500 || !error.status;
      if (!shouldRetry) {
        ctx.waitUntil(sendTelegramMessage(
          env,
          chatId,
          `I could not start the fix workflow for run ${runContext.runId}: ${error.message}`,
          message.message_id,
        ));
      }

      return jsonResponse(
        { ok: false, error: "dispatch_failed", retryable: shouldRetry },
        shouldRetry ? 500 : 200,
      );
    }

    ctx.waitUntil(sendTelegramMessage(
      env,
      chatId,
      `Accepted fix command for AI review run ${runContext.runId}.`,
      message.message_id,
    ));

    return jsonResponse({ ok: true, dispatched: true, run_id: runContext.runId });
  },
};
