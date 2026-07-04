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

function Find-ExecutableOnPath {
    param(
        [string]$ExecutableName,
        [string]$PathValue
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $null
    }

    foreach ($pathEntry in ($PathValue -split ";")) {
        if ([string]::IsNullOrWhiteSpace($pathEntry)) {
            continue
        }

        $expandedPath = [Environment]::ExpandEnvironmentVariables($pathEntry.Trim())
        $candidate = Join-Path $expandedPath $ExecutableName
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Resolve-GitCommand {
    if ((-not [string]::IsNullOrWhiteSpace($env:GIT_EXE)) -and (Test-Path -LiteralPath $env:GIT_EXE)) {
        return $env:GIT_EXE
    }

    $command = Get-Command git -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    $machinePath = Get-ItemPropertyValue `
        -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" `
        -Name Path `
        -ErrorAction SilentlyContinue
    $userPath = Get-ItemPropertyValue `
        -Path "HKCU:\Environment" `
        -Name Path `
        -ErrorAction SilentlyContinue

    foreach ($pathValue in @($machinePath, $userPath)) {
        $gitOnPath = Find-ExecutableOnPath -ExecutableName "git.exe" -PathValue $pathValue
        if (-not [string]::IsNullOrWhiteSpace($gitOnPath)) {
            return $gitOnPath
        }
    }

    $candidatePaths = @(
        "${env:ProgramFiles}\Git\cmd\git.exe",
        "${env:ProgramFiles}\Git\bin\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "${env:ProgramFiles(x86)}\Git\bin\git.exe"
    )

    foreach ($candidate in $candidatePaths) {
        if ((-not [string]::IsNullOrWhiteSpace($candidate)) -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    throw "Unable to locate git.exe. Install Git for Windows or add Git to the service account PATH."
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

    & $script:GitCommand cat-file -e "$Ref^{commit}" 2>$null
    return $LASTEXITCODE -eq 0
}

function Invoke-GitOutput {
    param([string[]]$Arguments)

    $output = & $script:GitCommand @Arguments 2>$null
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
        & $script:GitCommand fetch --no-tags origin "+refs/heads/$DefaultBranchName`:refs/remotes/origin/$DefaultBranchName"
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

if (Test-ZeroSha $HeadSha) {
    Write-Info "Push deleted a ref; skipping review."
    exit 0
}

$script:GitCommand = Resolve-GitCommand
Write-Info "Using git: $script:GitCommand"

$HeadSha = Resolve-HeadSha $HeadSha

$shortHead = $HeadSha.Substring(0, [Math]::Min(12, $HeadSha.Length))
$baseSha = Resolve-BaseSha -Before $BeforeSha -DefaultBranchName $DefaultBranch
$baseBranch = $null
$createdBaseBranch = $false
$singleCommitMode = [string]::IsNullOrWhiteSpace($baseSha)
$outputRoot = if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) { (Get-Location).Path } else { $env:RUNNER_TEMP }
$reviewOutputPath = Join-Path $outputRoot "codex-review-output.md"
$transcriptOutputPath = Join-Path $outputRoot "codex-review-transcript.txt"
$lastMessageOutputPath = Join-Path $outputRoot "codex-review-last-message.md"

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
        $reviewArgs += @("--base", $baseBranch)
        $rangeLabel = "$baseSha..$HeadSha"
    }

    if ($DryRun) {
        Write-Info "Dry run: codex $($reviewArgs -join ' ')"
        Write-Info "Dry run range: $rangeLabel"
        exit 0
    }

    if (-not [string]::IsNullOrWhiteSpace($baseBranch)) {
        & $script:GitCommand branch --force $baseBranch $baseSha
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to create temporary review base branch '$baseBranch'."
        }

        $createdBaseBranch = $true
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

    $reviewText = Limit-ReviewLength $reviewText

$summary = @"
# Local AI Code Review

- Range: ``$rangeLabel``
- Mode: advisory
- Codex exit code: ``$codexExitCode``

## Review

$reviewText
"@

    Write-ReviewSummary -Markdown $summary -OutputPath $reviewOutputPath

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
    if ($createdBaseBranch) {
        & $script:GitCommand branch --delete --force $baseBranch 2>$null | Out-Null
    }
}
