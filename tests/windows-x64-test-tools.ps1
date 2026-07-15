function Resolve-RedTestCompiler {
	param(
		[string]$Compiler,
		[Parameter(Mandatory)][string]$Root
	)

	$candidates = @(
		$Compiler,
		$env:RED_TEST_COMPILER,
		(Join-Path $Root 'rebview.exe'),
		(Join-Path $Root 'rebcmdview.exe')
	) | Where-Object { $_ }
	foreach ($candidate in $candidates) {
		if (Test-Path -LiteralPath $candidate -PathType Leaf) {
			return (Resolve-Path -LiteralPath $candidate).Path
		}
	}
	foreach ($name in @('rebview.exe', 'rebcmdview.exe')) {
		$command = Get-Command $name -ErrorAction SilentlyContinue
		if ($command) { return $command.Source }
	}
	throw 'Red compiler host not found; pass -Compiler or set RED_TEST_COMPILER'
}

function Resolve-VsWhere {
	$command = Get-Command 'vswhere.exe' -ErrorAction SilentlyContinue
	if ($command) { return $command.Source }
	$path = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
	if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
	throw 'vswhere.exe not found; install Visual Studio Build Tools with the x64 C++ toolchain'
}

function Resolve-VcTool {
	param(
		[Parameter(Mandatory)][string]$Name,
		[string]$Path
	)

	if ($Path) {
		if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Name not found: $Path" }
		return (Resolve-Path -LiteralPath $Path).Path
	}
	$environmentName = "RED_TEST_$($Name.ToUpperInvariant())"
	$environmentPath = [Environment]::GetEnvironmentVariable($environmentName)
	if ($environmentPath) {
		if (-not (Test-Path -LiteralPath $environmentPath -PathType Leaf)) {
			throw "$environmentName does not name a file: $environmentPath"
		}
		return (Resolve-Path -LiteralPath $environmentPath).Path
	}
	$command = Get-Command "$Name.exe" -ErrorAction SilentlyContinue
	if ($command) { return $command.Source }

	$vswhere = Resolve-VsWhere
	$matches = @(& $vswhere -latest -products * `
		-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
		-find "VC\Tools\MSVC\**\bin\Hostx64\x64\$Name.exe")
	$match = $matches | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
	if ($match) { return (Resolve-Path -LiteralPath $match).Path }
	throw "$Name.exe was not found in the latest Visual Studio x64 C++ toolchain"
}

function Resolve-VcVars64 {
	param([string]$Path)

	if ($Path) {
		if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "vcvars64.bat not found: $Path" }
		return (Resolve-Path -LiteralPath $Path).Path
	}
	if ($env:RED_TEST_VCVARS64) {
		if (-not (Test-Path -LiteralPath $env:RED_TEST_VCVARS64 -PathType Leaf)) {
			throw "RED_TEST_VCVARS64 does not name a file: $env:RED_TEST_VCVARS64"
		}
		return (Resolve-Path -LiteralPath $env:RED_TEST_VCVARS64).Path
	}
	$vswhere = Resolve-VsWhere
	$installationPath = & $vswhere -latest -products * `
		-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
		-property installationPath
	if (-not $installationPath) { throw 'Visual Studio x64 C++ installation not found' }
	$vcvars = Join-Path ($installationPath | Select-Object -First 1) 'VC\Auxiliary\Build\vcvars64.bat'
	if (-not (Test-Path -LiteralPath $vcvars -PathType Leaf)) { throw "vcvars64.bat not found: $vcvars" }
	(Resolve-Path -LiteralPath $vcvars).Path
}

function Resolve-Cdb {
	param([string]$Path)

	if ($Path) {
		if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "cdb.exe not found: $Path" }
		return (Resolve-Path -LiteralPath $Path).Path
	}
	if ($env:RED_TEST_CDB) {
		if (-not (Test-Path -LiteralPath $env:RED_TEST_CDB -PathType Leaf)) {
			throw "RED_TEST_CDB does not name a file: $env:RED_TEST_CDB"
		}
		return (Resolve-Path -LiteralPath $env:RED_TEST_CDB).Path
	}
	$command = Get-Command 'cdb.exe' -ErrorAction SilentlyContinue
	if ($command) { return $command.Source }
	$kitsRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\Debuggers\x64\cdb.exe'
	if (Test-Path -LiteralPath $kitsRoot -PathType Leaf) { return $kitsRoot }
	$null
}
