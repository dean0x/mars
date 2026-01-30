#!/usr/bin/env bash
# Mars CLI - Git Operations
# Wrapper functions for git commands with consistent error handling

# Result pattern: functions return 0 on success, non-zero on failure
# Output is captured in global variables to avoid subshell issues

GIT_OUTPUT=""
GIT_ERROR=""

# Clone a repository
# Usage: git_clone "url" "target_dir"
# Returns: 0 on success, 1 on failure
git_clone() {
    local url="$1"
    local target="$2"

    GIT_OUTPUT=""
    GIT_ERROR=""

    if [[ -d "$target" ]]; then
        GIT_ERROR="Directory already exists: $target"
        return 1
    fi

    if GIT_OUTPUT=$(git clone --progress "$url" "$target" 2>&1); then
        return 0
    else
        GIT_ERROR="$GIT_OUTPUT"
        return 1
    fi
}

# Get repository status
# Usage: git_status "repo_dir"
# Sets: GIT_OUTPUT with status info
# Returns: 0 on success
git_status() {
    local repo_dir="$1"

    GIT_OUTPUT=""
    GIT_ERROR=""

    if [[ ! -d "$repo_dir/.git" ]]; then
        GIT_ERROR="Not a git repository: $repo_dir"
        return 1
    fi

    if ! GIT_OUTPUT=$(git -C "$repo_dir" status --porcelain 2>&1); then
        GIT_ERROR="$GIT_OUTPUT"
        return 1
    fi

    return 0
}

# Check if repo has uncommitted changes
# Usage: if git_is_dirty "repo_dir"; then ...
git_is_dirty() {
    local repo_dir="$1"

    git_status "$repo_dir" || return 1
    [[ -n "$GIT_OUTPUT" ]]
}

# Get current branch name
# Usage: branch=$(git_current_branch "repo_dir")
git_current_branch() {
    local repo_dir="$1"

    git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Create a new branch
# Usage: git_branch "repo_dir" "branch_name"
# Returns: 0 on success
git_branch() {
    local repo_dir="$1"
    local branch_name="$2"

    GIT_OUTPUT=""
    GIT_ERROR=""

    if [[ ! -d "$repo_dir/.git" ]]; then
        GIT_ERROR="Not a git repository: $repo_dir"
        return 1
    fi

    # Check if branch already exists
    if git -C "$repo_dir" rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        GIT_ERROR="Branch already exists: $branch_name"
        return 1
    fi

    if ! GIT_OUTPUT=$(git -C "$repo_dir" checkout -b "$branch_name" 2>&1); then
        GIT_ERROR="$GIT_OUTPUT"
        return 1
    fi

    return 0
}

# Checkout existing branch
# Usage: git_checkout "repo_dir" "branch_name"
# Returns: 0 on success
git_checkout() {
    local repo_dir="$1"
    local branch_name="$2"

    GIT_OUTPUT=""
    GIT_ERROR=""

    if [[ ! -d "$repo_dir/.git" ]]; then
        GIT_ERROR="Not a git repository: $repo_dir"
        return 1
    fi

    if ! GIT_OUTPUT=$(git -C "$repo_dir" checkout "$branch_name" 2>&1); then
        GIT_ERROR="$GIT_OUTPUT"
        return 1
    fi

    return 0
}

# Pull latest changes
# Usage: git_pull "repo_dir" [--rebase]
# Returns: 0 on success
git_pull() {
    local repo_dir="$1"
    local rebase="${2:-}"

    GIT_OUTPUT=""
    GIT_ERROR=""

    if [[ ! -d "$repo_dir/.git" ]]; then
        GIT_ERROR="Not a git repository: $repo_dir"
        return 1
    fi

    local args=()
    [[ "$rebase" == "--rebase" ]] && args+=("--rebase")

    if ! GIT_OUTPUT=$(git -C "$repo_dir" pull "${args[@]}" 2>&1); then
        GIT_ERROR="$GIT_OUTPUT"
        return 1
    fi

    return 0
}

# Fetch from remote
# Usage: git_fetch "repo_dir"
git_fetch() {
    local repo_dir="$1"

    GIT_OUTPUT=""
    GIT_ERROR=""

    if [[ ! -d "$repo_dir/.git" ]]; then
        GIT_ERROR="Not a git repository: $repo_dir"
        return 1
    fi

    if ! GIT_OUTPUT=$(git -C "$repo_dir" fetch 2>&1); then
        GIT_ERROR="$GIT_OUTPUT"
        return 1
    fi

    return 0
}

# Get ahead/behind counts relative to upstream
# Usage: git_ahead_behind "repo_dir"
# Sets: GIT_AHEAD, GIT_BEHIND
GIT_AHEAD=0
GIT_BEHIND=0

git_ahead_behind() {
    local repo_dir="$1"

    GIT_AHEAD=0
    GIT_BEHIND=0

    if [[ ! -d "$repo_dir/.git" ]]; then
        return 1
    fi

    local upstream
    upstream=$(git -C "$repo_dir" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null) || return 0

    local counts
    counts=$(git -C "$repo_dir" rev-list --left-right --count "$upstream...HEAD" 2>/dev/null) || return 0

    GIT_BEHIND=$(echo "$counts" | cut -f1)
    GIT_AHEAD=$(echo "$counts" | cut -f2)

    return 0
}

# Get remote URL
# Usage: url=$(git_remote_url "repo_dir")
git_remote_url() {
    local repo_dir="$1"

    git -C "$repo_dir" remote get-url origin 2>/dev/null
}

# Check if branch exists (local or remote)
# Usage: if git_branch_exists "repo_dir" "branch_name"; then ...
git_branch_exists() {
    local repo_dir="$1"
    local branch_name="$2"

    git -C "$repo_dir" rev-parse --verify "$branch_name" >/dev/null 2>&1 ||
    git -C "$repo_dir" rev-parse --verify "origin/$branch_name" >/dev/null 2>&1
}

# Stash changes
# Usage: git_stash "repo_dir"
git_stash() {
    local repo_dir="$1"

    GIT_OUTPUT=""
    GIT_ERROR=""

    if ! GIT_OUTPUT=$(git -C "$repo_dir" stash 2>&1); then
        GIT_ERROR="$GIT_OUTPUT"
        return 1
    fi

    return 0
}

# Pop stash
# Usage: git_stash_pop "repo_dir"
git_stash_pop() {
    local repo_dir="$1"

    GIT_OUTPUT=""
    GIT_ERROR=""

    if ! GIT_OUTPUT=$(git -C "$repo_dir" stash pop 2>&1); then
        GIT_ERROR="$GIT_OUTPUT"
        return 1
    fi

    return 0
}

# Get short commit hash
# Usage: hash=$(git_short_hash "repo_dir")
git_short_hash() {
    local repo_dir="$1"

    git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null
}

# Run arbitrary git command
# Usage: git_exec "repo_dir" "command" "args..."
git_exec() {
    local repo_dir="$1"
    shift
    local cmd=("$@")

    GIT_OUTPUT=""
    GIT_ERROR=""

    if [[ ! -d "$repo_dir/.git" ]]; then
        GIT_ERROR="Not a git repository: $repo_dir"
        return 1
    fi

    if ! GIT_OUTPUT=$(git -C "$repo_dir" "${cmd[@]}" 2>&1); then
        GIT_ERROR="$GIT_OUTPUT"
        return 1
    fi

    return 0
}
