#!/usr/bin/env bash
# Mars CLI - add command
# Add a repository to the workspace configuration

cmd_add() {
    local url=""
    local path=""
    local tags=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tags)
                tags="$2"
                shift 2
                ;;
            --path)
                path="$2"
                shift 2
                ;;
            -*)
                ui_step_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$url" ]]; then
                    url="$1"
                else
                    ui_step_error "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$url" ]]; then
        ui_step_error "Usage: mars add <url> [--tags tag1,tag2] [--path custom-path]"
        return 1
    fi

    config_require_workspace || return 1

    # Derive path from URL if not provided
    if [[ -z "$path" ]]; then
        path=$(yaml_path_from_url "$url")
    fi

    # Check if repo already exists
    local i
    for ((i = 0; i < YAML_REPO_COUNT; i++)); do
        local existing_url
        existing_url=$(yaml_get_url "$i")
        if [[ "$existing_url" == "$url" ]]; then
            ui_step_error "Repository already configured: $url"
            return 1
        fi

        local existing_path
        existing_path=$(yaml_get_path "$i")
        if [[ "$existing_path" == "$path" ]]; then
            ui_step_error "Path already in use: $path"
            return 1
        fi
    done

    ui_intro "Mars - Add Repository"

    # Add to config
    yaml_add_repo "$url" "$path" "$tags"

    # Save config
    config_save

    ui_step_done "Added repository:" "$path"

    if [[ -n "$tags" ]]; then
        ui_info "Tags: $tags"
    fi

    ui_bar_line
    ui_info "$(ui_dim "Run 'mars clone' to clone the repository")"

    ui_outro "Repository added to workspace"

    return 0
}
