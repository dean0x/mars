#!/usr/bin/env bash
# Mars CLI - sync command
# Pull latest changes across repositories

cmd_sync() {
    local tag=""
    local rebase=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tag)
                tag="$2"
                shift 2
                ;;
            --rebase|-r)
                rebase=1
                shift
                ;;
            *)
                ui_step_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    config_require_workspace || return 1

    ui_intro "Mars - Sync Repositories"

    local repos
    repos=$(config_get_repos "$tag")

    if [[ -z "$repos" ]]; then
        ui_step_error "No repositories configured"
        ui_outro_cancel "Nothing to sync"
        return 1
    fi

    local success_count=0
    local skip_count=0
    local fail_count=0
    local conflict_repos=()

    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue

        local path
        path=$(yaml_get_path "$repo")
        local full_path="$MARS_REPOS_DIR/$path"

        if [[ ! -d "$full_path" ]]; then
            ui_step_done "Skipped (not cloned):" "$path"
            skip_count=$((skip_count + 1))
            continue
        fi

        # Fetch first
        git_fetch "$full_path"

        # Pull
        local pull_args=""
        [[ $rebase -eq 1 ]] && pull_args="--rebase"

        if git_pull "$full_path" $pull_args; then
            # Check what happened
            if [[ "$GIT_OUTPUT" == *"Already up to date"* ]]; then
                ui_step_done "Up to date:" "$path"
            else
                ui_step_done "Updated:" "$path"
            fi
            success_count=$((success_count + 1))
        else
            # Check for conflicts
            if [[ "$GIT_ERROR" == *"conflict"* ]] || [[ "$GIT_ERROR" == *"CONFLICT"* ]]; then
                ui_step_error "Conflict: $path"
                conflict_repos+=("$path")
            else
                ui_step_error "Failed: $path"
            fi
            fail_count=$((fail_count + 1))
        fi
    done <<< "$repos"

    ui_bar_line

    if [[ ${#conflict_repos[@]} -gt 0 ]]; then
        ui_info "$(ui_yellow "Repositories with conflicts:")"
        for r in "${conflict_repos[@]}"; do
            ui_info "  $(ui_yellow "$r")"
        done
    fi

    if [[ $fail_count -eq 0 ]]; then
        local msg="Synced $success_count repo(s)"
        [[ $skip_count -gt 0 ]] && msg+=", $skip_count skipped"
        ui_outro "$msg"
    else
        ui_outro_cancel "$success_count synced, $fail_count failed"
        return 1
    fi

    return 0
}
