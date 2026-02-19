# LinkedIn Post

---

**How I manage 10+ repositories as a single workspace**

If you've worked on a project spread across multiple Git repos, you know the pain: checking status means opening each repo. Creating a feature branch means running `git checkout -b` five times. Syncing means pulling in each directory.

I used to manage this with a collection of shell scripts. Every project had its own `status-all.sh` and `sync-all.sh`. They all did roughly the same thing, slightly differently, and broke in slightly different ways.

So I built **Mars** — a CLI that manages multiple Git repos as one workspace.

**What it does:**

• `mars init` — creates a workspace config
• `mars add <repo> --tags frontend,api` — registers repos with tags
• `mars clone` — clones everything in parallel
• `mars status` — one table showing branch, state, and sync status for every repo
• `mars branch feature-x --tag backend` — create branches on specific repo groups
• `mars sync` — pull latest across all repos
• `mars exec "npm test" --tag frontend` — run commands on tagged subsets

The tag system is the key workflow enabler. Tag repos by team, by function, by whatever makes sense — then target operations at specific groups. Run frontend tests without touching backend repos. Create a branch only where you need it.

**Technical choices:**

• Pure bash 3.2+ — works on every Mac out of the box
• Zero dependencies beyond git
• Single-file distribution

Install: `npm i -g @dean0x/mars` or `brew install dean0x/tap/mars`

If you work with polyrepo setups, I'd love your feedback: https://github.com/dean0x/mars
