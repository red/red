[CmdletBinding()]
param(
    [string]$BotToken = $env:TELEGRAM_BOT_TOKEN,
    [string]$ChatId = $env:TELEGRAM_CHAT_ID,
    [string]$ReviewPath,
    [string]$MessageText,
    [int]$MaxMessageCharacters = 3500
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[telegram-review] $Message"
}

function Limit-Text {
    param(
        [string]$Text,
        [int]$MaxCharacters
    )

    if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -le $MaxCharacters) {
        return $Text
    }

    return "$($Text.Substring(0, $MaxCharacters - 80).TrimEnd())`n`n... truncated; see attached review report ..."
}

if ([string]::IsNullOrWhiteSpace($BotToken) -or [string]::IsNullOrWhiteSpace($ChatId)) {
    Write-Info "TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID is not configured; skipping notification."
    exit 0
}

$reportText = ""
if (-not [string]::IsNullOrWhiteSpace($ReviewPath) -and (Test-Path $ReviewPath)) {
    $reportText = (Get-Content -Path $ReviewPath -Raw).Trim()
}

if ([string]::IsNullOrWhiteSpace($MessageText)) {
    $MessageText = "AI review finished with findings."
}

$sendMessageUri = "https://api.telegram.org/bot$BotToken/sendMessage"
$sendDocumentUri = "https://api.telegram.org/bot$BotToken/sendDocument"
$messageBody = $MessageText

if (-not [string]::IsNullOrWhiteSpace($reportText) -and (($messageBody.Length + $reportText.Length + 2) -le $MaxMessageCharacters)) {
    $messageBody = "$messageBody`n`n$reportText"
}
else {
    $messageBody = Limit-Text -Text $messageBody -MaxCharacters $MaxMessageCharacters
}

Invoke-RestMethod -Uri $sendMessageUri -Method Post -Body @{
    chat_id = $ChatId
    text = $messageBody
    disable_web_page_preview = "true"
} | Out-Null

if (-not [string]::IsNullOrWhiteSpace($ReviewPath) -and (Test-Path $ReviewPath) -and -not [string]::IsNullOrWhiteSpace($reportText) -and (($MessageText.Length + $reportText.Length + 2) -gt $MaxMessageCharacters)) {
    Invoke-RestMethod -Uri $sendDocumentUri -Method Post -Form @{
        chat_id = $ChatId
        document = Get-Item -Path $ReviewPath
        caption = "AI review report"
    } | Out-Null
}

Write-Info "Telegram notification sent."
