# Mars

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![npm](https://img.shields.io/npm/v/@dean0x/mars)](https://www.npmjs.com/package/@dean0x/mars)
[![CI](https://github.com/dean0x/mars/actions/workflows/ci.yml/badge.svg)](https://github.com/dean0x/mars/actions/workflows/ci.yml)

Manage multiple Git repositories as one workspace.

Tag-based filtering, parallel operations, zero dependencies.

<p align="center">
  <img src="demo.gif" alt="Mars CLI demo" width="800" />
</p>

## Why Mars?

- **Polyrepo without the pain** — one CLI for status, branching, syncing across all repos
- **Tag-based filtering** — target subsets of repos (`--tag frontend`, `--tag backend`)
- **Zero dependencies** — pure bash 3.2+, works on macOS out of the box

## Quick Install

```bash
npm install -g @dean0x/mars
```

See [all installation methods](#installation) for Homebrew, curl, and manual options.

## Quick Start

```bash
mkdir my-project && cd my-project
mars init

mars add https://github.com/dean0x/mars-example-frontend.git --tags frontend,web
mars add https://github.com/dean0x/mars-example-backend.git --tags backend,api
mars add https://github.com/dean0x/mars-example-shared.git --tags shared

mars clone
mars status
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

## Workspace Structure

```
my-project/
├── mars.yaml           # Workspace configuration
├── .gitignore          # Contains 'repos/'
└── repos/              # Cloned repositories (gitignored)
    ├── frontend/
    ├── backend/
    └── shared/
```

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

Install a specific version:

```bash
MARS_VERSION=0.1.1 curl -fsSL https://raw.githubusercontent.com/dean0x/mars/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/dean0x/mars.git
cd mars
./build.sh
cp dist/mars ~/.local/bin/  # or anywhere in PATH
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, architecture, and release process.

## License

MIT
