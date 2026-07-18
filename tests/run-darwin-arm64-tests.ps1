param(
	[string]$Compiler = 'D:\EE\QTool\rebcmdview.exe',
	[string]$Remote = 'gh-runner',
	[switch]$Canonical
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $repo 'build\darwin-arm64-tests'
$smokes = @(
	'darwin-arm64-minimal-smoke',
	'darwin-arm64-import-smoke',
	'darwin-arm64-import-var-smoke'
)
$runtimeSmokes = @('darwin-arm64-runtime-smoke')
$abiSmokes = @('darwin-arm64-abi-smoke')
$allSmokes = $smokes + $runtimeSmokes + $abiSmokes
$dylibBase = Join-Path $outputDir 'darwin-arm64-shared'
$dylib = "$dylibBase.dylib"
$canonicalNames = @()
$canonicalArchive = Join-Path $outputDir 'canonical-tests.tar'

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
foreach ($smoke in $smokes) {
	$source = Join-Path $repo "system\tests\source\units\$smoke.reds"
	$output = Join-Path $outputDir $smoke
	Remove-Item -LiteralPath $output -Force -ErrorAction SilentlyContinue
	$args = @(
		'/c', $Compiler, '-cqs', (Join-Path $repo 'red.r'), '-r',
		'-t', 'Darwin-ARM64', '--no-runtime', '-d', '--show-func-map',
		'-o', $output, $source
	)
	& cmd @args
	if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $output)) {
		throw "Darwin ARM64 smoke compilation failed for $smoke with exit code $LASTEXITCODE"
	}
}

foreach ($smoke in $runtimeSmokes) {
	$source = Join-Path $repo "system\tests\source\units\$smoke.reds"
	$output = Join-Path $outputDir $smoke
	Remove-Item -LiteralPath $output -Force -ErrorAction SilentlyContinue
	$args = @(
		'/c', $Compiler, '-cqs', (Join-Path $repo 'red.r'), '-r',
		'-t', 'Darwin-ARM64', '-d', '--show-func-map',
		'-o', $output, $source
	)
	& cmd @args
	if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $output)) {
		throw "Darwin ARM64 runtime smoke compilation failed for $smoke with exit code $LASTEXITCODE"
	}
}

foreach ($smoke in $abiSmokes) {
	$source = Join-Path $repo "system\tests\source\units\$smoke.reds"
	$output = Join-Path $outputDir $smoke
	Remove-Item -LiteralPath $output -Force -ErrorAction SilentlyContinue
	$args = @(
		'/c', $Compiler, '-cqs', (Join-Path $repo 'red.r'), '-r',
		'-t', 'Darwin-ARM64', '--no-runtime', '-d', '--show-func-map',
		'-o', $output, $source
	)
	& cmd @args
	if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $output)) {
		throw "Darwin ARM64 ABI smoke compilation failed for $smoke with exit code $LASTEXITCODE"
	}
}

Remove-Item -LiteralPath $dylib -Force -ErrorAction SilentlyContinue
$dylibArgs = @(
	'/c', $Compiler, '-cqs', (Join-Path $repo 'red.r'), '-r',
	'-t', 'Darwin-ARM64-SO', '-d', '--show-func-map',
	'-o', $dylibBase, (Join-Path $repo 'system\tests\shared-lib.reds')
)
& cmd @dylibArgs
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $dylib)) {
	throw "Darwin ARM64 dylib compilation failed with exit code $LASTEXITCODE"
}

if ($Canonical) {
	$canonicalDir = Join-Path $outputDir 'canonical'
	New-Item -ItemType Directory -Force -Path $canonicalDir | Out-Null
	$runAll = Get-Content (Join-Path $repo 'system\tests\run-all.r') -Raw
	$canonicalNames = [regex]::Matches(
		$runAll,
		'%source/units/([A-Za-z0-9-]+-test\.reds)'
	) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
	$canonicalNames = $canonicalNames | Where-Object {
		$_ -notin @('struct-test.reds', 'size-test.reds')
	}
	foreach ($name in $canonicalNames) {
		$source = Join-Path $repo "system\tests\source\units\$name"
		$smoke = [IO.Path]::GetFileNameWithoutExtension($name)
		$output = Join-Path $canonicalDir $smoke
		Remove-Item -LiteralPath $output -Force -ErrorAction SilentlyContinue
		$args = @(
			'/c', $Compiler, '-cqs', (Join-Path $repo 'red.r'), '-r',
			'-t', 'Darwin-ARM64', '-d', '--show-func-map',
			'-o', $output, $source
		)
		$compileOutput = & cmd @args 2>&1
		if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $output)) {
			$compileOutput | Write-Host
			throw "Darwin ARM64 canonical suite compilation failed for $name with exit code $LASTEXITCODE"
		}
		Write-Host "Compiled Darwin ARM64 canonical suite: $smoke"
	}
	Copy-Item -LiteralPath (
		Join-Path $repo 'system\tests\source\units\libs\structlib.c'
	) -Destination (Join-Path $canonicalDir 'structlib.c') -Force
	Remove-Item -LiteralPath $canonicalArchive -Force -ErrorAction SilentlyContinue
	$tar = Join-Path $env:SystemRoot 'System32\tar.exe'
	& $tar -cf $canonicalArchive -C $canonicalDir .
	if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $canonicalArchive)) {
		throw 'Failed to package Darwin ARM64 canonical suites'
	}
}

