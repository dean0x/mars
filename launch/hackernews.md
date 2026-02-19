# Show HN Post

## Submission

**Title:** Show HN: Mars – manage multiple Git repos as one workspace

**URL:** https://github.com/dean0x/mars

**Timing:** Tuesday-Thursday, 8-10 AM ET

---

## First Comment

Post immediately after submission:

---

Hi HN, I built Mars because managing 10+ repos with shell scripts was getting painful. Every project had its own `status-all.sh`, `branch-all.sh`, `sync-all.sh` — and they all did the same thing slightly differently.

Mars gives you a single CLI for the common operations: init a workspace, add repos (with optional tags), clone them in parallel, check status across all of them, create branches, sync, and run arbitrary commands.

**What it does:**

- `mars init` creates a workspace with a `mars.yaml` config
- `mars add <url> --tags frontend,web` adds repos with tags
- `mars clone` clones everything (4 parallel jobs)
- `mars status` shows branch, dirty state, and sync status in a table
- `mars exec "npm install" --tag frontend` runs commands on tagged subsets
- `mars branch/checkout/sync` for cross-repo git operations

**Technical decisions:**

- Pure bash 3.2+ — ships with every Mac, zero install friction, no runtime dependencies
- Clack-style terminal UI (Unicode spinners, box drawing characters, color) with ASCII fallback
- No associative arrays (bash 3.2 compat) — uses parallel indexed arrays instead
- Parallel operations with job control, capped at 4 concurrent

**One extra feature:** if you use Claude Code, Mars can share a `claude.md` and `.claude/` directory across all repos in your workspace. Useful if you want consistent AI context across a polyrepo.

**What it doesn't do (yet):**

- No Windows support (bash-only)
- No repo removal command
- No workspace-level git hooks
- No dependency graph between repos

Install: `npm i -g @dean0x/mars` or `brew install dean0x/tap/mars`

Happy to answer questions about the implementation, bash 3.2 constraints, or polyrepo workflows.

---

## Anticipated Q&A

**"Why not git submodules?"**

Different model. Submodules couple repos at the git level — they track specific commits and require coordinated updates. Mars keeps repos fully independent but lets you orchestrate operations across them. You can add/remove repos from a workspace without affecting the repos themselves.

**"How is this different from gita/myrepos/meta?"**

- gita (Python): Similar concept, different implementation. Mars is pure bash with zero deps, has tag-based filtering, and Claude config sharing.
- myrepos (Perl): Config-file driven, more complex configuration. Mars uses a simple YAML format.
- meta (Node): JSON-based, heavier runtime. Mars is a single bash script.
- All of them are good tools. Mars trades extensibility for simplicity and zero-friction installation.

**"Bash in 2026?"**

bash 3.2 ships with every Mac. `curl | bash` installs it in 5 seconds. No Node, no Python, no Go binary to download. The tradeoff is development speed (bash is painful to write) for deployment simplicity (bash is everywhere). For a CLI that orchestrates git commands, bash is a natural fit.

**"Why not a monorepo?"**

Monorepos are great when they work for your team. Mars is for the cases where you need or want independent repos — different CI pipelines, different access controls, different release cycles — but still want unified operations across them.

**"How does the Claude config sharing work?"**

When you run `mars init`, it optionally creates a `claude.md` and `.claude/` directory at the workspace root. When you open any repo in the workspace with Claude Code, it walks up the directory tree and finds these shared config files. No symlinks, no copying — just directory structure.
