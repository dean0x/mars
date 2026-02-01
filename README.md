# Mars CLI

Multi Agentic Repo workspace manager for git repositories with shared Claude configuration.

## Features

- Manage multiple git repos as a unified workspace
- Shared `claude.md` and `.claude/` config across repos
- Tag-based repo filtering for targeted operations
- Parallel cloning with rate limiting
- Works with bash 3.2+ (macOS compatible)

## Installation

### npm (recommended)

```bash
npm install -g @dean0x/mars
```

Or run without installing:

```bash
npx @dean0x/mars --help
```

### Homebrew (macOS/Linux)

```bash
brew install dean0x/tap/mars
```

### Shell Script

```bash
curl -fsSL https://raw.githubusercontent.com/dean0x/mars/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/dean0x/mars.git
cd mars
./build.sh
cp dist/mars ~/.local/bin/  # or anywhere in PATH
```

## Quick Start

```bash
# Create a new workspace
mkdir my-project && cd my-project
mars init

# Add repositories
mars add git@github.com:org/frontend.git --tags frontend,web
mars add git@github.com:org/backend.git --tags backend,api
mars add git@github.com:org/shared.git --tags shared

# Clone all repos
mars clone

# Check status
mars status
```

## Workspace Structure

```
my-project/
├── mars.yaml           # Workspace configuration
├── claude.md           # Shared Claude config (optional)
├── .claude/            # Shared Claude folder (optional)
├── .gitignore          # Contains 'repos/'
└── repos/              # Cloned repositories (gitignored)
    ├── frontend/
    ├── backend/
    └── shared/
```

## Commands

| Command | Description |
|---------|-------------|
| `mars init` | Initialize a new workspace |
| `mars add <url> [--tags t1,t2]` | Add a repository to config |
| `mars clone [--tag TAG]` | Clone configured repositories |
| `mars status [--tag TAG]` | Show status of all repositories |
| `mars branch <name> [--tag TAG]` | Create branch on repositories |
| `mars checkout <branch> [--tag TAG]` | Checkout branch on repositories |
| `mars sync [--tag TAG] [--rebase]` | Pull latest changes |
| `mars exec "<cmd>" [--tag TAG]` | Run command in each repository |
| `mars list [--tag TAG]` | List configured repositories |

## Tag Filtering

Target subsets of repos using `--tag`:

```bash
# Only clone frontend repos
mars clone --tag frontend

# Create branch on backend repos only
mars branch feature-auth --tag backend

# Run npm install on all frontend repos
mars exec "npm install" --tag frontend
```

## Configuration

### mars.yaml

```yaml
version: 1

workspace:
  name: "my-project"

repos:
  - url: git@github.com:org/frontend.git
    tags: [frontend, web]
  - url: git@github.com:org/backend.git
    path: api                    # optional custom path
    tags: [backend, api]

defaults:
  branch: main
```

## Development

### Project Structure

```
mars/
├── mars                    # Main CLI entry point
├── lib/
│   ├── ui.sh              # Terminal UI components
│   ├── yaml.sh            # YAML parser
│   ├── config.sh          # Config management
│   ├── git.sh             # Git operations
│   └── commands/          # Command implementations
├── build.sh               # Build distribution
├── install.sh             # Installer script
└── test/                  # Test suite
```

### Running Tests

```bash
# Run all tests
bash test/test_yaml.sh
bash test/test_config.sh
bash test/test_integration.sh
```

### Building

```bash
./build.sh    # Output: dist/mars
```

**Important:** `dist/mars` is committed for easy installation. Always run `./build.sh` before committing changes to source files.

## License

MIT
