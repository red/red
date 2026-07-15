[CmdletBinding()]
param(
	[string]$Compiler,
	[string]$Dumpbin,
	[int]$CompileTimeoutSeconds = 120,
	[int]$RunTimeoutSeconds = 20,
	[switch]$KeepArtifactsOnFailure
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'windows-x64-test-tools.ps1')
$Compiler = Resolve-RedTestCompiler $Compiler $root
$Dumpbin = Resolve-VcTool 'dumpbin' $Dumpbin
$artifactDir = Join-Path $root 'build\windows-x64-dll-tests'
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

function Compile-Dll([string]$Source, [string]$Output, [string]$Log) {
	$args = @(
		'/c', $Compiler, '-cqs', (Join-Path $root 'red.r'), '-dlib', '-d',
		'-t', 'Windows-X86-64-DLL', '-o', $Output, $Source
	)
	Invoke-CheckedProcess 'cmd.exe' $args $CompileTimeoutSeconds $Log | Out-Null
}

function Check-Image([string]$Dll, [string[]]$Exports, [string]$Prefix) {
	$headers = Invoke-CheckedProcess $Dumpbin @('/headers', $Dll) $RunTimeoutSeconds `
		(Join-Path $artifactDir "$Prefix-headers.log")
	if ($headers -notmatch '8664 machine \(x64\)') { throw "$Prefix is not x64" }
	if ($headers -notmatch '20B magic # \(PE32\+\)') { throw "$Prefix is not PE32+" }
	if ($headers -notmatch 'High Entropy Virtual Addresses') { throw "$Prefix lacks high-entropy VA" }
	if ($headers -notmatch 'Dynamic base') { throw "$Prefix lacks dynamic-base" }
	if ($headers -notmatch 'NX compatible') { throw "$Prefix lacks NX compatibility" }
	if ($headers -notmatch '(?m)^\s*1[0-9A-Fa-f]{8}\s+image base') {
		throw "$Prefix does not have a preferred image base above 4 GB"
	}
	if ($headers -notmatch '(?m)^\s*[1-9A-Fa-f][0-9A-Fa-f]*\s+\[\s*[1-9A-Fa-f][0-9A-Fa-f]*\]\s+RVA \[size\] of Base Relocation Directory') {
		throw "$Prefix has no base relocations"
	}

	$exportText = Invoke-CheckedProcess $Dumpbin @('/exports', $Dll) $RunTimeoutSeconds `
		(Join-Path $artifactDir "$Prefix-exports.log")
	foreach ($name in $Exports) {
		$escaped = [regex]::Escape($name)
		if ($exportText -notmatch "(?m)\s$escaped\s*`$") { throw "$Prefix export is missing: $name" }
	}

	$relocs = Invoke-CheckedProcess $Dumpbin @('/relocations', $Dll) $RunTimeoutSeconds `
		(Join-Path $artifactDir "$Prefix-relocations.log")
	if ($relocs -notmatch 'DIR64') { throw "$Prefix has no DIR64 relocation" }
}

try {
	if (-not (Test-Path -LiteralPath $Compiler -PathType Leaf)) { throw "Compiler not found: $Compiler" }
	if (-not (Test-Path -LiteralPath $Dumpbin -PathType Leaf)) { throw "dumpbin not found: $Dumpbin" }
	New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null

	$minimal = Join-Path $artifactDir 'minimal.dll'
	$lifecycle = Join-Path $artifactDir 'lifecycle.dll'
	Compile-Dll (Join-Path $root 'system\tests\source\units\libtest-dll1.reds') $minimal `
		(Join-Path $artifactDir 'minimal-compile.log')
	Compile-Dll (Join-Path $root 'system\tests\shared-lib.reds') $lifecycle `
		(Join-Path $artifactDir 'lifecycle-compile.log')
	Check-Image $minimal @('add-one', 'i') 'minimal'
	Check-Image $lifecycle @('foo', 'bar', 'i') 'lifecycle'

	$loader = Join-Path $artifactDir 'loader.ps1'
	$loaderSource = @'
param([string]$Dll, [string]$Function, [int]$Expected, [switch]$Lifecycle)
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @"
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
public static class RedDllLoader {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    static extern IntPtr LoadLibraryW(string path);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr GetProcAddress(IntPtr module, string name);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool FreeLibrary(IntPtr module);
    [UnmanagedFunctionPointer(CallingConvention.Winapi)] delegate int UnaryInt(int value);
    public static int Run(string path, string name) {
        IntPtr module = LoadLibraryW(path);
        if (module == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        Console.WriteLine("MODULE=0x" + module.ToInt64().ToString("X"));
        if ((ulong)module.ToInt64() <= 0xFFFFFFFFUL) throw new Exception("DLL loaded below 4 GB");
        IntPtr proc = GetProcAddress(module, name);
        if (proc == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        int actual = ((UnaryInt)Marshal.GetDelegateForFunctionPointer(proc, typeof(UnaryInt)))(41);
        Console.WriteLine("RESULT=" + actual);
        IntPtr data = GetProcAddress(module, "i");
        if (data == IntPtr.Zero || Marshal.ReadInt32(data) != 56) throw new Exception("Exported data mismatch");
        if (!FreeLibrary(module)) throw new Win32Exception(Marshal.GetLastWin32Error());
        Console.WriteLine("UNLOADED");
        return actual;
    }
}
"@
$actual = [RedDllLoader]::Run($Dll, $Function)
if ($actual -ne $Expected) { throw "Expected $Expected, got $actual" }
'@
	Set-Content -LiteralPath $loader -Value $loaderSource -Encoding ASCII

	$minimalRun = Invoke-CheckedProcess (Get-Process -Id $PID).Path `
		@('-NoProfile', '-File', $loader, '-Dll', $minimal, '-Function', 'add-one', '-Expected', '42') `
		$RunTimeoutSeconds (Join-Path $artifactDir 'minimal-run.log')
	$lifecycleRun = Invoke-CheckedProcess (Get-Process -Id $PID).Path `
		@('-NoProfile', '-File', $loader, '-Dll', $lifecycle, '-Function', 'foo', '-Expected', '42', '-Lifecycle') `
		$RunTimeoutSeconds (Join-Path $artifactDir 'lifecycle-run.log')
	foreach ($output in @($minimalRun, $lifecycleRun)) {
		if ($output -notmatch 'MODULE=0x1[0-9A-F]+') { throw 'High-address load marker is missing' }
		if ($output -notmatch 'RESULT=42') { throw 'Export call marker is missing' }
		if ($output -notmatch 'UNLOADED') { throw 'Unload marker is missing' }
	}
	if ($lifecycleRun -notmatch 'on-load executed' -or $lifecycleRun -notmatch 'on-unload executed') {
		throw 'DLL lifecycle callbacks did not run'
	}

	Write-Host 'Windows x86-64 DLL smoke passed (2 libraries).'
	$succeeded = $true
}
finally {
	if ((-not $KeepArtifactsOnFailure -or $succeeded) -and (Test-Path -LiteralPath $artifactDir)) {
		Remove-Item -LiteralPath (Resolve-Path -LiteralPath $artifactDir).Path -Recurse -Force
	}
}
