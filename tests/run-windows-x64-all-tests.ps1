[CmdletBinding()]
param(
	[string]$Compiler,
	[string]$Dumpbin,
	[string]$Cdb,
	[string]$VcVars64,
	[ValidateSet('Prepare', 'Native')][string]$Phase = 'Prepare',
	[int]$CompileTimeoutSeconds = 300,
	[int]$RunTimeoutSeconds = 60,
	[switch]$KeepArtifactsOnFailure
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'windows-x64-test-tools.ps1')

$Compiler = Resolve-RedTestCompiler $Compiler $root
$Dumpbin = Resolve-VcTool 'dumpbin' $Dumpbin
$artifactDir = Join-Path $root 'build\windows-x64-all-tests'
$dependencyDir = Join-Path $artifactDir 'dependencies'
$succeeded = $false

function Invoke-CheckedProcess {
	param(
		[Parameter(Mandatory)][string]$FilePath,
		[string[]]$ArgumentList = @(),
		[Parameter(Mandatory)][int]$TimeoutSeconds,
		[Parameter(Mandatory)][string]$OutputPath,
		[string]$WorkingDirectory = $root
	)

	$stderr = [IO.Path]::GetTempFileName()
	try {
		$process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList `
			-WorkingDirectory $WorkingDirectory -NoNewWindow -PassThru `
			-RedirectStandardOutput $OutputPath -RedirectStandardError $stderr
		if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
			$process.Kill($true)
			throw "$FilePath timed out after $TimeoutSeconds seconds"
		}
		$process.WaitForExit()
		$process.Refresh()
		$output = (Get-Content -LiteralPath $OutputPath -Raw -ErrorAction SilentlyContinue) +
			(Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue)
		if ($process.ExitCode -ne 0) { throw "$FilePath exited with $($process.ExitCode)`n$output" }
		$output
	}
	finally {
		Remove-Item -LiteralPath $stderr -Force -ErrorAction SilentlyContinue
	}
}

function Assert-X64Image {
	param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)

	$log = Join-Path $artifactDir "$Label-headers.log"
	$headers = Invoke-CheckedProcess $Dumpbin @('/headers', $Path) $RunTimeoutSeconds $log
	if ($headers -notmatch '8664 machine \(x64\)') { throw "$Label is not an x64 image" }
	if ($headers -notmatch '20B magic # \(PE32\+\)') { throw "$Label is not PE32+" }
}

function Invoke-PreparePhase {
	New-Item -ItemType Directory -Path $dependencyDir -Force | Out-Null
	$vcvars = Resolve-VcVars64 $VcVars64
	$structSource = Join-Path $root 'system\tests\source\units\libs\structlib.c'
	$structDll = Join-Path $dependencyDir 'structlib.dll'
	$buildCmd = Join-Path $artifactDir 'build-structlib.cmd'
	@(
		'@echo off',
		"call `"$vcvars`" >nul",
		'if errorlevel 1 exit /b %errorlevel%',
		"cl.exe /nologo /LD /O2 /Fe:`"$structDll`" `"$structSource`""
	) | Set-Content -LiteralPath $buildCmd -Encoding ASCII
	Invoke-CheckedProcess 'cmd.exe' @('/d', '/s', '/c', "`"$buildCmd`"") `
		$CompileTimeoutSeconds (Join-Path $artifactDir 'structlib-build.log') $dependencyDir | Out-Null
	if (-not (Test-Path -LiteralPath $structDll -PathType Leaf)) { throw 'x64 structlib.dll was not generated' }
	Assert-X64Image $structDll 'structlib'

	$canarySource = Join-Path $root 'tests\source\runtime\windows-x64-runner-canary.reds'
	$canaryExe = Join-Path $artifactDir 'windows-x64-runner-canary.exe'
	$compileArgs = @(
		'/c', $Compiler, '-cqs', (Join-Path $root 'red.r'), '-r', '-d',
		'-t', 'Windows-X86-64', '-o', $canaryExe, $canarySource
	)
	$compileOutput = Invoke-CheckedProcess 'cmd.exe' $compileArgs $CompileTimeoutSeconds `
		(Join-Path $artifactDir 'canary-compile.log')
	if ($compileOutput -match '(?m)^\*\*\* Warning:') { throw "x64 canary compilation emitted warnings`n$compileOutput" }
	if (-not (Test-Path -LiteralPath $canaryExe -PathType Leaf)) { throw 'x64 runner canary was not generated' }
	Assert-X64Image $canaryExe 'canary'
	Invoke-CheckedProcess $canaryExe @() $RunTimeoutSeconds `
		(Join-Path $artifactDir 'canary-run.log') | Out-Null

	[ordered]@{
		compiler = $Compiler
		dumpbin = $Dumpbin
		vcvars64 = $vcvars
		cdb = Resolve-Cdb $Cdb
		executableTarget = 'Windows-X86-64'
		libraryTarget = 'Windows-X86-64-DLL'
	} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $artifactDir 'tools.json') -Encoding ASCII
	Write-Host "Windows x86-64 test preparation passed: PE32+ canary and $structDll"
}

function Invoke-TestScript {
	param(
		[Parameter(Mandatory)][string]$Name,
		[Parameter(Mandatory)][string]$Path,
		[Parameter(Mandatory)][hashtable]$Arguments
	)

	$log = Join-Path $artifactDir "$Name.log"
	try {
		& $Path @Arguments 2>&1 | Tee-Object -FilePath $log
	}
	catch {
		$_ | Out-File -LiteralPath $log -Append
		throw
	}
}

function Invoke-NativePhase {
	if (-not (Test-Path -LiteralPath $dependencyDir -PathType Container)) {
		throw 'x64 test dependencies are missing; run the Prepare phase first'
	}
	$cdbPath = Resolve-Cdb $Cdb
	$common = @{ Compiler = $Compiler }
	if ($KeepArtifactsOnFailure) { $common.KeepArtifactsOnFailure = $true }
	$withDumpbin = $common.Clone()
	$withDumpbin.Dumpbin = $Dumpbin

	Invoke-TestScript 'abi' (Join-Path $PSScriptRoot 'run-windows-x64-abi-tests.ps1') $common
	$release = $withDumpbin.Clone()
	if ($cdbPath) { $release.Cdb = $cdbPath }
	Invoke-TestScript 'release' (Join-Path $PSScriptRoot 'run-windows-x64-release-tests.ps1') $release
	Invoke-TestScript 'development' (Join-Path $PSScriptRoot 'run-windows-x64-development-tests.ps1') $withDumpbin
	Invoke-TestScript 'dll' (Join-Path $PSScriptRoot 'run-windows-x64-dll-tests.ps1') $withDumpbin
	Invoke-TestScript 'window-long-ptr' (Join-Path $PSScriptRoot 'run-windows-window-long-ptr-tests.ps1') $withDumpbin
	Invoke-TestScript 'view' (Join-Path $PSScriptRoot 'run-windows-x64-view-tests.ps1') $withDumpbin
	Write-Host 'Windows x86-64 native, runtime, DLL, WindowLongPtr, and View phases passed.'
}

try {
	New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
	if ($Phase -eq 'Prepare') {
		Invoke-PreparePhase
	}
	else {
		Invoke-NativePhase
	}
	$succeeded = $true
}
finally {
	if ($Phase -eq 'Native' -and $succeeded -and (Test-Path -LiteralPath $artifactDir)) {
		Remove-Item -LiteralPath (Resolve-Path -LiteralPath $artifactDir).Path -Recurse -Force
	}
}
