[CmdletBinding()]
param(
	[string]$Compiler = 'D:\EE\QTool\rebcmdview.exe',
	[int]$CompileTimeoutSeconds = 120,
	[int]$RunTimeoutSeconds = 20,
	[switch]$KeepArtifactsOnFailure
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$sourceDir = Join-Path $root 'system\tests\source\units'
$artifactDir = Join-Path $root 'build\windows-x64-abi-tests'
$tests = @(
	'x64-function-pointer-smoke', 'x64-mixed-arg-smoke', 'x64-float-arg-smoke',
	'x64-hidden-return-smoke', 'x64-variadic-smoke', 'x64-register-arg-smoke',
	'x64-stack-arg-smoke', 'x64-struct-by-value-smoke', 'x64-union-by-value-smoke'
)
$succeeded = $false

function Invoke-CheckedProcess {
	param([string]$FilePath, [string[]]$ArgumentList = @(), [int]$TimeoutSeconds, [string]$OutputPath)
	$stdout = if ($OutputPath) { $OutputPath } else { [System.IO.Path]::GetTempFileName() }
	$stderr = [System.IO.Path]::GetTempFileName()
	try {
		$p = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -NoNewWindow -PassThru `
			-RedirectStandardOutput $stdout -RedirectStandardError $stderr
		if (-not $p.WaitForExit($TimeoutSeconds * 1000)) { $p.Kill($true); throw "$FilePath timed out" }
		$out = (Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue) +
			(Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue)
		if ($p.ExitCode -ne 0) { throw "$FilePath exited with $($p.ExitCode)`n$out" }
		$out
	}
	finally {
		if (-not $OutputPath) { Remove-Item -LiteralPath $stdout -Force -ErrorAction SilentlyContinue }
		Remove-Item -LiteralPath $stderr -Force -ErrorAction SilentlyContinue
	}
}

try {
	if (-not (Test-Path -LiteralPath $Compiler -PathType Leaf)) { throw "Red compiler not found: $Compiler" }
	New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
	$results = foreach ($name in $tests) {
		$source = Join-Path $sourceDir "$name.reds"
		$exe = Join-Path $artifactDir "$name.exe"
		$log = Join-Path $artifactDir "$name-compile.log"
		$args = @('/c', $Compiler, '-cqs', (Join-Path $root 'red.r'), '-r', '-d', '-t', 'Windows-X86-64', '-o', $exe, $source)
		Invoke-CheckedProcess 'cmd.exe' $args $CompileTimeoutSeconds $log | Out-Null
		$output = Invoke-CheckedProcess $exe @() $RunTimeoutSeconds
		$text = if ($null -eq $output) { '' } else { ([string]$output).Trim() }
		[pscustomobject]@{ Name = $name; ExitCode = 0; Output = $text }
	}
	$results | Format-Table -AutoSize | Out-Host
	Write-Host "Windows x86-64 ABI smoke passed ($($tests.Count) tests)."
	$succeeded = $true
}
finally {
	if ((-not $KeepArtifactsOnFailure -or $succeeded) -and (Test-Path -LiteralPath $artifactDir)) {
		Remove-Item -LiteralPath (Resolve-Path -LiteralPath $artifactDir).Path -Recurse -Force
	}
}
