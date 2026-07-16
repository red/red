[CmdletBinding()]
param(
	[string]$Compiler = 'D:\EE\QTool\rebcmdview.exe',
	[string]$Remote = 'armbian',
	[int]$BuildTimeoutSeconds = 600,
	[int]$RunTimeoutSeconds = 600,
	[switch]$KeepArtifactsOnFailure
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'windows-x64-test-tools.ps1')
$Compiler = Resolve-RedTestCompiler $Compiler $root
$builder = Join-Path $root 'system\tests\build-arm-tests.r'
$packageRoot = Join-Path $root 'quick-test\runnable'
$packageDir = Join-Path $packageRoot 'arm-tests\system'
$remoteDir = $null
$createdPackageRoot = $false
$succeeded = $false

function Invoke-CheckedProcess {
	param(
		[Parameter(Mandatory)][string]$FilePath,
		[string[]]$ArgumentList = @(),
		[Parameter(Mandatory)][int]$TimeoutSeconds,
		[string]$WorkingDirectory
	)

	$stdout = [System.IO.Path]::GetTempFileName()
	$stderr = [System.IO.Path]::GetTempFileName()
	try {
		$start = @{
			FilePath = $FilePath
			ArgumentList = $ArgumentList
			NoNewWindow = $true
			PassThru = $true
			RedirectStandardOutput = $stdout
			RedirectStandardError = $stderr
		}
		if ($WorkingDirectory) { $start.WorkingDirectory = $WorkingDirectory }
		$process = Start-Process @start
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

function Remove-ExactDirectory {
	param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Expected)

	if (Test-Path -LiteralPath $Path) {
		$resolved = (Resolve-Path -LiteralPath $Path).Path
		$expectedPath = [System.IO.Path]::GetFullPath($Expected)
		if (-not [StringComparer]::OrdinalIgnoreCase.Equals($resolved, $expectedPath)) {
			throw "Refusing to remove unexpected path: $resolved"
		}
		Remove-Item -LiteralPath $resolved -Recurse -Force
	}
}

try {
	if (Test-Path -LiteralPath $packageRoot) {
		throw "ARM test package directory already exists: $packageRoot"
	}
	$createdPackageRoot = $true

	$buildArgs = @('/c', $Compiler, '-cqs', $builder, '-t', 'Linux-ARM64')
	$buildOutput = Invoke-CheckedProcess -FilePath 'cmd.exe' -ArgumentList $buildArgs `
		-TimeoutSeconds $BuildTimeoutSeconds -WorkingDirectory $root
	if ($buildOutput -notmatch 'Red/System ARM tests built in') {
		throw "ARM64 package builder did not report completion`n$buildOutput"
	}

	if (-not (Test-Path -LiteralPath $packageDir -PathType Container)) {
		throw "ARM64 test package was not created: $packageDir"
	}
	$packageFiles = @(Get-ChildItem -LiteralPath $packageDir -File)
	$excluded = @(
		'run-all.sh', 'validate-arm64-elf.sh', 'libtest-dll1.so', 'libtest-dll2.so',
		'libstructlib.so', 'structlib.c'
	)
	$expectedTests = @($packageFiles | Where-Object { $_.Name -notin $excluded }).Count
	$expectedSmokes = @(Get-ChildItem -LiteralPath (Join-Path $root 'system\tests\source\units') `
		-Filter 'arm64-*.reds' -File).Count + 1 # generated long-branch smoke
	if ($expectedSmokes -eq 0 -or $expectedTests -lt $expectedSmokes) {
		throw "Invalid package counts: tests=$expectedTests smokes=$expectedSmokes"
	}

	$ssh = (Get-Command 'ssh.exe' -ErrorAction Stop).Source
	$scp = (Get-Command 'scp.exe' -ErrorAction Stop).Source
	$remoteOutput = Invoke-CheckedProcess -FilePath $ssh `
		-ArgumentList @($Remote, 'mktemp -d /tmp/red-arm64-system-tests.XXXXXX') `
		-TimeoutSeconds 30
	$remoteDir = @($remoteOutput -split "`r?`n" | Where-Object { $_ })[-1].Trim()
	if ($remoteDir -notmatch '^/tmp/red-arm64-system-tests\.[A-Za-z0-9]+$') {
		throw "Unexpected remote test directory: $remoteDir"
	}

	$copyArgs = @($packageFiles.FullName) + "${Remote}:$remoteDir/"
	Invoke-CheckedProcess -FilePath $scp -ArgumentList $copyArgs -TimeoutSeconds 180 | Out-Null

	$validationOutput = Invoke-CheckedProcess -FilePath $ssh `
		-ArgumentList @(
			$Remote,
			"cd $remoteDir && sh ./validate-arm64-elf.sh ./array-test ./libtest-dll1.so"
		) -TimeoutSeconds 30
	if ($validationOutput -notmatch 'ARM64 ELF validation passed:') {
		throw "ARM64 ELF validator did not report success`n$validationOutput"
	}

	$runOutput = Invoke-CheckedProcess -FilePath $ssh `
		-ArgumentList @($Remote, "cd $remoteDir && sh ./run-all.sh") `
		-TimeoutSeconds $RunTimeoutSeconds
	$marker = "Summary: $expectedTests/$expectedTests tests passed"
	if ($runOutput -notmatch [regex]::Escape($marker)) {
		throw "ARM64 runner did not emit the expected summary: $marker`n$runOutput"
	}

	Write-Host $marker
	Write-Host "ARM64 release package passed on $Remote ($expectedSmokes backend smokes)."
	$succeeded = $true
}
finally {
	if ($remoteDir -and (-not $KeepArtifactsOnFailure -or $succeeded)) {
		try {
			$sshCommand = Get-Command 'ssh.exe' -ErrorAction SilentlyContinue
			if ($sshCommand -and $remoteDir -match '^/tmp/red-arm64-system-tests\.[A-Za-z0-9]+$') {
				Invoke-CheckedProcess -FilePath $sshCommand.Source `
					-ArgumentList @($Remote, "rm -rf -- $remoteDir") -TimeoutSeconds 30 | Out-Null
			}
		}
		catch { Write-Warning "Failed to remove remote test directory ${Remote}:${remoteDir}: $_" }
	}
	if ($createdPackageRoot -and (-not $KeepArtifactsOnFailure -or $succeeded)) {
		Remove-ExactDirectory -Path $packageRoot -Expected $packageRoot
	}
}
