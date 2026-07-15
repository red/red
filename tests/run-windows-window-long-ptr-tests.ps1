[CmdletBinding()]
param(
	[string]$Compiler,
	[string]$Dumpbin,
	[int]$CompileTimeoutSeconds = 240,
	[int]$RunTimeoutSeconds = 60,
	[switch]$KeepArtifactsOnFailure
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'windows-x64-test-tools.ps1')
$Compiler = Resolve-RedTestCompiler $Compiler $root
$Dumpbin = Resolve-VcTool 'dumpbin' $Dumpbin
$artifactDir = Join-Path $root 'build\windows-window-long-ptr-tests'
$source = Join-Path $root 'tests\source\view\windows-x64-minimal.red'
$succeeded = $false

function Invoke-CheckedProcess {
	param(
		[Parameter(Mandatory)][string]$FilePath,
		[string[]]$ArgumentList = @(),
		[Parameter(Mandatory)][int]$TimeoutSeconds,
		[Parameter(Mandatory)][string]$OutputPath
	)

	$stderr = [System.IO.Path]::GetTempFileName()
	try {
		$process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList `
			-NoNewWindow -PassThru -RedirectStandardOutput $OutputPath -RedirectStandardError $stderr
		if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
			$process.Kill($true)
			throw "$FilePath timed out after $TimeoutSeconds seconds"
		}
		$process.WaitForExit()
		$process.Refresh()
		$output = (Get-Content -LiteralPath $OutputPath -Raw -ErrorAction SilentlyContinue) +
			(Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue)
		if ($process.ExitCode -ne 0) {
			throw "$FilePath exited with $($process.ExitCode)`n$output"
		}
		$output
	}
	finally {
		Remove-Item -LiteralPath $stderr -Force -ErrorAction SilentlyContinue
	}
}

function Invoke-BoundedGuiProcess {
	param(
		[Parameter(Mandatory)][string]$FilePath,
		[Parameter(Mandatory)][string]$WorkingDirectory,
		[Parameter(Mandatory)][int]$TimeoutSeconds
	)

	$process = Start-Process -FilePath $FilePath -WorkingDirectory $WorkingDirectory -PassThru
	if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
		$process.Kill($true)
		throw "$FilePath timed out after $TimeoutSeconds seconds"
	}
	if ($process.ExitCode -ne 0) {
		throw "$FilePath exited with $($process.ExitCode)"
	}
}

function Assert-NoCompilerWarnings {
	param(
		[Parameter(Mandatory)][string]$Output,
		[Parameter(Mandatory)][string]$Target
	)

	if ($Output -match '(?m)^\*\*\* Warning:') {
		throw "$Target compilation emitted warnings`n$Output"
	}
}

