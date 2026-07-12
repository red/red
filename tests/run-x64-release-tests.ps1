[CmdletBinding()]
param(
	[string]$Compiler = 'D:\EE\QTool\rebcmdview.exe',
	[int]$Runs = 5,
	[int]$CompileTimeoutSeconds = 180,
	[int]$RunTimeoutSeconds = 20,
	[switch]$KeepArtifactsOnFailure
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $root 'tests\source\runtime\x64-red-smoke.red'
$artifactDir = Join-Path $root 'build\x64-release-tests'
$executable = Join-Path $artifactDir 'x64-red-smoke'
$succeeded = $false

function Invoke-CheckedProcess {
	param(
		[Parameter(Mandatory)][string]$FilePath,
		[Parameter(Mandatory)][string[]]$ArgumentList,
		[Parameter(Mandatory)][int]$TimeoutSeconds
	)

	$stdout = [System.IO.Path]::GetTempFileName()
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
		if ($process.ExitCode -ne 0) {
			throw "$FilePath exited with $($process.ExitCode)`n$output"
		}
		$output
	}
	finally {
		Remove-Item -LiteralPath $stdout,$stderr -Force -ErrorAction SilentlyContinue
	}
}

try {
	New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
	$compileArgs = @(
		'/c', $Compiler, '-cqs', (Join-Path $root 'red.r'), '-r', '-d',
		'-t', 'Linux-X86-64', '-o', $executable, $source
	)
	$compileOutput = Invoke-CheckedProcess -FilePath 'cmd.exe' -ArgumentList $compileArgs `
		-TimeoutSeconds $CompileTimeoutSeconds

	if ($executable -notmatch '^([A-Za-z]):\\(.*)$') {
		throw "Unable to translate the generated executable path for WSL: $executable"
	}
	$drive = $Matches[1].ToLowerInvariant()
	$relative = $Matches[2].Replace('\', '/')
	$linuxExecutable = "/mnt/$drive/$relative"

	$header = Invoke-CheckedProcess -FilePath 'wsl.exe' `
		-ArgumentList @('readelf', '-hW', $linuxExecutable) -TimeoutSeconds $RunTimeoutSeconds
	if ($header -notmatch 'Class:\s+ELF64') { throw 'Generated executable is not ELF64' }
	if ($header -notmatch 'Type:\s+DYN') { throw 'Generated executable is not ET_DYN/PIE' }

	$dynamic = Invoke-CheckedProcess -FilePath 'wsl.exe' `
		-ArgumentList @('readelf', '-dW', $linuxExecutable) -TimeoutSeconds $RunTimeoutSeconds
	if ($dynamic -match 'TEXTREL') { throw 'Generated executable contains TEXTREL' }

	$sections = Invoke-CheckedProcess -FilePath 'wsl.exe' `
		-ArgumentList @('readelf', '-SW', $linuxExecutable) -TimeoutSeconds $RunTimeoutSeconds
	$executableRanges = foreach ($line in $sections -split "`r?`n") {
		if ($line -match '^\s*\[\s*\d+\]\s+\S+\s+\S+\s+([0-9A-Fa-f]+)\s+[0-9A-Fa-f]+\s+([0-9A-Fa-f]+)\s+\S+\s+([A-Z]+)') {
			if ($Matches[3] -like '*X*') {
				$start = [Convert]::ToUInt64($Matches[1], 16)
				[pscustomobject]@{ Start = $start; End = $start + [Convert]::ToUInt64($Matches[2], 16) }
			}
		}
	}
	$relocations = Invoke-CheckedProcess -FilePath 'wsl.exe' `
		-ArgumentList @('readelf', '-rW', $linuxExecutable) -TimeoutSeconds $RunTimeoutSeconds
	foreach ($line in $relocations -split "`r?`n") {
		if ($line -match '^([0-9A-Fa-f]{8,16})\s') {
			$offset = [Convert]::ToUInt64($Matches[1], 16)
			foreach ($range in $executableRanges) {
				if ($offset -ge $range.Start -and $offset -lt $range.End) {
					throw ('Dynamic relocation targets executable section at 0x{0:X}' -f $offset)
				}
			}
		}
	}

	$aslr = (Invoke-CheckedProcess -FilePath 'wsl.exe' `
		-ArgumentList @('cat', '/proc/sys/kernel/randomize_va_space') -TimeoutSeconds $RunTimeoutSeconds).Trim()
	if ($aslr -eq '0') { throw 'ASLR is disabled in WSL' }

	for ($run = 1; $run -le $Runs; $run++) {
		$output = Invoke-CheckedProcess -FilePath 'wsl.exe' `
			-ArgumentList @('timeout', "${RunTimeoutSeconds}s", $linuxExecutable) `
			-TimeoutSeconds ($RunTimeoutSeconds + 5)
		$runtimeLines = @($output -split "`r?`n" | Where-Object { $_.Trim().Length -ne 0 })
		$successMarkers = @($runtimeLines | Where-Object { $_.Trim() -eq 'X64-RED-OK' })
		if ($runtimeLines[-1].Trim() -ne 'X64-RED-OK' -or $successMarkers.Count -ne 1 -or
			$output -match '\*\*\* (Runtime|Internal) Error') {
			throw "Unexpected runtime output on run $run`n$output"
		}
	}

	Write-Host "Linux x86-64 release smoke passed ($Runs runs, ASLR=$aslr)."
	$succeeded = $true
}
finally {
	if ((-not $KeepArtifactsOnFailure -or $succeeded) -and (Test-Path -LiteralPath $artifactDir)) {
		$resolved = (Resolve-Path -LiteralPath $artifactDir).Path
		$expected = [System.IO.Path]::GetFullPath((Join-Path $root 'build\x64-release-tests'))
		if ([StringComparer]::OrdinalIgnoreCase.Equals($resolved, $expected)) {
			Remove-Item -LiteralPath $resolved -Recurse -Force
		}
	}
}
