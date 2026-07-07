[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ReviewPath,

    [string]$HeadSha = $env:GITHUB_SHA,
    [string]$BaseBranch = $env:GITHUB_REF_NAME,
    [string]$FixBranchPrefix = "ai-review/fix",
    [string]$TestCommand = $env:AI_REVIEW_TEST_COMMAND
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[codex-fix] $Message"
}

function Write-GitHubOutput {
    param(
        [string]$Name,
        [AllowNull()][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($env:GITHUB_OUTPUT)) {
        return
    }

    if ($null -eq $Value) {
        $Value = ""
    }

    $delimiter = "EOF_$([Guid]::NewGuid().ToString("N"))"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$Name<<$delimiter" -Encoding utf8
    Add-Content -Path $env:GITHUB_OUTPUT -Value $Value -Encoding utf8
    Add-Content -Path $env:GITHUB_OUTPUT -Value $delimiter -Encoding utf8
}

function Invoke-Git {
    param([string[]]$Arguments)

    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Invoke-GitOutput {
    param([string[]]$Arguments)

    $output = & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }

    return ($output | Out-String).Trim()
}

function ConvertTo-SafeBranchPart {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "branch"
    }

    $safe = $Value -replace "[^A-Za-z0-9._-]", "-"
    $safe = $safe -replace "-+", "-"
    $safe = $safe.Trim(".-".ToCharArray())

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "branch"
    }

    return $safe
}

function Limit-Text {
    param(
        [string]$Text,
        [int]$MaxCharacters = 12000
    )

    if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -le $MaxCharacters) {
        return $Text
    }

    return "$($Text.Substring(0, $MaxCharacters).TrimEnd())`n`n... truncated ..."
}

function Test-CodexUsageError {
    param([string]$Output)

    return $Output -match "(?m)^error: " -and $Output -match "(?m)^Usage: codex "
}

if (-not (Test-Path $ReviewPath)) {
    throw "Review report not found: $ReviewPath"
}

if ([string]::IsNullOrWhiteSpace($HeadSha)) {
    $HeadSha = Invoke-GitOutput @("rev-parse", "HEAD")
}

if ([string]::IsNullOrWhiteSpace($BaseBranch)) {
    $BaseBranch = Invoke-GitOutput @("branch", "--show-current")
}

$outputRoot = if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) { (Get-Location).Path } else { $env:RUNNER_TEMP }
$fixLastMessagePath = Join-Path $outputRoot "codex-fix-last-message.md"
$fixTranscriptPath = Join-Path $outputRoot "codex-fix-transcript.txt"
$fixSummaryPath = Join-Path $outputRoot "codex-fix-summary.md"
$prBodyPath = Join-Path $outputRoot "codex-fix-pr-body.md"
$testOutputPath = Join-Path $outputRoot "codex-fix-test-output.txt"

$shortHead = $HeadSha.Substring(0, [Math]::Min(12, $HeadSha.Length))
$basePart = ConvertTo-SafeBranchPart $BaseBranch
$fixBranch = "$FixBranchPrefix/$basePart-$shortHead"
$reviewText = (Get-Content -Path $ReviewPath -Raw).Trim()
$repoRoot = (Get-Location).Path

Write-GitHubOutput -Name "fix_created" -Value "false"
Write-GitHubOutput -Name "fix_status" -Value "started"
Write-GitHubOutput -Name "fix_error" -Value ""
Write-GitHubOutput -Name "fix_branch" -Value $fixBranch
Write-GitHubOutput -Name "pr_body_path" -Value $prBodyPath
Write-GitHubOutput -Name "fix_summary_path" -Value $fixSummaryPath
Write-GitHubOutput -Name "fix_transcript_path" -Value $fixTranscriptPath

Write-Info "Creating fix branch $fixBranch from $shortHead."
Invoke-Git @("switch", "-C", $fixBranch, $HeadSha)
$initialHead = Invoke-GitOutput @("rev-parse", "HEAD")

$prompt = @"
You are running in GitHub Actions to fix issues found by an AI code review.

Repository: $env:GITHUB_REPOSITORY
Reviewed commit: $HeadSha
Target branch: $BaseBranch

Fix only the concrete issues described in the review report below. Keep changes minimal and local to the findings. Do not perform unrelated refactors. Do not create commits, branches, pull requests, tags, or releases; the workflow will handle git operations after you finish. Follow the repository instructions in AGENTS.md.

Review report:

$reviewText
"@

Write-Info "Running Codex fix pass."
$fixLines = $prompt | & codex exec -C $repoRoot -s danger-full-access --output-last-message $fixLastMessagePath - 2>&1
$codexExitCode = $LASTEXITCODE
$fixTranscript = ($fixLines | Out-String).TrimEnd()

if ([string]::IsNullOrWhiteSpace($fixTranscript)) {
    $fixTranscript = "Codex produced no fix transcript output."
}

Set-Content -Path $fixTranscriptPath -Value $fixTranscript -Encoding utf8

$currentHead = Invoke-GitOutput @("rev-parse", "HEAD")
$status = (& git status --porcelain | Out-String).Trim()

