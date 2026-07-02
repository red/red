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

function New-ReviewInstructions {
    @"
Review the pushed diff for potential bugs only.

Focus on correctness regressions, runtime failures, unsafe behavior, broken edge cases, data loss or corruption, security issues, resource leaks, race or lifecycle problems, and missing tests only when the missing coverage hides a realistic bug risk in changed behavior.

Do not comment on style, formatting, naming, broad refactors, or general language guidance unless it directly causes a likely bug.

For each finding, include severity, file path, nearest changed line or hunk, why it is a bug risk, and a minimal fix direction. If there are no credible bugs, say that clearly.
"@
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

if (Test-ZeroSha $HeadSha) {
    Write-Info "Push deleted a ref; skipping review."
    exit 0
}

$HeadSha = Resolve-HeadSha $HeadSha

$shortHead = $HeadSha.Substring(0, [Math]::Min(12, $HeadSha.Length))
$baseSha = Resolve-BaseSha -Before $BeforeSha -DefaultBranchName $DefaultBranch
$baseBranch = $null
$singleCommitMode = [string]::IsNullOrWhiteSpace($baseSha)
$outputRoot = if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) { (Get-Location).Path } else { $env:RUNNER_TEMP }
$reviewOutputPath = Join-Path $outputRoot "codex-review-output.md"

try {
    $reviewArgs = @("review")
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

    $reviewArgs += "-"
    $instructions = New-ReviewInstructions

    if ($DryRun) {
        Write-Info "Dry run: codex $($reviewArgs -join ' ')"
        Write-Info "Dry run range: $rangeLabel"
        exit 0
    }

    Write-Info "Running Codex review for $rangeLabel."
    $reviewLines = $instructions | & codex @reviewArgs 2>&1
    $codexExitCode = $LASTEXITCODE
    $reviewText = ($reviewLines | Out-String).TrimEnd()

    if ([string]::IsNullOrWhiteSpace($reviewText)) {
        $reviewText = "Codex produced no review output."
    }

$summary = @"
# Local AI Code Review

- Range: ``$rangeLabel``
- Mode: advisory

## Review

$reviewText
"@

    Write-ReviewSummary -Markdown $summary -OutputPath $reviewOutputPath

    if ($codexExitCode -ne 0) {
        throw "Codex review failed with exit code $codexExitCode. See $reviewOutputPath for captured output."
    }

    Write-Info "Review written to $reviewOutputPath."
}
finally {
    if (-not [string]::IsNullOrWhiteSpace($baseBranch)) {
        & git branch --delete --force $baseBranch 2>$null | Out-Null
    }
}
