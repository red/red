[CmdletBinding()]
param(
	[string]$Compiler,
	[string]$Dumpbin,
	[int]$CompileTimeoutSeconds = 180,
	[int]$RunTimeoutSeconds = 20,
	[switch]$KeepArtifactsOnFailure
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'windows-x64-test-tools.ps1')
$Compiler = Resolve-RedTestCompiler $Compiler $root
$Dumpbin = Resolve-VcTool 'dumpbin' $Dumpbin
$artifactDir = Join-Path $root 'build\windows-x64-development-tests'
$runtime = Join-Path $artifactDir 'libRedRT.dll'
$executable = Join-Path $artifactDir 'development-smoke.exe'
$succeeded = $false

function Invoke-CheckedProcess {
	param(
		[Parameter(Mandatory)][string]$FilePath,
		[string[]]$ArgumentList = @(),
		[Parameter(Mandatory)][int]$TimeoutSeconds,
		[Parameter(Mandatory)][string]$OutputPath,
		[string]$WorkingDirectory = $root
	)

	$stderr = [System.IO.Path]::GetTempFileName()
	try {
		$process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList `
			-WorkingDirectory $WorkingDirectory -NoNewWindow -PassThru `
			-RedirectStandardOutput $OutputPath -RedirectStandardError $stderr
		if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
			$process.Kill($true)
			throw "$FilePath timed out after $TimeoutSeconds seconds"
		}
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

function Assert-X64Image([string]$Path, [string]$Prefix) {
	$headers = Invoke-CheckedProcess $Dumpbin @('/headers', $Path) $RunTimeoutSeconds `
		(Join-Path $artifactDir "$Prefix-headers.log")
	if ($headers -notmatch '8664 machine \(x64\)') { throw "$Prefix is not x64" }
	if ($headers -notmatch '20B magic # \(PE32\+\)') { throw "$Prefix is not PE32+" }
	if ($headers -notmatch 'NX compatible') { throw "$Prefix lacks NX compatibility" }
}

try {
	if (-not (Test-Path -LiteralPath $Compiler -PathType Leaf)) { throw "Compiler not found: $Compiler" }
	if (-not (Test-Path -LiteralPath $Dumpbin -PathType Leaf)) { throw "dumpbin not found: $Dumpbin" }
	New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
	foreach ($file in @($runtime, $executable)) {
		Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
	}

	$compileArgs = @(
		'/c', $Compiler, '-cqs', (Join-Path $root 'red.r'), '-c', '--no-view', '-d',
		'-t', 'Windows-X86-64', '-o', $executable,
		(Join-Path $root 'tests\source\runtime\x64-red-smoke.red')
	)
	$compileOutput = Invoke-CheckedProcess 'cmd.exe' $compileArgs $CompileTimeoutSeconds `
		(Join-Path $artifactDir 'compile.log')
	if ($compileOutput -notmatch 'output file\s+: .*development-smoke\.exe') {
		throw 'Development executable output marker is missing'
	}
	if (-not (Test-Path -LiteralPath $runtime -PathType Leaf)) { throw 'libRedRT.dll was not generated' }
	if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw 'Development executable was not generated' }

	Assert-X64Image $runtime 'runtime'
	Assert-X64Image $executable 'client'

	$imports = Invoke-CheckedProcess $Dumpbin @('/imports', $executable) $RunTimeoutSeconds `
		(Join-Path $artifactDir 'client-imports.log')
	if ($imports -notmatch 'LIBREDRT\.DLL') { throw 'Client does not import libRedRT.dll' }
	foreach ($name in @('system', 'red/boot', 'red/type-check')) {
		if ($imports -notmatch [regex]::Escape($name)) { throw "Client import is missing: $name" }
	}

	$exports = Invoke-CheckedProcess $Dumpbin @('/exports', $runtime) $RunTimeoutSeconds `
		(Join-Path $artifactDir 'runtime-exports.log')
	foreach ($name in @('system', 'red/boot', 'red/get-build-date')) {
		if ($exports -notmatch "(?m)\s$([regex]::Escape($name))\s*`$") {
			throw "Runtime export is missing: $name"
		}
	}

	1..3 | ForEach-Object {
		$output = Invoke-CheckedProcess $executable @() $RunTimeoutSeconds `
			(Join-Path $artifactDir "run-$_.log") $artifactDir
		if ($output -notmatch 'X64-RED-OK') { throw "Run $_ success marker is missing" }
		if ($output -match '\*\*\* Runtime Error|FAIL:') { throw "Run $_ reported a runtime failure" }
	}

	Write-Host 'Windows x86-64 development-mode smoke passed (3 runs).'
	$succeeded = $true
}
finally {
	if ((-not $KeepArtifactsOnFailure -or $succeeded) -and (Test-Path -LiteralPath $artifactDir)) {
		Remove-Item -LiteralPath (Resolve-Path -LiteralPath $artifactDir).Path -Recurse -Force
	}
}
