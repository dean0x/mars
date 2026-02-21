# Contributing to Mars

## Development Setup

Clone the repo and run directly in development mode:

```bash
git clone https://github.com/dean0x/mars.git
cd mars
./mars init  # Sources from lib/ directory
```

## Project Structure

```
mars/
├── mars                    # Main CLI entry point
├── lib/
│   ├── ui.sh              # Terminal UI (colors, spinners, prompts, tables)
│   ├── yaml.sh            # mars.yaml parser
│   ├── config.sh          # Workspace detection and config loading
│   ├── git.sh             # Git wrapper with output capture
│   └── commands/          # Command implementations
│       ├── init.sh
│       ├── clone.sh
│       ├── status.sh
│       ├── branch.sh
│       ├── checkout.sh
│       ├── sync.sh
│       ├── exec.sh
│       ├── add.sh
│       └── list.sh
├── build.sh               # Build bundled distribution
├── install.sh             # Curl installer
├── dist/                  # Bundled distribution (committed)
└── test/                  # Test suite
```

## Architecture

### Two Operating Modes

- **Development**: `./mars` sources files from `lib/` subdirectories
- **Distribution**: `dist/mars` is a single bundled file with all code inlined

### Key Patterns

**Output Capture** — Git operations capture output in globals:

```bash
GIT_OUTPUT=""
GIT_ERROR=""
if git_clone "$url" "$path"; then
    # success: use GIT_OUTPUT
else
    # failure: use GIT_ERROR
fi
```

**Bash 3.2 Compatibility** — No associative arrays; uses parallel indexed arrays:

```bash
YAML_REPO_URLS=()
YAML_REPO_PATHS=()
YAML_REPO_TAGS=()
```

**Tag Filtering** — Comma-separated tags with string matching:

```bash
[[ ",$tags," == *",$filter_tag,"* ]]
```

**Command Pattern** — Each command is `cmd_<name>()` in its own file under `lib/commands/`.

### Implementation Constraints

- Bash 3.2+ (macOS default) — no associative arrays, no `readarray`
- Return exit codes, never throw (bash has no exceptions)
- Avoid subshells where possible (breaks global variable updates)
- Check return codes explicitly and propagate errors
- Use `ui_step_error()`/`ui_step_done()` for user feedback
- Clone operations run sequentially with per-repo spinner feedback

## Running Tests

```bash
bash test/test_yaml.sh
bash test/test_config.sh
bash test/test_integration.sh
```

Tests use `/tmp/mars/` for temporary files.

## Building

```bash
./build.sh    # Output: dist/mars
```

**Important:** `dist/mars` is committed to the repo for easy installation. Always run `./build.sh` before committing changes to source files.

## Pull Requests

- Run all tests before submitting
- Run `./build.sh` and include the updated `dist/mars`
- Maintain bash 3.2 compatibility (test on macOS if possible)
- Follow existing code patterns (output capture, parallel arrays, command pattern)

## Release Process

1. Update version in `package.json`
2. Commit: `git commit -am "Bump version to X.Y.Z"`
3. Tag: `git tag vX.Y.Z`
4. Push: `git push origin main --tags`

CI automatically handles:

- Run tests
- Verify tag version matches `package.json`
- Create GitHub Release with `dist/mars` binary attached
- Publish to npm (`@dean0x/mars`)
- Update Homebrew formula (`dean0x/tap/mars`)

### Required Secrets (Maintainers)

| Secret | Repository | Purpose |
|--------|------------|---------|
| `NPM_TOKEN` | mars | npm publish access token |
| `HOMEBREW_TAP_TOKEN` | mars | PAT with repo scope for homebrew-tap workflow |
