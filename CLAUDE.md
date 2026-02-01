# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mars is a Bash-based Multi Agentic Repo workspace manager for managing multiple Git repositories as a unified workspace. Written for bash 3.2+ (macOS compatible) with no external dependencies beyond git.

## Commands

```bash
# Build bundled distribution (MUST run before committing source changes)
./build.sh              # Output: dist/mars (committed for easy installation)

# Run in development mode
./mars <command>        # Sources from lib/ directory

# Run tests (no framework - custom bash harness)
bash test/test_yaml.sh
bash test/test_config.sh
bash test/test_integration.sh
```

## Architecture

### Two Operating Modes
- **Development**: `./mars` sources files from `lib/` subdirectories
- **Distribution**: `dist/mars` is a single bundled file with all code inlined

### Module Structure
```
lib/
├── ui.sh           # Terminal UI (colors, spinners, prompts, tables)
├── yaml.sh         # mars.yaml parser (not general-purpose YAML)
├── config.sh       # Workspace detection and config loading
├── git.sh          # Git wrapper with output capture
└── commands/       # Command implementations (init, clone, add, etc.)
```

### Key Patterns

**Output Capture Pattern** - Git operations capture output in globals:
```bash
GIT_OUTPUT=""
GIT_ERROR=""
if git_clone "$url" "$path"; then
    # success: use GIT_OUTPUT
else
    # failure: use GIT_ERROR
fi
```

**Bash 3.2 Compatibility** - No associative arrays, uses parallel indexed arrays:
```bash
YAML_REPO_URLS=()
YAML_REPO_PATHS=()
YAML_REPO_TAGS=()
```

**Tag Filtering** - Comma-separated tags with string matching:
```bash
[[ ",$tags," == *",$filter_tag,"* ]]
```

**Command Pattern** - Each command is `cmd_<name>()` in its own file under `lib/commands/`.

### Configuration Format (mars.yaml)
```yaml
version: 1
workspace:
  name: "project-name"
repos:
  - url: git@github.com:org/repo.git
    path: custom-path    # optional
    tags: [frontend]     # optional
defaults:
  branch: main
```

## Implementation Constraints

- Return exit codes, never throw (bash has no exceptions)
- Avoid subshells where possible (breaks global variable updates)
- Check return codes explicitly and propagate errors
- Use `ui_step_error()`/`ui_step_done()` for user feedback
- Tests use `/tmp/claude/` for temporary files
- Parallel operations limited to 4 concurrent jobs (`CLONE_PARALLEL_LIMIT`)
