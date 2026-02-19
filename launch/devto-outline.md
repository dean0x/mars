# Dev.to Blog Post

**Title:** How to Manage a Polyrepo Workspace with Mars CLI

**Tags:** git, bash, cli, productivity

**Target publish:** Week 2 after launch

---

## Outline

### 1. Introduction — The Polyrepo Problem

- Not every project fits in a monorepo
- Independent repos mean independent CI, access controls, release cycles
- But daily operations across repos are painful: status, branching, syncing
- The typical solution: a growing collection of shell scripts

### 2. Existing Tools and Their Tradeoffs

| Tool | Language | Config | Approach |
|------|----------|--------|----------|
| git submodules | git-native | .gitmodules | Couples repos at git level, tracks specific commits |
| gita | Python | CLI-based | Group and manage repos, Python dependency |
| myrepos | Perl | .mrconfig | Config-file driven, runs arbitrary commands |
| meta | Node | meta.json | JSON config, plugin system |
| **Mars** | Bash | mars.yaml | Tag-based filtering, Claude-aware, zero deps |

Key differentiators for Mars:
- Pure bash 3.2+ — no runtime dependencies
- Tag-based filtering as a first-class concept
- Shared Claude Code configuration

### 3. Getting Started with Mars

- Installation (all 4 methods: npm, Homebrew, curl, manual)
- `mars init` walkthrough — what it creates
- `mars add` — registering repos with tags
- `mars clone` — parallel cloning

Include code examples and expected output.

### 4. Daily Workflow

- Morning routine: `mars sync` then `mars status`
- Starting a feature: `mars branch feature-x --tag backend`
- Running tests: `mars exec "npm test" --tag frontend`
- Checking what changed: `mars status`
- End of day: `mars sync --rebase`

### 5. Tag-Based Workflows

- Organizing repos: frontend, backend, shared, infrastructure
- Operations on subsets: `--tag frontend`
- Multiple tags per repo: `--tags frontend,web`
- Real-world example: deploying frontend repos vs backend repos

### 6. Claude Configuration Sharing

- What `claude.md` and `.claude/` do in Claude Code
- How Mars shares them at the workspace level
- Workspace structure that enables this
- Use case: consistent AI context across a polyrepo

### 7. Under the Hood

- Why bash 3.2+ (macOS default, zero friction)
- Clack-style UI implementation in bash (Unicode/ASCII fallback)
- Parallel operations with bash job control
- Single-file bundling for distribution
- No associative arrays — parallel indexed arrays pattern

### 8. Conclusion

- When to use Mars vs monorepo vs submodules
- Mars fits when: independent repos, unified operations, tag-based organization
- Links: GitHub, npm, install command
- Call for feedback and contributions
