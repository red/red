# Telegram AI Review Webhook

This Cloudflare Worker receives Telegram bot webhooks for AI review fix commands and starts the GitHub Actions workflow that creates the fix PR.

The normal flow is:

1. `.github/workflows/ai-review.yml` sends an AI review report to Telegram.
2. A reviewer replies to that report with `@Red_Code_Review_bot fix it`.
3. Telegram sends the update to this Worker.
4. The Worker validates the webhook secret, chat ID, bot command, and GitHub Actions run URL.
5. The Worker sends a `repository_dispatch` event to GitHub.
6. `.github/workflows/ai-review-telegram-command.yml` downloads the selected review artifact and creates or updates the fix PR.

## Required Secrets

Configure these as Cloudflare Worker secrets:

- `TELEGRAM_BOT_TOKEN`: Telegram bot token from BotFather.
- `TELEGRAM_WEBHOOK_SECRET`: a long random string used by Telegram's `secret_token` webhook header.
- `TELEGRAM_CHAT_ID`: the Telegram chat where review commands are allowed.
- `GITHUB_TOKEN`: a GitHub token that can create `repository_dispatch` events for this repo.

Configure these Worker vars in `wrangler.toml`:

- `TELEGRAM_BOT_USERNAME`: bot username without `@`; default is `Red_Code_Review_bot`.
- `GITHUB_REPOSITORY`: repository in `owner/name` form; this repo uses `red/red`.

Also configure these in the GitHub repository:

- GitHub Actions secrets:
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_CHAT_ID`
- Optional GitHub Actions variables:
  - `TELEGRAM_BOT_USERNAME`
  - `AI_REVIEW_TEST_COMMAND`

## Deploy With Wrangler

Install and log in to Wrangler:

```powershell
cd .github\telegram-webhook
npm install -g wrangler
wrangler login
```

Set Worker secrets:

```powershell
wrangler secret put TELEGRAM_BOT_TOKEN
wrangler secret put TELEGRAM_WEBHOOK_SECRET
wrangler secret put TELEGRAM_CHAT_ID
wrangler secret put GITHUB_TOKEN
```

Deploy:

```powershell
wrangler deploy
```

The deploy output includes the Worker URL, for example:

```text
https://red-review-telegram-webhook.<your-subdomain>.workers.dev
```

## Configure Telegram Webhook

Use the same `TELEGRAM_WEBHOOK_SECRET` value you stored in Cloudflare. Telegram webhook secret tokens may contain letters, numbers, `_`, and `-`.

```powershell
$botToken = "<telegram bot token>"
$workerUrl = "https://red-review-telegram-webhook.<your-subdomain>.workers.dev"
$secret = "<same value as TELEGRAM_WEBHOOK_SECRET>"

Invoke-RestMethod `
  -Method Post `
  -Uri "https://api.telegram.org/bot$botToken/setWebhook" `
  -Body @{
    url = $workerUrl
    secret_token = $secret
    allowed_updates = '["message","edited_message"]'
  }
```

Check webhook status:

```powershell
Invoke-RestMethod "https://api.telegram.org/bot$botToken/getWebhookInfo"
```

## Find The Telegram Chat ID

Before setting the webhook, send a message to the bot in the target chat and run:

```powershell
$botToken = "<telegram bot token>"
Invoke-RestMethod "https://api.telegram.org/bot$botToken/getUpdates" | ConvertTo-Json -Depth 20
```

Use the `message.chat.id` value as `TELEGRAM_CHAT_ID`.

## GitHub Token

Use a fine-grained personal access token scoped to this repository. It needs permission to create repository dispatch events. For fine-grained tokens, use repository `Contents` read/write permission.

Store that token as the Cloudflare Worker secret `GITHUB_TOKEN`. Do not store it as a GitHub Actions secret for this webhook path; the Worker needs it to start the Actions workflow.

## Test

1. Push a change that causes `.github/workflows/ai-review.yml` to send a Telegram report.
2. In Telegram, reply to the exact report to fix with:

   ```text
   @Red_Code_Review_bot fix it
   ```

3. The Worker should reply that it accepted the command.
4. GitHub Actions should start `AI Review Telegram Command`.
5. If Codex creates a fix, the workflow opens or updates a PR.

You can also manually start `AI Review Telegram Command` from GitHub Actions with an AI Review run ID.
