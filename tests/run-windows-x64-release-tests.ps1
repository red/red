[CmdletBinding()]
param(
	[string]$Compiler = 'D:\EE\QTool\rebcmdview.exe',
	[string]$Dumpbin = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\dumpbin.exe',
	[string]$Cdb = 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe',
	[int]$Runs = 3,
	[int]$CompileTimeoutSeconds = 240,
	[int]$RunTimeoutSeconds = 30,
	[switch]$KeepArtifactsOnFailure
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $root 'tests\source\runtime\x64-red-smoke.red'
$artifactDir = Join-Path $root 'build\windows-x64-tests'
$executable = Join-Path $artifactDir 'windows-x64-red-smoke.exe'
$succeeded = $false

function Invoke-CheckedProcess {
	param(
		[Parameter(Mandatory)][string]$FilePath,
		[string[]]$ArgumentList = @(),
		[Parameter(Mandatory)][int]$TimeoutSeconds,
		[string]$OutputPath
	)

	$stdout = if ($OutputPath) { $OutputPath } else { [System.IO.Path]::GetTempFileName() }
	$stderr = [System.IO.Path]::GetTempFileName()
	try {
		$process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList `
			-NoNewWindow -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
		if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
			$process.Kill($true)
			throw "$FilePath timed out after $TimeoutSeconds seconds"
		}
	$output = (Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue) +
			(Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue)
		$output = $output -replace ([char]27 + '\[[0-9;]*m'), ''
		if ($process.ExitCode -ne 0) {
			throw "$FilePath exited with $($process.ExitCode)`n$output"
		}
		$output
	}
	finally {
		if (-not $OutputPath) { Remove-Item -LiteralPath $stdout -Force -ErrorAction SilentlyContinue }
		Remove-Item -LiteralPath $stderr -Force -ErrorAction SilentlyContinue
	}
}

function Require-Tool([string]$Path, [string]$Name) {
	if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
		throw "$Name not found: $Path"
	}
}

try {
	Require-Tool $Compiler 'Red compiler'
	Require-Tool $Dumpbin 'dumpbin'
	Require-Tool $Cdb 'cdb'
	New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null

	$compileArgs = @(
		'/c', $Compiler, '-cqs', (Join-Path $root 'red.r'), '-r', '-d',
		'-t', 'Windows-X86-64', '-o', $executable, $source
	)
	Invoke-CheckedProcess -FilePath 'cmd.exe' -ArgumentList $compileArgs `
		-TimeoutSeconds $CompileTimeoutSeconds -OutputPath (Join-Path $artifactDir 'compile.log') | Out-Null

	$headers = Invoke-CheckedProcess -FilePath $Dumpbin `
		-ArgumentList @('/headers', $executable) -TimeoutSeconds $RunTimeoutSeconds `
		-OutputPath (Join-Path $artifactDir 'headers.log')
	if ($headers -notmatch '8664 machine \(x64\)') { throw 'Generated image is not x64' }
	if ($headers -notmatch '20B magic # \(PE32\+\)') { throw 'Generated image is not PE32+' }
	if ($headers -notmatch 'Dynamic base') { throw 'Generated image is not marked dynamic-base' }
	if ($headers -notmatch 'NX compatible') { throw 'Generated image is not NX-compatible' }
	if ($headers -notmatch '(?m)^\s*[1-9A-Fa-f][0-9A-Fa-f]*\s+\[\s*[1-9A-Fa-f][0-9A-Fa-f]*\]\s+RVA \[size\] of Base Relocation Directory') {
		throw 'Generated image has no base relocations'
	}

	$imports = Invoke-CheckedProcess -FilePath $Dumpbin `
		-ArgumentList @('/imports', $executable) -TimeoutSeconds $RunTimeoutSeconds `
		-OutputPath (Join-Path $artifactDir 'imports.log')
	if ($imports -notmatch 'KERNEL32\.DLL') { throw 'KERNEL32 import table is missing' }
	if ($imports -notmatch 'MSVCRT\.DLL') { throw 'MSVCRT import table is missing' }

	$sections = Invoke-CheckedProcess -FilePath $Dumpbin `
		-ArgumentList @('/sections', $executable) -TimeoutSeconds $RunTimeoutSeconds `
		-OutputPath (Join-Path $artifactDir 'sections.log')
	if ($sections -notmatch '\.text') { throw 'Executable .text section is missing' }
	if ($sections -notmatch '\.reloc') { throw 'Relocation section is missing' }

	for ($run = 1; $run -le $Runs; $run++) {
		$output = Invoke-CheckedProcess -FilePath $executable -ArgumentList @() `
			-TimeoutSeconds $RunTimeoutSeconds
		$lines = @($output -split "`r?`n" | Where-Object { $_.Trim().Length -ne 0 })
		$markers = @($lines | Where-Object { $_.Trim() -eq 'X64-RED-OK' })
		if ($lines[-1].Trim() -ne 'X64-RED-OK' -or $markers.Count -ne 1 -or
			$output -match '\*\*\* (Runtime|Internal) Error') {
			throw "Unexpected runtime output on run $run`n$output"
		}
	}

	Write-Host "Windows x86-64 release smoke passed ($Runs runs)."
	$succeeded = $true
}
catch {
	if (Test-Path -LiteralPath $executable) {
		$cdbLog = Join-Path $artifactDir 'cdb-failure.log'
		try {
			Invoke-CheckedProcess -FilePath $Cdb -ArgumentList @('-logo', $cdbLog, '-c', '.lastevent; .ecxr; kv; r; u @rip L10; q', $executable) `
				-TimeoutSeconds ($RunTimeoutSeconds + 15) | Out-Null
		} catch { $_ | Out-File -LiteralPath (Join-Path $artifactDir 'cdb-launch-error.log') }
	}
	throw
}
finally {
	if ((-not $KeepArtifactsOnFailure -or $succeeded) -and (Test-Path -LiteralPath $artifactDir)) {
		$resolved = (Resolve-Path -LiteralPath $artifactDir).Path
		$expected = [System.IO.Path]::GetFullPath((Join-Path $root 'build\windows-x64-tests'))
		if ([StringComparer]::OrdinalIgnoreCase.Equals($resolved, $expected)) {
			Remove-Item -LiteralPath $resolved -Recurse -Force
		}
	}
}
