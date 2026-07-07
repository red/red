[CmdletBinding()]
param(
    [string]$BeforeSha = $env:REVIEW_BEFORE,
    [string]$HeadSha = $env:REVIEW_SHA,
    [string]$DefaultBranch = $env:DEFAULT_BRANCH,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[codex-review] $Message"
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

function Test-ZeroSha {
    param([string]$Sha)
    return -not [string]::IsNullOrWhiteSpace($Sha) -and $Sha -match "^0+$"
}

function Test-GitCommit {
    param([string]$Ref)

    if ([string]::IsNullOrWhiteSpace($Ref)) {
        return $false
    }

    & git cat-file -e "$Ref^{commit}" 2>$null
    return $LASTEXITCODE -eq 0
}

function Invoke-GitOutput {
    param([string[]]$Arguments)

    $output = & git @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return ($output | Out-String).Trim()
}

function Resolve-HeadSha {
    param([string]$Candidate)

    if ((-not [string]::IsNullOrWhiteSpace($Candidate)) -and -not (Test-ZeroSha $Candidate) -and (Test-GitCommit $Candidate)) {
        return $Candidate
    }

    $head = Invoke-GitOutput @("rev-parse", "HEAD")
    if ([string]::IsNullOrWhiteSpace($head)) {
        throw "Unable to resolve HEAD for review."
    }

    return $head
}

function Resolve-BaseSha {
    param(
        [string]$Before,
        [string]$DefaultBranchName
    )

    if ((-not (Test-ZeroSha $Before)) -and (Test-GitCommit $Before)) {
        return $Before
    }

    if ([string]::IsNullOrWhiteSpace($DefaultBranchName)) {
        $DefaultBranchName = "master"
    }

    $remoteDefault = "origin/$DefaultBranchName"
    if (-not (Test-GitCommit $remoteDefault)) {
        Write-Info "Fetching origin/$DefaultBranchName to resolve a base commit."
        & git fetch --no-tags origin "+refs/heads/$DefaultBranchName`:refs/remotes/origin/$DefaultBranchName"
        if ($LASTEXITCODE -ne 0) {
            Write-Info "Unable to fetch origin/$DefaultBranchName; falling back to local history."
        }
    }

    if (Test-GitCommit $remoteDefault) {
        $mergeBase = Invoke-GitOutput @("merge-base", "HEAD", $remoteDefault)
        if (-not [string]::IsNullOrWhiteSpace($mergeBase)) {
            return $mergeBase
        }
    }

    if (Test-GitCommit "HEAD~1") {
        return (Invoke-GitOutput @("rev-parse", "HEAD~1"))
    }

    return $null
}

function Write-ReviewSummary {
    param(
        [string]$Markdown,
        [string]$OutputPath
    )

    $parent = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }

    Set-Content -Path $OutputPath -Value $Markdown -Encoding utf8

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $Markdown -Encoding utf8
    }
}

function Test-CodexUsageError {
    param([string]$Output)

    return $Output -match "(?m)^error: " -and $Output -match "(?m)^Usage: codex "
}

function Test-ReviewHasIssues {
    param([string]$ReviewText)

    if ([string]::IsNullOrWhiteSpace($ReviewText)) {
        return $false
    }

    $normalized = $ReviewText.Trim()
    if ($normalized -eq "Codex produced no review output.") {
        return $false
    }

    $issuePatterns = @(
        "(?im)^\s*-\s*\[(P[0-9]|S[0-9]|critical|high|medium|low|bug|security|performance|correctness)\]",
        "(?im)^\s*\[(P[0-9]|S[0-9]|critical|high|medium|low|bug|security|performance|correctness)\]",
        "(?im)^\s*(critical|high|medium|low|warning|error|bug|security|correctness|performance)\s*:",
        "(?im)^\s*(finding|issue)\s+\d+\s*:",
        "(?im)^\s*#+\s*(findings|issues)\b",
        "(?im)\b(can|could|may|will)\s+(produce|cause|lead to|result in)\s+.+\b(crash|failure|malformed|invalid|wrong|missing|regression|bug)\b"
    )

    foreach ($pattern in $issuePatterns) {
        if ($normalized -match $pattern) {
            return $true
        }
    }

    $cleanPatterns = @(
        "(?is)^\s*(no findings|no issues found|no issues detected|no actionable issues|no actionable findings|nothing to report|looks good to me|lgtm)\.?\s*$",
        "(?is)^\s*findings\s*:\s*(none|no(ne)? issues)\.?\s*$",
        "(?is)^\s*there are no (findings|issues|actionable issues|actionable findings)\.?\s*$",
        "(?is)^\s*i found no (findings|issues|actionable issues|actionable findings)\.?\s*$",
        "(?is)^\s*(the patch|this patch|the change|this change|the changes|this update).*\b(no|not any|without)\s+((evident|obvious|functional|actionable)\s+)*(regressions?|issues?|findings?|bugs?)\b.*$",
        "(?is)^\s*(the patch|this patch|the change|this change|the changes|this update|the updated iteration).*\bdoes not introduce (any|an|a) ((evident|obvious|functional|actionable|correctness)\s+)*(regressions?|issues?|bugs?)\b.*$"
    )

    foreach ($pattern in $cleanPatterns) {
        if ($normalized -match $pattern) {
            return $false
        }
    }

    if (
        $normalized -match "(?i)\b(now\s+matches|matches)\b" -and
        $normalized -match "(?i)\bno downstream references\b" -and
        $normalized -match "(?i)\bdoes not introduce (any|an|a) ((evident|obvious|functional|actionable|correctness)\s+)*(regressions?|issues?|bugs?)\b"
    ) {
        return $false
    }

    return $true
}

