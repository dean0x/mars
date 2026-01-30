#!/usr/bin/env bash
# Mars CLI - exec command
# Run command in each repository

cmd_exec() {
    local command=""
    local tag=""
    local quiet=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tag)
                tag="$2"
                shift 2
                ;;
            --quiet|-q)
                quiet=1
                shift
                ;;
            --)
                shift
                command="$*"
                break
                ;;
            -*)
                ui_step_error "Unknown option: $1"
                return 1
                ;;
            *)
                # Everything else is the command
                command="$*"
                break
                ;;
        esac
    done

    if [[ -z "$command" ]]; then
        ui_step_error "Usage: mars exec \"<command>\" [--tag TAG]"
        return 1
    fi

    config_require_workspace || return 1

    ui_intro "Mars - Execute: $command"

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
            ((skip_count++))
            continue
        fi

        ui_step "Running in: $path"
        ui_bar_line

        # Execute command in repo directory
        local output
        local exit_code

        if output=$(cd "$full_path" && eval "$command" 2>&1); then
            exit_code=0
        else
            exit_code=$?
        fi

        # Show output if not quiet
        if [[ $quiet -eq 0 ]] && [[ -n "$output" ]]; then
            while IFS= read -r line; do
                printf '%s  %s\n' "$(ui_bar)" "$(ui_dim "$line")"
            done <<< "$output"
        fi

        if [[ $exit_code -eq 0 ]]; then
            ui_step_done "Success:" "$path"
            ((success_count++))
        else
            ui_step_error "Failed (exit $exit_code): $path"
            ((fail_count++))
        fi

        ui_bar_line
    done <<< "$repos"

    if [[ $fail_count -eq 0 ]]; then
        local msg="Executed on $success_count repo(s)"
        [[ $skip_count -gt 0 ]] && msg+=", $skip_count skipped"
        ui_outro "$msg"
    else
        ui_outro_cancel "$success_count succeeded, $fail_count failed"
        return 1
    fi

    return 0
}
