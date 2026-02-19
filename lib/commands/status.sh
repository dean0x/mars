#!/usr/bin/env bash
# Mars CLI - status command
# Show git status across all repositories

cmd_status() {
    local tag=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tag)
                tag="$2"
                shift 2
                ;;
            *)
                ui_step_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    config_require_workspace || return 1

    ui_intro "Mars - Repository Status"

    local repos
    repos=$(config_get_repos "$tag")

    if [[ -z "$repos" ]]; then
        ui_step_error "No repositories configured"
        ui_outro_cancel "Nothing to show"
        return 1
    fi

    # Table header
    ui_table_widths 24 20 12 14
    ui_table_header "Repository" "Branch" "Status" "Sync"

    local not_cloned=0

    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue

        local path
        path=$(yaml_get_path "$repo")
        local full_path="$MARS_REPOS_DIR/$path"

        if [[ ! -d "$full_path" ]]; then
            ui_table_row "$path" "$(ui_dim "not cloned")" "-" "-"
            not_cloned=$((not_cloned + 1))
            continue
        fi

        # Get branch
        local branch
        branch=$(git_current_branch "$full_path")

        # Get dirty status
        local status_text
        if git_is_dirty "$full_path"; then
            status_text="$(ui_yellow "dirty")"
        else
            status_text="$(ui_green "clean")"
        fi

        # Get ahead/behind
        git_ahead_behind "$full_path"
        local sync_text=""

        if [[ $GIT_AHEAD -gt 0 ]] && [[ $GIT_BEHIND -gt 0 ]]; then
            sync_text="$(ui_yellow "↑$GIT_AHEAD ↓$GIT_BEHIND")"
        elif [[ $GIT_AHEAD -gt 0 ]]; then
            sync_text="$(ui_cyan "↑$GIT_AHEAD")"
        elif [[ $GIT_BEHIND -gt 0 ]]; then
            sync_text="$(ui_yellow "↓$GIT_BEHIND")"
        else
            sync_text="$(ui_green "synced")"
        fi

        ui_table_row "$path" "$branch" "$status_text" "$sync_text"
    done <<< "$repos"

    ui_bar_line

    if [[ $not_cloned -gt 0 ]]; then
        ui_info "$(ui_dim "$not_cloned repository(ies) not cloned. Run 'mars clone' to clone them.")"
    fi

    ui_outro "Status complete"

    return 0
}