function Limit-ReviewLength {
    param(
        [string]$Text,
        [int]$MaxCharacters = 12000
    )

    if ($Text.Length -le $MaxCharacters) {
        return $Text
    }

    $tailLength = [Math]::Min(4000, $MaxCharacters)
    $headLength = $MaxCharacters - $tailLength
    $head = $Text.Substring(0, $headLength).TrimEnd()
    $tail = $Text.Substring($Text.Length - $tailLength).TrimStart()

    return @"
$head

... review output truncated; see codex-review-transcript.txt for the full raw transcript ...

$tail
"@.Trim()
}

$outputRoot = if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) { (Get-Location).Path } else { $env:RUNNER_TEMP }
$reviewOutputPath = Join-Path $outputRoot "codex-review-output.md"
$transcriptOutputPath = Join-Path $outputRoot "codex-review-transcript.txt"
$lastMessageOutputPath = Join-Path $outputRoot "codex-review-last-message.md"

if (Test-ZeroSha $HeadSha) {
    Write-Info "Push deleted a ref; skipping review."
    Write-GitHubOutput -Name "has_issues" -Value "false"
    Write-GitHubOutput -Name "review_output_path" -Value $reviewOutputPath
    Write-GitHubOutput -Name "transcript_path" -Value $transcriptOutputPath
    Write-GitHubOutput -Name "last_message_path" -Value $lastMessageOutputPath
    Write-GitHubOutput -Name "range_label" -Value ""
    exit 0
}

$HeadSha = Resolve-HeadSha $HeadSha

$shortHead = $HeadSha.Substring(0, [Math]::Min(12, $HeadSha.Length))
$baseSha = Resolve-BaseSha -Before $BeforeSha -DefaultBranchName $DefaultBranch
$baseBranch = $null
$singleCommitMode = [string]::IsNullOrWhiteSpace($baseSha)

try {
    $reviewArgs = @("exec", "review", "--output-last-message", $lastMessageOutputPath)
    $rangeLabel = $null

    if ($singleCommitMode) {
        Write-Info "No base commit found; reviewing HEAD commit only."
        $reviewArgs += @("--commit", $HeadSha)
        $rangeLabel = $shortHead
    }
    else {
        $baseBranch = "codex-review-base-$shortHead"
        Write-Info "Using $baseSha as review base."
        & git branch --force $baseBranch $baseSha
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to create temporary review base branch '$baseBranch'."
        }

        $reviewArgs += @("--base", $baseBranch)
        $rangeLabel = "$baseSha..$HeadSha"
    }

    if ($DryRun) {
        Write-Info "Dry run: codex $($reviewArgs -join ' ')"
        Write-Info "Dry run range: $rangeLabel"
        Write-GitHubOutput -Name "has_issues" -Value "false"
        Write-GitHubOutput -Name "review_output_path" -Value $reviewOutputPath
        Write-GitHubOutput -Name "transcript_path" -Value $transcriptOutputPath
        Write-GitHubOutput -Name "last_message_path" -Value $lastMessageOutputPath
        Write-GitHubOutput -Name "range_label" -Value $rangeLabel
        exit 0
    }

    Write-Info "Running Codex review for $rangeLabel."
    $reviewLines = & codex @reviewArgs 2>&1
    $codexExitCode = $LASTEXITCODE
    $rawReviewText = ($reviewLines | Out-String).TrimEnd()

    if ([string]::IsNullOrWhiteSpace($rawReviewText)) {
        $rawReviewText = "Codex produced no transcript output."
    }

    Set-Content -Path $transcriptOutputPath -Value $rawReviewText -Encoding utf8

    if (Test-Path $lastMessageOutputPath) {
        $reviewText = (Get-Content -Path $lastMessageOutputPath -Raw).Trim()
    }
    else {
        throw "Codex did not write $lastMessageOutputPath. See $transcriptOutputPath for captured output."
    }

    if ([string]::IsNullOrWhiteSpace($reviewText)) {
        $reviewText = "Codex produced no review output."
    }

    $hasIssues = Test-ReviewHasIssues $reviewText
    $reviewText = Limit-ReviewLength $reviewText
    $hasIssuesText = if ($hasIssues) { "true" } else { "false" }

$summary = @"
# Local AI Code Review

- Range: ``$rangeLabel``
- Mode: advisory
- Codex exit code: ``$codexExitCode``
- Issues found: ``$hasIssuesText``

## Review

$reviewText
"@

    Write-ReviewSummary -Markdown $summary -OutputPath $reviewOutputPath
    Write-GitHubOutput -Name "has_issues" -Value $hasIssuesText
    Write-GitHubOutput -Name "review_output_path" -Value $reviewOutputPath
    Write-GitHubOutput -Name "transcript_path" -Value $transcriptOutputPath
    Write-GitHubOutput -Name "last_message_path" -Value $lastMessageOutputPath
    Write-GitHubOutput -Name "range_label" -Value $rangeLabel

    if (Test-CodexUsageError $rawReviewText) {
        throw "Codex review command failed due to invalid CLI usage. See $reviewOutputPath for captured output."
    }
    elseif ($codexExitCode -eq 2) {
        Write-Warning "Codex review exited with code 2; preserving advisory output and passing the workflow."
    }
    elseif ($codexExitCode -ne 0) {
        throw "Codex review failed with exit code $codexExitCode. See $reviewOutputPath for captured output."
    }

    Write-Info "Review written to $reviewOutputPath."
}
finally {
    if (-not [string]::IsNullOrWhiteSpace($baseBranch)) {
        & git branch --delete --force $baseBranch 2>$null | Out-Null
    }
}
