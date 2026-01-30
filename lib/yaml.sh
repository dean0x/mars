#!/usr/bin/env bash
# Mars CLI - Minimal YAML Parser
# Parses mars.yaml format only - not a general YAML parser
# Compatible with bash 3.2+ (no associative arrays)

# Global state - using parallel indexed arrays instead of associative arrays
YAML_WORKSPACE_NAME=""
YAML_DEFAULTS_BRANCH=""
YAML_REPO_COUNT=0

# Arrays indexed by repo number (0, 1, 2, ...)
# Access: ${YAML_REPO_URLS[$i]}
YAML_REPO_URLS=()
YAML_REPO_PATHS=()
YAML_REPO_TAGS=()

yaml_parse() {
    local file="$1"
    local line
    local in_repos=0
    local in_defaults=0
    local current_index=-1

    # Reset state
    YAML_WORKSPACE_NAME=""
    YAML_DEFAULTS_BRANCH="main"
    YAML_REPO_COUNT=0
    YAML_REPO_URLS=()
    YAML_REPO_PATHS=()
    YAML_REPO_TAGS=()

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Remove leading/trailing whitespace for comparison
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

        # Check section markers
        if [[ "$trimmed" == "repos:" ]]; then
            in_repos=1
            in_defaults=0
            continue
        elif [[ "$trimmed" == "defaults:" ]]; then
            in_repos=0
            in_defaults=1
            continue
        elif [[ "$trimmed" == "workspace:" ]]; then
            in_repos=0
            in_defaults=0
            continue
        fi

        # Parse workspace name
        if [[ "$trimmed" =~ ^name:[[:space:]]*[\"\']?([^\"\']+)[\"\']?$ ]]; then
            YAML_WORKSPACE_NAME="${BASH_REMATCH[1]}"
            continue
        fi

        # Parse defaults section
        if [[ $in_defaults -eq 1 ]]; then
            if [[ "$trimmed" =~ ^branch:[[:space:]]*(.+)$ ]]; then
                YAML_DEFAULTS_BRANCH="${BASH_REMATCH[1]}"
            fi
            continue
        fi

        # Parse repos section
        if [[ $in_repos -eq 1 ]]; then
            # New repo entry (starts with -)
            if [[ "$trimmed" =~ ^-[[:space:]]*url:[[:space:]]*(.+)$ ]]; then
                current_index=$((current_index + 1))
                local url="${BASH_REMATCH[1]}"
                YAML_REPO_URLS[$current_index]="$url"
                YAML_REPO_PATHS[$current_index]=$(yaml_path_from_url "$url")
                YAML_REPO_TAGS[$current_index]=""
                YAML_REPO_COUNT=$((YAML_REPO_COUNT + 1))
                continue
            fi

            # Continuation of current repo
            if [[ $current_index -ge 0 ]]; then
                if [[ "$trimmed" =~ ^path:[[:space:]]*(.+)$ ]]; then
                    YAML_REPO_PATHS[$current_index]="${BASH_REMATCH[1]}"
                elif [[ "$trimmed" =~ ^tags:[[:space:]]*\[([^\]]*)\]$ ]]; then
                    # Parse inline array: [tag1, tag2]
                    local tags_str="${BASH_REMATCH[1]}"
                    # Remove spaces and quotes
                    tags_str="${tags_str//[[:space:]]/}"
                    tags_str="${tags_str//\"/}"
                    tags_str="${tags_str//\'/}"
                    YAML_REPO_TAGS[$current_index]="$tags_str"
                fi
            fi
        fi
    done < "$file"

    return 0
}

# Extract repo name from URL
# Usage: yaml_path_from_url "git@github.com:org/repo.git"
# Returns: "repo"
yaml_path_from_url() {
    local url="$1"
    local name

    # Handle SSH URLs: git@github.com:org/repo.git
    if [[ "$url" =~ ([^/:]+)\.git$ ]]; then
        name="${BASH_REMATCH[1]}"
    # Handle HTTPS URLs: https://github.com/org/repo.git
    elif [[ "$url" =~ /([^/]+)\.git$ ]]; then
        name="${BASH_REMATCH[1]}"
    # Handle URLs without .git
    elif [[ "$url" =~ ([^/:]+)$ ]]; then
        name="${BASH_REMATCH[1]}"
    else
        name="repo"
    fi

    printf '%s' "$name"
}

# Get list of repo indices, optionally filtered by tag
# Usage: yaml_get_repos [tag]
# Returns: newline-separated list of indices (0, 1, 2, ...)
yaml_get_repos() {
    local filter_tag="${1:-}"
    local i

    for ((i = 0; i < YAML_REPO_COUNT; i++)); do
        if [[ -z "$filter_tag" ]]; then
            printf '%d\n' "$i"
        else
            local tags="${YAML_REPO_TAGS[$i]}"
            # Check if tag is in comma-separated list
            if [[ ",$tags," == *",$filter_tag,"* ]]; then
                printf '%d\n' "$i"
            fi
        fi
    done
}

# Get repo URL by index
yaml_get_url() {
    local idx="$1"
    printf '%s' "${YAML_REPO_URLS[$idx]:-}"
}

# Get repo path by index
yaml_get_path() {
    local idx="$1"
    printf '%s' "${YAML_REPO_PATHS[$idx]:-}"
}

# Get repo tags by index
yaml_get_tags() {
    local idx="$1"
    printf '%s' "${YAML_REPO_TAGS[$idx]:-}"
}

# Write mars.yaml
# Usage: yaml_write "path/to/mars.yaml"
yaml_write() {
    local file="$1"
    local i

    {
        printf 'version: 1\n\n'
        printf 'workspace:\n'
        printf '  name: "%s"\n\n' "$YAML_WORKSPACE_NAME"
        printf 'repos:\n'

        for ((i = 0; i < YAML_REPO_COUNT; i++)); do
            local url="${YAML_REPO_URLS[$i]}"
            local path="${YAML_REPO_PATHS[$i]}"
            local tags="${YAML_REPO_TAGS[$i]}"

            printf '  - url: %s\n' "$url"

            # Only write path if different from derived
            local derived
            derived=$(yaml_path_from_url "$url")
            if [[ "$path" != "$derived" ]]; then
                printf '    path: %s\n' "$path"
            fi

            # Write tags if present
            if [[ -n "$tags" ]]; then
                printf '    tags: [%s]\n' "$tags"
            fi
        done

        printf '\ndefaults:\n'
        printf '  branch: %s\n' "$YAML_DEFAULTS_BRANCH"
    } > "$file"
}

# Add a repo to the config
# Usage: yaml_add_repo "url" "path" "tags"
yaml_add_repo() {
    local url="$1"
    local path="${2:-}"
    local tags="${3:-}"

    local idx=$YAML_REPO_COUNT

    YAML_REPO_URLS[$idx]="$url"

    if [[ -z "$path" ]]; then
        path=$(yaml_path_from_url "$url")
    fi
    YAML_REPO_PATHS[$idx]="$path"
    YAML_REPO_TAGS[$idx]="$tags"

    YAML_REPO_COUNT=$((YAML_REPO_COUNT + 1))
}
