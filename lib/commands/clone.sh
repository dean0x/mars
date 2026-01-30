#!/usr/bin/env bash
# Mars CLI - clone command
# Clone configured repositories with parallel execution

# Maximum concurrent clone jobs
CLONE_PARALLEL_LIMIT=4

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

    # Count repos
    local total=0
    local to_clone=()
    local already_cloned=()

    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        ((total++))

        local path
        path=$(yaml_get_path "$repo")
        local full_path="$MARS_REPOS_DIR/$path"

        if [[ -d "$full_path" ]] && [[ $force -eq 0 ]]; then
            already_cloned+=("$repo")
        else
            to_clone+=("$repo")
        fi
    done <<< "$repos"

    # Report already cloned
    for repo in "${already_cloned[@]}"; do
        local path
        path=$(yaml_get_path "$repo")
        ui_step_done "Already cloned:" "$path"
    done

    if [[ ${#to_clone[@]} -eq 0 ]]; then
        ui_outro "All repositories already cloned"
        return 0
    fi

    ui_bar_line
    ui_info "Cloning ${#to_clone[@]} of $total repositories..."
    ui_bar_line

    # Clone with parallelism
    local pids=()
    local repo_for_pid=()
    local success_count=0
    local fail_count=0
    local failed_repos=()

    for repo in "${to_clone[@]}"; do
        local url
        url=$(yaml_get_url "$repo")
        local path
        path=$(yaml_get_path "$repo")
        local full_path="$MARS_REPOS_DIR/$path"

        # Remove existing directory if force
        if [[ -d "$full_path" ]] && [[ $force -eq 1 ]]; then
            rm -rf "$full_path"
        fi

        # Wait if at parallel limit
        while [[ ${#pids[@]} -ge $CLONE_PARALLEL_LIMIT ]]; do
            _clone_wait_one
        done

        # Start clone in background
        (
            if git clone --quiet "$url" "$full_path" 2>/dev/null; then
                exit 0
            else
                exit 1
            fi
        ) &

        pids+=($!)
        repo_for_pid+=("$repo")
    done

    # Wait for remaining jobs
    while [[ ${#pids[@]} -gt 0 ]]; do
        _clone_wait_one
    done

    # Summary
    ui_bar_line

    if [[ $fail_count -eq 0 ]]; then
        ui_outro "Cloned $success_count repositories successfully"
    else
        for repo in "${failed_repos[@]}"; do
            local path
            path=$(yaml_get_path "$repo")
            ui_step_error "Failed: $path"
        done
        ui_outro_cancel "Cloned $success_count, failed $fail_count"
        return 1
    fi

    return 0
}

# Helper to wait for one clone job
_clone_wait_one() {
    if [[ ${#pids[@]} -eq 0 ]]; then
        return
    fi

    # Wait for any process to complete
    local pid
    for i in "${!pids[@]}"; do
        pid="${pids[$i]}"
        if ! kill -0 "$pid" 2>/dev/null; then
            # Process finished
            wait "$pid"
            local exit_code=$?
            local repo="${repo_for_pid[$i]}"
            local path
            path=$(yaml_get_path "$repo")

            if [[ $exit_code -eq 0 ]]; then
                ui_step_done "Cloned:" "$path"
                ((success_count++))
            else
                ui_step_error "Failed to clone: $path"
                ((fail_count++))
                failed_repos+=("$repo")
            fi

            # Remove from arrays
            unset 'pids[i]'
            unset 'repo_for_pid[i]'
            pids=("${pids[@]}")
            repo_for_pid=("${repo_for_pid[@]}")
            return
        fi
    done

    # If all still running, sleep briefly
    sleep 0.1
}
