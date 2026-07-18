param(
	[string]$Compiler = 'D:\EE\QTool\rebcmdview.exe',
	[string]$Remote = 'gh-runner'
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $repo 'build\macos-arm64-view-tests'
$name = 'macos-arm64-view-smoke'
$output = Join-Path $outputDir $name
$app = "$output.app"
$archive = Join-Path $outputDir "$name.tar"
$source = Join-Path $repo 'tests\source\view\macos-arm64-smoke.red'

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Remove-Item -LiteralPath $app -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue

$compileArgs = @(
	'/c', $Compiler, '-cqs', (Join-Path $repo 'red.r'), '-r',
	'-t', 'macOS-ARM64', '-d', '--show-func-map',
	'-o', $output, $source
)
& cmd @compileArgs
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $app -PathType Container)) {
	throw "macOS ARM64 View smoke compilation failed with exit code $LASTEXITCODE"
}

$tar = Join-Path $env:SystemRoot 'System32\tar.exe'
& $tar -cf $archive -C $outputDir "$name.app"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $archive -PathType Leaf)) {
	throw 'Failed to package the macOS ARM64 View smoke bundle'
}

$remoteDir = (& ssh $Remote 'mktemp -d /tmp/red-macos-arm64-view.XXXXXX').Trim()
if ($LASTEXITCODE -ne 0 -or $remoteDir -notmatch '^/tmp/red-macos-arm64-view\.[A-Za-z0-9]+$') {
	throw "Failed to create a safe remote test directory: $remoteDir"
}

try {
	& scp $archive "${Remote}:$remoteDir/"
	if ($LASTEXITCODE -ne 0) { throw 'Failed to copy the macOS ARM64 View bundle' }

	$command = @"
set -eu
cd '$remoteDir'
tar -xf '$name.tar'
exe='$name.app/Contents/MacOS/$name'
chmod 755 "`$exe"
test "`$(uname -m)" = arm64
file "`$exe" | grep -q 'Mach-O 64-bit executable arm64'
otool -hv "`$exe" | grep -q ARM64
otool -L "`$exe" | grep -q 'AppKit.framework'
dyld_info -validate_only "`$exe"
cp "`$exe" '$name.signature-probe'
chmod 755 '$name.signature-probe'
codesign --verify --strict --verbose=4 '$name.signature-probe'
rm '$name.signature-probe'
rm -f macos-arm64-view-smoke.ok macos-arm64-view-smoke.error
if ./"`$exe"; then
  :
else
  status=`$?
  if test -f macos-arm64-view-smoke.error; then cat macos-arm64-view-smoke.error; fi
  exit "`$status"
fi
test "`$(cat macos-arm64-view-smoke.ok)" = MACOS-ARM64-VIEW-OK
"@
	& ssh $Remote $command
	if ($LASTEXITCODE -ne 0) { throw 'macOS ARM64 View smoke failed on the remote runner' }
}
finally {
	if ($remoteDir -match '^/tmp/red-macos-arm64-view\.[A-Za-z0-9]+$') {
		& ssh $Remote "rm -rf '$remoteDir'" | Out-Null
	}
}

Write-Host "macOS ARM64 native View smoke passed on $Remote."
