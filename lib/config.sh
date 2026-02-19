#!/usr/bin/env bash
# Mars CLI - Configuration Management
# Handles workspace detection and config loading/saving

MARS_WORKSPACE_ROOT=""
MARS_CONFIG_FILE=""
MARS_REPOS_DIR=""

# Find workspace root by searching upward for mars.yaml
# Usage: config_find_root [start_dir]
# Returns: 0 if found (sets MARS_WORKSPACE_ROOT), 1 if not found
config_find_root() {
    local start_dir="${1:-$PWD}"
    local current="$start_dir"

    while [[ "$current" != "/" ]]; do
        if [[ -f "$current/mars.yaml" ]]; then
            MARS_WORKSPACE_ROOT="$current"
            MARS_CONFIG_FILE="$current/mars.yaml"
            MARS_REPOS_DIR="$current/repos"
            return 0
        fi
        current="$(dirname "$current")"
    done

    return 1
}

# Initialize workspace in current directory
# Usage: config_init "workspace_name"
# Returns: 0 on success, 1 if already initialized
config_init() {
    local workspace_name="$1"
    local dir="${2:-$PWD}"

    if [[ -f "$dir/mars.yaml" ]]; then
        return 1
    fi

    MARS_WORKSPACE_ROOT="$dir"
    MARS_CONFIG_FILE="$dir/mars.yaml"
    MARS_REPOS_DIR="$dir/repos"

    # Set workspace name for yaml module
    YAML_WORKSPACE_NAME="$workspace_name"
    YAML_DEFAULTS_BRANCH="main"
    YAML_REPO_COUNT=0
    YAML_REPO_URLS=()
    YAML_REPO_PATHS=()
    YAML_REPO_TAGS=()

    # Create directory structure
    mkdir -p "$MARS_REPOS_DIR"

    # Write config
    yaml_write "$MARS_CONFIG_FILE"

    # Create .gitignore
    printf 'repos/\n' > "$dir/.gitignore"

    return 0
}

# Load configuration
# Usage: config_load
# Returns: 0 on success, 1 on failure
config_load() {
    if [[ -z "$MARS_CONFIG_FILE" ]] || [[ ! -f "$MARS_CONFIG_FILE" ]]; then
        return 1
    fi

    yaml_parse "$MARS_CONFIG_FILE"
}

# Save configuration
# Usage: config_save
config_save() {
    if [[ -z "$MARS_CONFIG_FILE" ]]; then
        return 1
    fi

    yaml_write "$MARS_CONFIG_FILE"
}

# Get repos (optionally filtered by tag)
# Usage: repos=$(config_get_repos [tag])
config_get_repos() {
    local tag="${1:-}"
    yaml_get_repos "$tag"
}

# Get repo count
# Usage: count=$(config_repo_count [tag])
config_repo_count() {
    local tag="${1:-}"
    local count=0
    local repos
    repos=$(config_get_repos "$tag")

    while IFS= read -r repo; do
        [[ -n "$repo" ]] && count=$((count + 1))
    done <<< "$repos"

    printf '%d' "$count"
}

# Check if repo directory exists
# Usage: if config_repo_exists "repo_index"; then ...
config_repo_exists() {
    local idx="$1"
    local path
    path=$(yaml_get_path "$idx")
    [[ -d "$MARS_REPOS_DIR/$path" ]]
}

# Get full path to repo
# Usage: full_path=$(config_repo_full_path "repo_index")
config_repo_full_path() {
    local idx="$1"
    local path
    path=$(yaml_get_path "$idx")
    printf '%s/%s' "$MARS_REPOS_DIR" "$path"
}

# Require workspace context
# Usage: config_require_workspace || return 1
# Prints error and returns 1 if not in workspace
config_require_workspace() {
    if ! config_find_root; then
        printf 'Error: Not in a Mars workspace. Run "mars init" first.\n' >&2
        return 1
    fi
    config_load
}

# Check if path is inside workspace
# Usage: if config_is_in_workspace "/some/path"; then ...
config_is_in_workspace() {
    local path="$1"
    [[ "$path" == "$MARS_WORKSPACE_ROOT"* ]]
}

# Get workspace name
config_workspace_name() {
    printf '%s' "$YAML_WORKSPACE_NAME"
}

# Get default branch
config_default_branch() {
    printf '%s' "$YAML_DEFAULTS_BRANCH"
}
