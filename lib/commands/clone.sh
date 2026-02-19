#!/usr/bin/env bash
# Mars CLI - clone command
# Clone configured repositories with per-repo progress

cmd_clone() {
    local tag=""
    local force=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tag)
                tag="$2"
                shift 2
                ;;
            --force|-f)
                force=1
                shift
                ;;
            *)
                ui_step_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    config_require_workspace || return 1

    ui_intro "Mars - Clone Repositories"

    local repos
    repos=$(config_get_repos "$tag")

    if [[ -z "$repos" ]]; then
        if [[ -n "$tag" ]]; then
            ui_step_error "No repositories found with tag: $tag"
        else
            ui_step_error "No repositories configured. Run 'mars add <url>' first."
        fi
        ui_outro_cancel "Nothing to clone"
        return 1
    fi

    # Count total repos
    local total=0
    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        total=$((total + 1))
    done <<< "$repos"

    local current=0
    local success_count=0
    local skip_count=0
    local fail_count=0

    # Clone each repo with spinner feedback
    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        current=$((current + 1))

        local url
        url=$(yaml_get_url "$repo")
        local path
        path=$(yaml_get_path "$repo")
        local full_path="$MARS_REPOS_DIR/$path"

        # Already cloned?
        if [[ -d "$full_path" ]] && [[ $force -eq 0 ]]; then
            ui_step_done "Already cloned:" "$path"
            skip_count=$((skip_count + 1))
            continue
        fi

        # Remove existing directory if force
        if [[ -d "$full_path" ]] && [[ $force -eq 1 ]]; then
            rm -rf "$full_path"
        fi

        # Show spinner while cloning
        ui_spinner_start "Cloning $path... ($current/$total)"

        local clone_err
        if clone_err=$(git clone --quiet "$url" "$full_path" 2>&1); then
            ui_spinner_stop
            ui_step_done "Cloned:" "$path"
            success_count=$((success_count + 1))
        else
            ui_spinner_error "Failed to clone: $path"
            if [[ -n "$clone_err" ]]; then
                ui_info "$(ui_dim "$clone_err")"
            fi
            fail_count=$((fail_count + 1))
        fi
    done <<< "$repos"

    # Summary
    ui_bar_line

    if [[ $fail_count -eq 0 ]]; then
        local msg="Cloned $success_count repositories successfully"
        if [[ $skip_count -gt 0 ]]; then
            msg="$msg, $skip_count already cloned"
        fi
        ui_outro "$msg"
    else
        ui_outro_cancel "Cloned $success_count, failed $fail_count"
        return 1
    fi

    return 0
}
