# Reddit Posts

---

## r/ClaudeAI

**Title:** TIL you can share a single CLAUDE.md across all your repos using directory structure

**Body:**

I've been working on a polyrepo project — about 12 repos, mix of frontend/backend/infra. For a while I was maintaining separate CLAUDE.md files in each one, which was annoying because 80% of the context was the same (coding standards, architectural patterns, preferred libraries).

Then I realized: Claude Code walks up the directory tree. If all your repos live under a single parent directory, you can put your shared CLAUDE.md at that parent level and it just works. Every repo inherits it automatically. No symlinks, no copying.

The problem was the "all repos under one parent" part. Cloning them manually, keeping them in sync, checking status across all of them — the usual polyrepo pain. I ended up writing a small bash CLI to manage the workspace: clone repos in parallel, check status/branches across all of them, run commands on subsets using tags.

```bash
mars status                             # branch + sync state for all repos
mars exec "npm test" --tag frontend     # run commands on tagged subsets
```

It's called Mars — pure bash 3.2+, zero deps beyond git. Link in comments if anyone wants to try it.

But the real point of this post: how are you all handling context sharing across repos? Separate CLAUDE.md per repo? One big shared one? Some hybrid? Curious what's working for people.

---

## r/commandline

**Title:** Mars — polyrepo workspace manager, pure bash 3.2+, zero dependencies

**Body:**

I got tired of maintaining a different `status-all.sh` and `sync-all.sh` for every multi-repo project, so I built Mars — a single CLI that manages multiple git repos as a workspace.

What it does:

- `mars init` — interactive workspace setup
- `mars add <url> --tags frontend,web` — register repos with tags
- `mars clone` — parallel clone, 4 concurrent jobs, progress spinners
- `mars status` — table showing branch, dirty state, ahead/behind for every repo
- `mars exec "npm test" --tag frontend` — run commands on tagged subsets
- `mars branch/checkout/sync` — cross-repo git operations

Technical stuff that might interest this sub:

- Pure bash 3.2+ (macOS default) — no associative arrays, so everything uses parallel indexed arrays
- Clack-style terminal UI: Unicode spinners (◒◐◓◑), box drawing (┌│└), color output with ASCII fallback for dumb terminals
- No subshells where possible — they break global variable updates in bash, so git output capture uses a globals pattern instead
- Single-file distribution: `build.sh` concatenates 13 source files (~1200 lines) into one executable

The hardest part was honestly the bash 3.2 constraint. No `declare -A`, no `readarray`, no `|&`. Everything that would take one line in bash 4+ requires a workaround. But the payoff is it runs on a stock Mac with zero install friction.

Install: `npm i -g @dean0x/mars` or `brew install dean0x/tap/mars` or `curl -fsSL https://raw.githubusercontent.com/dean0x/mars/main/install.sh | bash`

GitHub: https://github.com/dean0x/mars

---

## r/programming

**Title:** The polyrepo shell script graveyard — and how I finally replaced mine

**Body:**

Every polyrepo project I've worked on eventually grows the same collection of shell scripts: `status-all.sh`, `sync-all.sh`, `branch-all.sh`. They all do roughly the same thing, slightly differently, and break in slightly different ways.

The tipping point for me was when I joined a project with 12 repos. I copied my scripts from the last project, adjusted the paths, and within a week I had bugs because some repos had different default branches, some needed different handling. The scripts kept growing.

So I sat down and figured out what I actually needed:

1. A config file listing repos with metadata (tags like "frontend", "backend")
2. Parallel operations (cloning 12 repos sequentially is painful)
3. Tag-based filtering — run tests on just the frontend repos, create a branch on just backend
4. A status view showing branch, dirty state, and sync status across everything

I ended up writing it in bash 3.2+ (macOS default, zero install friction) with no dependencies beyond git. It's about 1200 lines across 13 files, bundled into a single executable for distribution.

The interesting tradeoffs:

- **bash 3.2 means no associative arrays** — I use parallel indexed arrays instead, which is ugly but portable
- **No subshells** where possible, because they break global variable updates
- **Tag filtering uses string matching** on comma-separated values — simple but covers every real-world case I've hit

There are similar tools out there — gita (Python), myrepos (Perl), meta (Node) — all good, with different tradeoffs. The main difference is zero-dep installation and first-class tag filtering.

The tool is called Mars. GitHub link in the comments if you're curious.

Has anyone else gone through this cycle of "copy shell scripts → customize → give up → build something proper"? Curious whether this is a universal polyrepo experience or just my teams.

---

## r/git

**Title:** I manage 15 repos for one project — here's the workflow I settled on

**Body:**

After years of `cd repo1 && git status && cd ../repo2 && git status && ...` I finally built something to handle it.

The core problem: I work on a project split across 15 independent repos (different CI, different release cycles, different access controls — monorepo wasn't an option). Every morning I'd spend 5 minutes just figuring out which repos were on the right branch and which needed a pull.

I wrote a CLI called Mars that wraps git operations across all of them:

- `mars status` — one table showing branch, dirty/clean, ahead/behind for every repo
- `mars branch feature-x --tag backend` — create a branch on just the backend repos
- `mars sync --rebase` — pull latest across everything
- `mars exec "git log --oneline -5"` — run arbitrary git (or non-git) commands

The tag system ended up being more useful than I expected. Repos are tagged in a simple YAML config (`frontend`, `backend`, `shared`), and every command supports `--tag` to target subsets. Deploying? `mars exec "make deploy" --tag frontend`. Running tests? `mars exec "npm test" --tag backend`.

Pure bash 3.2+, no dependencies beyond git.

GitHub: https://github.com/dean0x/mars

For anyone else managing a pile of repos — what does your workflow look like? Still using wrapper scripts, or have you found something better?

---

## r/devops

**Title:** We had 14 microservice repos and no consistent way to operate across them

**Body:**

This might be a familiar story: the team started with 3 repos, each with their own CI, their own release cycle, their own access controls. Monorepo never made sense for us. Fast forward two years and we had 14.

The operational pain wasn't the repos themselves — it was coordinating across them. "Is every repo on the release branch?" required checking 14 terminals. "Pull latest everywhere before we cut a release" was a shell script that someone wrote once and nobody maintained. Tag a release across the repos that changed? Manual.

I eventually wrote a CLI to standardize it. The core idea: define a workspace config listing your repos with tags (by team, by function, whatever), then operate on them as a group.

```bash
mars status                             # branch + sync state across all 14
mars branch release-2.4 --tag backend   # branch just the backend services
mars exec "make test" --tag payments    # run tests on a specific group
mars sync --rebase                      # pull latest everywhere
```

The tag-based filtering turned out to be the most useful part. We tag by team ownership (platform, payments, frontend) and by deployment group. When payments needs a hotfix, `mars branch hotfix-xxx --tag payments` gets you set up across just those 3 repos.

It's a simple bash tool (3.2+, zero deps beyond git) — not trying to replace your CI/CD or your deployment pipeline. It just handles the "git operations across N repos" layer that everyone solves with ad-hoc scripts.

GitHub link in comments. Curious how other teams handle this — especially at larger repo counts. Are you using wrapper scripts, a monorepo, or something else entirely?

---

## r/commandline first comment

> GitHub: https://github.com/dean0x/mars

*(For r/ClaudeAI, r/programming, and r/devops — post the GitHub link as a first comment rather than in the body.)*
