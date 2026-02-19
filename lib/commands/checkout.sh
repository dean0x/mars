#!/usr/bin/env bash
# Mars CLI - checkout command
# Checkout a branch across repositories

cmd_checkout() {
    local branch_name=""
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
            -*)
                ui_step_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$branch_name" ]]; then
                    branch_name="$1"
                else
                    ui_step_error "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$branch_name" ]]; then
        ui_step_error "Usage: mars checkout <branch-name> [--tag TAG] [--force]"
        return 1
    fi

    config_require_workspace || return 1

    ui_intro "Mars - Checkout Branch: $branch_name"

    local repos
    repos=$(config_get_repos "$tag")

    if [[ -z "$repos" ]]; then
        ui_step_error "No repositories configured"
        ui_outro_cancel "Nothing to do"
        return 1
    fi

    local success_count=0
    local skip_count=0
    local fail_count=0
    local dirty_repos=()

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

        # Check for uncommitted changes
        if git_is_dirty "$full_path" && [[ $force -eq 0 ]]; then
            ui_step_error "Uncommitted changes: $path"
            dirty_repos+=("$path")
            fail_count=$((fail_count + 1))
            continue
        fi

        # Check if branch exists
        if ! git_branch_exists "$full_path" "$branch_name"; then
            ui_step_error "Branch not found: $path"
            fail_count=$((fail_count + 1))
            continue
        fi

        # Checkout
        if git_checkout "$full_path" "$branch_name"; then
            ui_step_done "Checked out:" "$path → $branch_name"
            success_count=$((success_count + 1))
        else
            ui_step_error "Failed: $path - $GIT_ERROR"
            fail_count=$((fail_count + 1))
        fi
    done <<< "$repos"

    ui_bar_line

    if [[ ${#dirty_repos[@]} -gt 0 ]]; then
        ui_info "$(ui_yellow "Hint: Use --force to checkout despite uncommitted changes")"
        ui_bar_line
    fi

    if [[ $fail_count -eq 0 ]]; then
        local msg="Checked out '$branch_name' on $success_count repo(s)"
        [[ $skip_count -gt 0 ]] && msg+=", $skip_count skipped"
        ui_outro "$msg"
    else
        ui_outro_cancel "$success_count succeeded, $fail_count failed"
        return 1
    fi

    return 0
}
