# Reddit Posts

---

## r/ClaudeAI

**Title:** Managing Claude Code across a polyrepo — what's your workflow?

**Body:**

I work across 10+ repos on the same project. Every time I start a session, I'm cd-ing between repos, checking what branch each one is on, pulling latest, running commands in the right subset.

I built a small CLI called **Mars** that treats multiple repos as one workspace. You tag repos by function and target operations at subsets:

```bash
mars init
mars add git@github.com:org/api.git --tags backend
mars add git@github.com:org/web.git --tags frontend
mars clone                              # parallel, 4 jobs
mars status                             # branch + sync state for every repo
mars exec "npm test" --tag frontend     # run tests on just frontend repos
mars sync --rebase                      # pull latest everywhere
```

It's pure bash 3.2+ with zero dependencies beyond git — no Python, no Node runtime. The workspace lives in a directory with all your repos cloned under it, so your CLAUDE.md and `.claude/` directory at the workspace root are naturally picked up when you open any repo underneath.

Curious how others here handle multi-repo workflows with Claude Code. Are you maintaining separate context per repo, or have you found ways to share configuration across them?

**Install:** `npm i -g @dean0x/mars` or `brew install dean0x/tap/mars`

GitHub: https://github.com/dean0x/mars

---

## r/commandline

**Title:** Mars — a polyrepo workspace manager written in pure bash 3.2+

**Body:**

I've been working on a CLI tool for managing multiple Git repos as a unified workspace. It's written entirely in bash 3.2+ (macOS default) with zero external dependencies beyond git.

**What it does:**

- Initialize workspaces with `mars init` (interactive prompts)
- Add repos with tags: `mars add <url> --tags frontend,web`
- Parallel clone (4 concurrent jobs) with progress spinners
- Cross-repo status table showing branch, dirty state, sync status
- Tag-based filtering: `mars status --tag backend`
- Run arbitrary commands: `mars exec "npm test" --tag frontend`
- Branch/checkout/sync across repos

**Technical details:**

- Clack-style terminal UI — Unicode spinners (◒◐◓◑), box drawing (┌│└), colored output with ASCII fallback for dumb terminals
- No associative arrays (bash 3.2 compat) — parallel indexed arrays instead
- No subshells where possible to preserve global state
- Output capture pattern for git operations (stdout/stderr in globals)
- Single-file distribution: `build.sh` concatenates all modules into one executable

The whole thing is ~1200 lines across 13 source files, bundled into a single `dist/mars` for distribution.

**Install:** `npm i -g @dean0x/mars` or `brew install dean0x/tap/mars` or `curl -fsSL https://raw.githubusercontent.com/dean0x/mars/main/install.sh | bash`

GitHub: https://github.com/dean0x/mars

---

## r/programming

**Title:** Mars: Manage multiple Git repos as one workspace (polyrepo tooling)

**Body:**

If you work with multiple independent repos that belong to the same project, you've probably written shell scripts to check status across all of them, create branches, sync changes, etc.

**Mars** is a CLI that replaces those scripts. You define a workspace with `mars.yaml`, tag your repos by function (frontend, backend, shared), and use a single CLI for operations across all of them:

```bash
mars init
mars add git@github.com:org/frontend.git --tags frontend
mars add git@github.com:org/backend.git --tags backend
mars clone                              # parallel, 4 jobs
mars status                             # table view across all repos
mars branch feature-auth --tag backend  # branch on backend repos only
mars exec "npm test" --tag frontend     # run tests on frontend repos
mars sync --rebase                      # pull latest on all repos
```

It's written in bash 3.2+ with no dependencies beyond git. Installs via npm, Homebrew, or curl.

**Compared to alternatives:**

- **git submodules** — couples repos at git level; Mars keeps them independent
- **gita** (Python) — similar concept, different tradeoffs (Mars is zero-dep bash)
- **myrepos** (Perl) — more complex config format
- **meta** (Node) — JSON config, heavier runtime

GitHub: https://github.com/dean0x/mars

---

## r/git

**Title:** Tool for managing branches, status, and sync across multiple repos

**Body:**

Built a CLI for orchestrating git operations across multiple repos. If you work with a polyrepo setup, this replaces the collection of shell scripts you've accumulated:

**Operations:**

- `mars clone` — parallel clone of all configured repos (4 concurrent jobs)
- `mars status` — table showing branch, dirty/clean, ahead/behind for every repo
- `mars branch feature-x` — create a branch on all (or tagged) repos
- `mars checkout main` — checkout across repos
- `mars sync --rebase` — pull latest on all repos
- `mars exec "git log --oneline -5"` — run arbitrary commands

**Tag filtering:**

Repos can be tagged (`frontend`, `backend`, `shared`, etc.) and every command supports `--tag` to target subsets:

```bash
mars branch feature-auth --tag backend
mars exec "npm install" --tag frontend
mars status --tag shared
```

**Config:**

Simple `mars.yaml`:

```yaml
version: 1
workspace:
  name: "my-project"
repos:
  - url: git@github.com:org/frontend.git
    tags: [frontend, web]
  - url: git@github.com:org/backend.git
    tags: [backend, api]
defaults:
  branch: main
```

Pure bash 3.2+, no dependencies beyond git.

GitHub: https://github.com/dean0x/mars