function Assert-WindowLongPtrSource {
	$backend = Join-Path $root 'modules\view\backends\windows'
	$files = Get-ChildItem -LiteralPath $backend -Filter '*.reds' -File
	$legacyPattern = '\b(?:GetWindowLong|SetWindowLong|get-window-long-ptr|set-window-long-ptr)\b|\bwc-offset\b|WindowLongPtrPtr'
	$unsafeNarrowingPattern = '\bas(?:-integer)?\s+(?:\(\s*)?(?:GetWindowLongPtr|SetWindowLongPtr|SendMessage)\b|\bwin-(?:long|ulong)-ptr-low32\b|\bWIN_WPARAM\b|\bas\s+win-(?:wparam|lparam|long-ptr|lresult)!\b'
	$unsafeHandleStoragePattern = '\bas-integer\s+(?:hWnd|hwnd|get-face-handle)\b|\b(?:handle|h)/value:\s+as-integer\s+hWnd\b|\bOS-make-view\s+face\s+as-integer\b'
	$violations = foreach ($file in $files) {
		Select-String -LiteralPath $file.FullName -Pattern @($legacyPattern, $unsafeNarrowingPattern, $unsafeHandleStoragePattern) -AllMatches
	}
	if ($violations) {
		throw "Legacy or narrowing window-long access remains:`n$($violations -join "`n")"
	}

	$win32 = Get-Content -LiteralPath (Join-Path $backend 'win32.reds') -Raw
	if ($win32 -notmatch 'GET_WINDOW_LONG_PTR_SYMBOL "GetWindowLongPtrW"' -or
		$win32 -notmatch 'GET_WINDOW_LONG_PTR_SYMBOL "GetWindowLongW"' -or
		$win32 -notmatch 'GetWindowLongPtr:\s+GET_WINDOW_LONG_PTR_SYMBOL' -or
		$win32 -notmatch 'SetWindowLongPtr:\s+SET_WINDOW_LONG_PTR_SYMBOL') {
		throw 'The cross-target logical WindowLongPtr import mapping is incomplete'
	}
}

try {
	if (-not (Test-Path -LiteralPath $Compiler -PathType Leaf)) { throw "Compiler not found: $Compiler" }
	if (-not (Test-Path -LiteralPath $Dumpbin -PathType Leaf)) { throw "dumpbin not found: $Dumpbin" }
	Assert-WindowLongPtrSource
	New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null

	$targets = @(
		@{ Name = 'x64'; TargetArgs = @('-t', 'Windows-X86-64'); GetImport = 'GetWindowLongPtrW'; SetImport = 'SetWindowLongPtrW' },
		@{ Name = 'x86'; TargetArgs = @(); GetImport = 'GetWindowLongW'; SetImport = 'SetWindowLongW' }
	)

	foreach ($target in $targets) {
		$targetDir = Join-Path $artifactDir $target.Name
		$executable = Join-Path $targetDir 'view-smoke.exe'
		$marker = Join-Path $targetDir 'windows-x64-view-smoke.ok'
		New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
		Remove-Item -LiteralPath $executable,$marker -Force -ErrorAction SilentlyContinue

		$compileArgs = @('/c', $Compiler, '-cqs', (Join-Path $root 'red.r'), '-r', '-d') +
			$target.TargetArgs + @('-o', $executable, $source)
		$compileOutput = Invoke-CheckedProcess 'cmd.exe' $compileArgs $CompileTimeoutSeconds `
			(Join-Path $targetDir 'compile.log')
		Assert-NoCompilerWarnings $compileOutput $target.Name
		if ($compileOutput -notmatch 'output file\s+: .*view-smoke\.exe') {
			throw "$($target.Name) compiler output marker is missing"
		}
		Start-Sleep -Seconds 2

		$imports = Invoke-CheckedProcess $Dumpbin @('/imports', $executable) $RunTimeoutSeconds `
			(Join-Path $targetDir 'imports.log')
		if ($imports -notmatch [regex]::Escape($target.GetImport) -or
			$imports -notmatch [regex]::Escape($target.SetImport)) {
			throw "$($target.Name) WindowLongPtr import mapping is incorrect"
		}
		if ($target.Name -eq 'x86' -and $imports -match 'WindowLongPtrW') {
			throw 'x86 executable imports unavailable WindowLongPtrW exports'
		}

		Invoke-BoundedGuiProcess $executable $targetDir $RunTimeoutSeconds
		if (-not (Test-Path -LiteralPath $marker -PathType Leaf) -or
			(Get-Content -LiteralPath $marker -Raw) -ne 'X64-VIEW-OK') {
			throw "$($target.Name) View smoke marker is missing"
		}
	}

	$succeeded = $true
	Write-Host 'Windows WindowLongPtr passed: x64 Ptr exports, x86 Long aliases, slot canaries, and View smoke.'
}
finally {
	if ($succeeded -or -not $KeepArtifactsOnFailure) {
		Remove-Item -LiteralPath $artifactDir -Recurse -Force -ErrorAction SilentlyContinue
	}
}
