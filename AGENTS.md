# AGENTS.md — Red Language (ANLACO fork)

## Purpose

This is the ANLACO fork of [red/red](https://github.com/red/red), focused on fixing **red/view** issues on **Linux (GTK3 backend)**. Patches are intended for upstream contribution if accepted by the Red team.

## Bootstrap & Build

Red is bootstrapped with **Rebol2**. The `rebol` binary must be in the repo root.

```bash
# Compile a Red source file (development mode)
./rebol -qws red.r "-c %path/to/file.red"

# Compile with release mode (no dependencies)
./rebol -qws red.r "-r %path/to/file.red"

# Compile targeting Linux GUI (GTK3)
./rebol -qws red.r "-t Linux-GTK %path/to/file.red"

# Rebuild libRedRT (required after changing runtime code)
./rebol -qws red.r "-u %path/to/file.red"

# Select View engine explicitly
./rebol -qws red.r "--view GTK -c %path/to/file.red"
# Or disable View entirely
./rebol -qws red.r "--no-view -c %path/to/file.red"
```

The `-t` flag cross-compiles to a different target. GUI apps need `-t Linux-GTK`; console apps use `-t Linux`.

## Testing

Three separate test runners exist:

```bash
# Red tests (from Rebol console)
do %tests/run-all.r
do %tests/run-core-tests.r
do %tests/run-view-tests.r         # View-specific
do %tests/run-regression-tests.r

# Red/System tests
do %system/tests/run-all.r

# Full suite (Red + Red/System)
do %run-all-tests.r

# CI mode flags: --batch, --each, --ci-each, --debug, --release
do %tests/run-core-tests.r --batch
```

Test framework: `quick-test.r` (Rebol), `quick-test.red` (Red), `quick-test.reds` (Red/System). Tests use `~~~start-file~~~`, `===start-group===`, `--test--`, `--assert` syntax. Run compiled tests from shell: `tests/run-all.sh`.

## Linux/GTK3 Setup

Required i386 packages for GUI on 64-bit Linux:

```bash
sudo apt-get install libgtk-3-bin:i386 librsvg2-common:i386 \
  libcanberra-gtk-module:i386 libcanberra-gtk3-module:i386 at-spi2-core:i386
```

CI uses Docker images in `CI/Linux-gtk/` (i386/ubuntu:18.04 + GTK3 + Xvfb) for headless GUI testing.

## Architecture

- **Two-pass compiler**: Red source → Red/System (`.reds`) → native code. `encapper/compiler.r` handles the Red pass; `system/compiler.r` handles the Red/System pass.
- **File extensions**: `.r` = Rebol source, `.red` = Red source, `.reds` = Red/System source.
- **Conditional compilation**: `#switch config/OS` and `#switch config/GUI-engine` select platform/backend code at compile time.

### Key directories

| Path | Contents |
|------|----------|
| `modules/view/` | View engine core: `view.red`, `VID.red`, `draw.red`, `RTD.red`, `styles.red` |
| `modules/view/backends/gtk3/` | **GTK3 Linux backend** — primary focus for this fork |
| `modules/view/backends/platform.red` | Platform-independent GUI backend core |
| `system/config.r` | Build target definitions (Linux, Linux-GTK, etc.) |
| `system/runtime/linux.reds` | Linux platform runtime |
| `runtime/` | Core runtime + datatype implementations |
| `environment/` | Mezzanine code shipped in the binary |
| `encapper/` | Rebol encapper that builds the Red binary |
| `build/includes.r` | Master list of all source files packaged into the binary |

### View backend structure

Each backend (`windows/`, `macOS/`, `gtk3/`, `terminal/`, `test/`) contains: `gui.reds`, `events.reds`, `draw.reds`, `font.reds`, plus widget-specific files. The GTK3 backend additionally has `gtk.reds` (3743 lines of GTK bindings) and `css.reds`.

## Commit conventions

Prefix commit messages with: `FEAT:`, `FIX:`, `TESTS:`, `DOCS:`, `CI:`.
For bug fixes referencing issues: `FIX: issue #<number> (<issue title>)`.

## Coding style

- Tabs for indentation (4 chars wide)
- UTF-8 encoding
- End-of-line comments: precede with `;--` starting at position 57
- Short function specs on one line (~90 chars); long specs use vertical layout with datatypes

## Git workflow

- `origin` → `git@github.com:anlaco/red.git` (ANLACO fork)
- `upstream` → `https://github.com/red/red.git` (official)
- Sync from upstream before creating PRs intended for upstream contribution.

## Upstream contribution process

Following the Red team's preferred workflow (see CONTRIBUTING.md):

1. **Notify the team** — Post on [Gitter](https://gitter.im/red/red) describing the proposed change and asking permission before submitting a PR.
2. **Write tests** — Every change must include tests using quick-test. For GTK3 GUI changes that require a display server, use interactive tests (like `tests/gtk3-face-size-test.red`) since automated headless tests cannot verify backend-specific behavior.
3. **Commit with correct prefix** — `FIX:`, `FEAT:`, `TESTS:`, `DOCS:`, `CI:`. Use your own author identity (not tool defaults).
4. **Push to fork** — `git push origin master`
5. **Create PR** — `gh pr create --repo red/red --head anlaco:master --base master`
6. **Follow up** — Respond to feedback from the Red team on the PR.

### Interactive test pattern (GTK3)

```red
Red [
    Title:   "Descriptive title"
    Purpose: "What the test verifies"
    Needs:   'View
]

view/flags [
    title "Test title"
    size 400x300
    on-resize [probe face/size]              ; Print size on resize
    button "Print face/size" [probe face/parent/size]  ; Button to check size
] [resize]
```

Key points:
- `Needs: 'View` is required for GUI support
- `view/flags [...] [resize]` enables window resizing
- `probe` prints values with type info (better for debugging than `print`)
- `face/parent/size` accesses the window size from a child widget

## Important notes

- The repo deliberately has **no `.gitignore`**. Copy `.github/.gitignore-sample` to `.gitignore` to ignore build artifacts.
- `build/` directory contains build scripts that require a Rebol SDK license — not needed for normal development.
- Mezzanine code contributions are **not currently accepted** upstream per CONTRIBUTING.md.
- Language changes require a proposal at [red/REP](https://github.com/red/REP) before implementation.