$remoteDir = (& ssh $Remote 'mktemp -d /tmp/red-darwin-arm64-tests.XXXXXX').Trim()
if ($LASTEXITCODE -ne 0 -or $remoteDir -notmatch '^/tmp/red-darwin-arm64-tests\.[A-Za-z0-9]+$') {
	throw "Failed to create a safe remote test directory: $remoteDir"
}

try {
	foreach ($smoke in $allSmokes) {
		& scp (Join-Path $outputDir $smoke) "${Remote}:$remoteDir/"
		if ($LASTEXITCODE -ne 0) { throw "Failed to copy Darwin ARM64 smoke binary: $smoke" }
	}
	$helperSource = Join-Path $repo 'system\tests\source\units\darwin-arm64-abi-helper.c'
	& scp $helperSource "${Remote}:$remoteDir/"
	if ($LASTEXITCODE -ne 0) { throw 'Failed to copy Darwin ARM64 ABI helper source' }
	& scp $dylib "${Remote}:$remoteDir/"
	if ($LASTEXITCODE -ne 0) { throw 'Failed to copy Darwin ARM64 shared library' }
	$loaderSource = Join-Path $repo 'system\tests\source\units\darwin-arm64-dylib-loader.c'
	& scp $loaderSource "${Remote}:$remoteDir/"
	if ($LASTEXITCODE -ne 0) { throw 'Failed to copy Darwin ARM64 dylib loader source' }
	if ($Canonical) {
		& scp $canonicalArchive "${Remote}:$remoteDir/"
		if ($LASTEXITCODE -ne 0) { throw 'Failed to copy Darwin ARM64 canonical suites' }
	}

	$canonicalCommand = ''
	if ($Canonical) {
		$canonicalExecutables = $canonicalNames | ForEach-Object {
			[IO.Path]::GetFileNameWithoutExtension($_)
		}
		$canonicalCommand = @"
mkdir canonical
tar -xf canonical-tests.tar -C canonical
cd canonical
clang -arch arm64 -dynamiclib -O2 -Wall -Wextra -o libstructlib.dylib structlib.c
codesign --force --sign - libstructlib.dylib
export DYLD_LIBRARY_PATH="`$PWD"
canonical_failures=0
canonical_passed=0
for suite in $($canonicalExecutables -join ' '); do
  chmod +x "`$suite"
  codesign --force --sign - "`$suite"
  if report=`$(./"`$suite" 2>&1); then
    status=0
  else
    status=`$?
  fi
  if [ "`$status" -eq 0 ] && printf '%s' "`$report" | grep -q 'Number of Assertions Failed:    0'; then
    echo "`$suite passed"
    canonical_passed=`$((canonical_passed + 1))
  else
    echo "****** `$suite failed (exit `$status) *****"
    printf '%s\n' "`$report"
    canonical_failures=1
  fi
done
echo "Canonical Red/System suites: `$canonical_passed/$($canonicalExecutables.Count) passed"
test "`$canonical_failures" -eq 0
cd ..
"@
	}

	$command = @"
set -eu
cd '$remoteDir'
test "`$(uname -m)" = arm64
for smoke in $($smokes -join ' '); do
  chmod +x "`$smoke"
  file "`$smoke"
  otool -hv "`$smoke"
  otool -l "`$smoke" | grep -q LC_MAIN
  dyld_info -validate_only "`$smoke"
  codesign --force --sign - "`$smoke"
  ./"`$smoke"
done
for smoke in $($runtimeSmokes -join ' '); do
  chmod +x "`$smoke"
  file "`$smoke"
  otool -hv "`$smoke"
  otool -l "`$smoke" | grep -q LC_MAIN
  dyld_info -validate_only "`$smoke"
  codesign --force --sign - "`$smoke"
  ./"`$smoke" probe-arg
done
clang -arch arm64 -dynamiclib -O2 -Wall -Wextra \
  -o libdarwin-arm64-abi-helper.dylib darwin-arm64-abi-helper.c
codesign --force --sign - libdarwin-arm64-abi-helper.dylib
for smoke in $($abiSmokes -join ' '); do
  chmod +x "`$smoke"
  file "`$smoke"
  otool -l "`$smoke" | grep -q LC_MAIN
  dyld_info -validate_only "`$smoke"
  codesign --force --sign - "`$smoke"
  ./"`$smoke"
done
file darwin-arm64-shared.dylib
otool -hv darwin-arm64-shared.dylib
otool -D darwin-arm64-shared.dylib | grep -q '^@rpath/darwin-arm64-shared.dylib`$'
nm -gU darwin-arm64-shared.dylib | grep -q ' _foo`$'
nm -gU darwin-arm64-shared.dylib | grep -q ' _i`$'
dyld_info -validate_only darwin-arm64-shared.dylib
codesign --force --sign - darwin-arm64-shared.dylib
clang -arch arm64 -O2 -Wall -Wextra \
  -o darwin-arm64-dylib-loader darwin-arm64-dylib-loader.c
codesign --force --sign - darwin-arm64-dylib-loader
./darwin-arm64-dylib-loader ./darwin-arm64-shared.dylib
$canonicalCommand
"@
	& ssh $Remote $command
	if ($LASTEXITCODE -ne 0) { throw 'Darwin ARM64 smoke failed on the remote runner' }
}
finally {
	if ($remoteDir -match '^/tmp/red-darwin-arm64-tests\.[A-Za-z0-9]+$') {
		& ssh $Remote "rm -rf '$remoteDir'" | Out-Null
	}
}

$scope = if ($Canonical) { 'focused and canonical tests' } else { 'focused smokes' }
Write-Host "Darwin ARM64 $scope passed on $Remote."
