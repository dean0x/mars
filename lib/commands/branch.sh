#!/usr/bin/env bash
# Mars CLI - branch command
# Create a new branch across repositories

cmd_branch() {
    local branch_name=""
    local tag=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tag)
                tag="$2"
                shift 2
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
        ui_step_error "Usage: mars branch <branch-name> [--tag TAG]"
        return 1
    fi

    config_require_workspace || return 1

    ui_intro "Mars - Create Branch: $branch_name"

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

        # Check if branch already exists
        if git_branch_exists "$full_path" "$branch_name"; then
            # Try to checkout instead
            if git_checkout "$full_path" "$branch_name"; then
                ui_step_done "Checked out existing:" "$path → $branch_name"
                success_count=$((success_count + 1))
            else
                ui_step_error "Failed to checkout existing branch: $path"
                fail_count=$((fail_count + 1))
            fi
            continue
        fi

        # Create new branch
        if git_branch "$full_path" "$branch_name"; then
            ui_step_done "Created:" "$path → $branch_name"
            success_count=$((success_count + 1))
        else
            ui_step_error "Failed: $path - $GIT_ERROR"
            fail_count=$((fail_count + 1))
        fi
    done <<< "$repos"

    ui_bar_line

    if [[ $fail_count -eq 0 ]]; then
        local msg="Branch '$branch_name' created on $success_count repo(s)"
        [[ $skip_count -gt 0 ]] && msg+=", $skip_count skipped"
        ui_outro "$msg"
    else
        ui_outro_cancel "$success_count succeeded, $fail_count failed"
        return 1
    fi

    return 0
}
