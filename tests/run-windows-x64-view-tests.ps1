[CmdletBinding()]
param(
	[string]$Compiler,
	[string]$Dumpbin,
	[int]$CompileTimeoutSeconds = 240,
	[int]$RunTimeoutSeconds = 60,
	[int]$SuiteTimeoutSeconds = 900,
	[switch]$KeepArtifactsOnFailure
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'windows-x64-test-tools.ps1')
$Compiler = Resolve-RedTestCompiler $Compiler $root
$Dumpbin = Resolve-VcTool 'dumpbin' $Dumpbin
$artifactDir = Join-Path $root 'build\windows-x64-view-tests'
$executable = Join-Path $artifactDir 'view-smoke.exe'
$marker = Join-Path $artifactDir 'windows-x64-view-smoke.ok'
$suiteSource = Join-Path $artifactDir 'base-self-test-x64.red'
$suiteExecutable = Join-Path $artifactDir 'base-self-test-x64.exe'
$suiteResult = Join-Path $artifactDir 'base-self-test-x64.result'
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
		$exitCode = $process.ExitCode
		$output = (Get-Content -LiteralPath $OutputPath -Raw -ErrorAction SilentlyContinue) +
			(Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue)
		if ($null -ne $exitCode -and $exitCode -ne 0) {
			throw "$FilePath exited with $exitCode`n$output"
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
		[Parameter(Mandatory)][int]$TimeoutSeconds,
		[string]$OutputPath,
		[string]$ErrorPath
	)

	$startArgs = @{
		FilePath = $FilePath
		WorkingDirectory = $WorkingDirectory
		PassThru = $true
	}
	if ($OutputPath) { $startArgs.RedirectStandardOutput = $OutputPath }
	if ($ErrorPath) { $startArgs.RedirectStandardError = $ErrorPath }
	$process = Start-Process @startArgs
	if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
		$process.Kill($true)
		throw "$FilePath timed out after $TimeoutSeconds seconds"
	}
	$process.ExitCode
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
	if ($win32 -notmatch 'GetWindowLongPtr:\s+GET_WINDOW_LONG_PTR_SYMBOL' -or
		$win32 -notmatch 'SetWindowLongPtr:\s+SET_WINDOW_LONG_PTR_SYMBOL') {
		throw 'The logical GetWindowLongPtr/SetWindowLongPtr imports are missing'
	}
}