if ((Test-CodexUsageError $fixTranscript) -or ($codexExitCode -ne 0 -and [string]::IsNullOrWhiteSpace($status) -and $currentHead -eq $initialHead)) {
    $transcriptTail = Limit-Text -Text $fixTranscript -MaxCharacters 4000
    $errorMessage = "Codex fix pass failed with exit code $codexExitCode. See $fixTranscriptPath."
    $summary = @"
# AI Review Fix Failed

$errorMessage

## Transcript Tail

````text
$transcriptTail
````
"@

    Set-Content -Path $fixSummaryPath -Value $summary -Encoding utf8
    Set-Content -Path $prBodyPath -Value $summary -Encoding utf8
    Write-GitHubOutput -Name "fix_status" -Value "failed"
    Write-GitHubOutput -Name "fix_error" -Value $errorMessage
    throw $errorMessage
}

if ($codexExitCode -ne 0) {
    Write-Warning "Codex fix pass exited with code $codexExitCode, but produced changes; continuing with commit."
}

if ([string]::IsNullOrWhiteSpace($status) -and $currentHead -eq $initialHead) {
    $summary = @"
# AI Review Fix

Codex did not produce any changes for the reported issues.
"@

    Set-Content -Path $fixSummaryPath -Value $summary -Encoding utf8
    Set-Content -Path $prBodyPath -Value $summary -Encoding utf8
    Write-GitHubOutput -Name "fix_status" -Value "no_changes"
    Write-Info "No fix changes produced."
    exit 0
}

Invoke-Git @("config", "user.name", "github-actions[bot]")
Invoke-Git @("config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com")

if (-not [string]::IsNullOrWhiteSpace($status)) {
    Invoke-Git @("add", "--all")
    & git diff --cached --quiet --exit-code
    $cachedDiffExitCode = $LASTEXITCODE

    if ($cachedDiffExitCode -eq 1) {
        Invoke-Git @("commit", "-m", "Fix AI review findings for $shortHead")
    }
    elseif ($cachedDiffExitCode -ne 0) {
        throw "git diff --cached failed with exit code $cachedDiffExitCode."
    }
}

$testStatus = "not configured"
if (-not [string]::IsNullOrWhiteSpace($TestCommand)) {
    Write-Info "Running validation command: $TestCommand"
    $testLines = & pwsh -NoProfile -Command $TestCommand 2>&1
    $testExitCode = $LASTEXITCODE
    $testOutput = ($testLines | Out-String).TrimEnd()

    if ([string]::IsNullOrWhiteSpace($testOutput)) {
        $testOutput = "Validation command produced no output."
    }

    Set-Content -Path $testOutputPath -Value $testOutput -Encoding utf8
    $testStatus = if ($testExitCode -eq 0) { "passed" } else { "failed with exit code $testExitCode" }
}

$finalHead = Invoke-GitOutput @("rev-parse", "HEAD")
if ($finalHead -eq $initialHead) {
    throw "Expected fix branch to contain a new commit, but HEAD did not change."
}

Write-Info "Pushing $fixBranch."
& git fetch --no-tags origin "+refs/heads/$fixBranch`:refs/remotes/origin/$fixBranch" 2>$null
Invoke-Git @("push", "--force-with-lease", "origin", "HEAD`:refs/heads/$fixBranch")

$fixSummary = "Codex fix completed."
if (Test-Path $fixLastMessagePath) {
    $fixSummary = (Get-Content -Path $fixLastMessagePath -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($fixSummary)) {
        $fixSummary = "Codex fix completed."
    }
}

$diffStat = Invoke-GitOutput @("diff", "--stat", "$initialHead..$finalHead")
if ([string]::IsNullOrWhiteSpace($diffStat)) {
    $diffStat = "No diff stat available."
}

$limitedReview = Limit-Text -Text $reviewText -MaxCharacters 10000
$limitedFixSummary = Limit-Text -Text $fixSummary -MaxCharacters 8000

$prBody = @"
## AI Review Fix

- Reviewed commit: ``$shortHead``
- Source branch: ``$BaseBranch``
- Fix branch: ``$fixBranch``
- Validation: ``$testStatus``

## Diff Stat

````text
$diffStat
````

## Fix Summary

$limitedFixSummary

## Review Report

$limitedReview
"@

Set-Content -Path $fixSummaryPath -Value $limitedFixSummary -Encoding utf8
Set-Content -Path $prBodyPath -Value $prBody -Encoding utf8

Write-GitHubOutput -Name "fix_created" -Value "true"
Write-GitHubOutput -Name "fix_status" -Value "created"
Write-GitHubOutput -Name "fix_error" -Value ""
Write-GitHubOutput -Name "fix_branch" -Value $fixBranch
Write-GitHubOutput -Name "pr_body_path" -Value $prBodyPath
Write-GitHubOutput -Name "fix_summary_path" -Value $fixSummaryPath
Write-GitHubOutput -Name "fix_transcript_path" -Value $fixTranscriptPath
Write-GitHubOutput -Name "test_status" -Value $testStatus

Write-Info "Fix branch pushed."