try {
	if (-not (Test-Path -LiteralPath $Compiler -PathType Leaf)) { throw "Compiler not found: $Compiler" }
	if (-not (Test-Path -LiteralPath $Dumpbin -PathType Leaf)) { throw "dumpbin not found: $Dumpbin" }
	Assert-WindowLongPtrSource
	New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
	Remove-Item -LiteralPath $executable,$marker -Force -ErrorAction SilentlyContinue

	$compileArgs = @(
		'/c', $Compiler, '-cqs', (Join-Path $root 'red.r'), '-r', '-d',
		'-t', 'Windows-X86-64', '-o', $executable,
		(Join-Path $root 'tests\source\view\windows-x64-minimal.red')
	)
	$compileOutput = Invoke-CheckedProcess 'cmd.exe' $compileArgs $CompileTimeoutSeconds `
		(Join-Path $artifactDir 'compile.log')
	Assert-NoCompilerWarnings $compileOutput 'Windows x86-64 View smoke'
	if ($compileOutput -notmatch 'output file\s+: .*view-smoke\.exe') {
		throw 'View executable output marker is missing'
	}
	Start-Sleep -Seconds 2

	$headers = Invoke-CheckedProcess $Dumpbin @('/headers', $executable) $RunTimeoutSeconds `
		(Join-Path $artifactDir 'headers.log')
	if ($headers -notmatch '8664 machine \(x64\)') { throw 'View executable is not x64' }
	if ($headers -notmatch '20B magic # \(PE32\+\)') { throw 'View executable is not PE32+' }
	if ($headers -notmatch 'NX compatible') { throw 'View executable lacks NX compatibility' }

	$imports = Invoke-CheckedProcess $Dumpbin @('/imports', $executable) $RunTimeoutSeconds `
		(Join-Path $artifactDir 'imports.log')
	if ($imports -notmatch 'GetWindowLongPtrW' -or $imports -notmatch 'SetWindowLongPtrW') {
		throw 'View executable does not import the x64 WindowLongPtr exports'
	}
	foreach ($name in @('USER32.dll', 'CreateWindowExW', 'DispatchMessageW')) {
		if ($imports -notmatch [regex]::Escape($name)) { throw "View import is missing: $name" }
	}

	1..3 | ForEach-Object {
		Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
		$exitCode = Invoke-BoundedGuiProcess $executable $artifactDir $RunTimeoutSeconds
		if ($exitCode -ne 0) { throw "View run $_ exited with $exitCode" }
		if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { throw "View run $_ marker file is missing" }
		if ((Get-Content -LiteralPath $marker -Raw) -ne 'X64-VIEW-OK') {
			throw "View run $_ marker content is invalid"
		}
	}

	$baseSelfTest = Get-Content -LiteralPath (Join-Path $root 'tests\source\view\base-self-test.red') -Raw
	$baseSelfTest = $baseSelfTest.Replace("`t; Needs:   'View", "`tNeeds:   View")
	$baseSelfTest = $baseSelfTest.Replace(
		'#include %../../../quick-test/quick-test.red',
		'#include %../../quick-test/quick-test.red'
	)
	$baseSelfTest = $baseSelfTest.Replace(
		'~~~start-file~~~ "base-self-test"',
		"~~~start-file~~~ `"base-self-test`"`r`n`r`nbst-user-mode: no`r`nview/no-wait [base 1x1]"
	)
	$baseSelfTest += @'

write %base-self-test-x64.result rejoin [
	qt-run-tests newline
	qt-run-asserts newline
	qt-run-passes newline
	qt-run-failures
]
quit/return either qt-run-failures = 0 [0][1]
'@
	Set-Content -LiteralPath $suiteSource -Value $baseSelfTest -Encoding UTF8

	$suiteCompileArgs = @(
		'/c', $Compiler, '-cqs', (Join-Path $root 'red.r'), '-r', '-d',
		'-t', 'Windows-X86-64', '-o', $suiteExecutable, $suiteSource
	)
	$suiteCompileOutput = Invoke-CheckedProcess 'cmd.exe' $suiteCompileArgs $CompileTimeoutSeconds `
		(Join-Path $artifactDir 'base-self-test-compile.log')
	Assert-NoCompilerWarnings $suiteCompileOutput 'Windows x86-64 View self-test'
	if ($suiteCompileOutput -notmatch 'output file\s+: .*base-self-test-x64\.exe') {
		throw 'View self-test executable output marker is missing'
	}

	Remove-Item -LiteralPath $suiteResult -Force -ErrorAction SilentlyContinue
	$suiteOutput = Join-Path $artifactDir 'base-self-test.stdout.log'
	$suiteError = Join-Path $artifactDir 'base-self-test.stderr.log'
	Remove-Item -LiteralPath $suiteOutput,$suiteError -Force -ErrorAction SilentlyContinue
	$suiteExitCode = Invoke-BoundedGuiProcess $suiteExecutable $artifactDir $SuiteTimeoutSeconds `
		$suiteOutput $suiteError
	if ($suiteExitCode -ne 0) {
		$output = (Get-Content -LiteralPath $suiteOutput -Raw -ErrorAction SilentlyContinue) +
			(Get-Content -LiteralPath $suiteError -Raw -ErrorAction SilentlyContinue)
		throw "View self-test exited with $suiteExitCode`n$output"
	}
	if (-not (Test-Path -LiteralPath $suiteResult -PathType Leaf)) {
		throw 'View self-test result file is missing'
	}
	$totals = @(Get-Content -LiteralPath $suiteResult)
	if ($totals.Count -ne 4) { throw 'View self-test result file is invalid' }
	if ([int]$totals[0] -le 0 -or [int]$totals[1] -le 0) { throw 'View self-test performed no tests' }
	if ([int]$totals[2] -ne [int]$totals[1]) { throw 'View self-test pass count does not match assertions' }
	if ([int]$totals[3] -ne 0) { throw "View self-test reported $($totals[3]) failures" }

	Write-Host "Windows x86-64 View passed: 3 smoke runs, $($totals[0]) tests, $($totals[1]) assertions."
	$succeeded = $true
}
finally {
	if ((-not $KeepArtifactsOnFailure -or $succeeded) -and (Test-Path -LiteralPath $artifactDir)) {
		Remove-Item -LiteralPath (Resolve-Path -LiteralPath $artifactDir).Path -Recurse -Force
	}
}
