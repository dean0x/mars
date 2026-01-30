#!/usr/bin/env bash
# Mars CLI - list command
# List configured repositories

cmd_list() {
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

    ui_intro "Mars - Configured Repositories"

    local repos
    repos=$(config_get_repos "$tag")

    if [[ -z "$repos" ]]; then
        if [[ -n "$tag" ]]; then
            ui_info "No repositories found with tag: $tag"
        else
            ui_info "No repositories configured"
            ui_bar_line
            ui_info "$(ui_dim "Run 'mars add <url>' to add a repository")"
        fi
        ui_outro "List complete"
        return 0
    fi

    # Table header
    ui_table_header "Path" "Tags" "Cloned"

    local total=0
    local cloned=0

    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        ((total++))

        local path
        path=$(yaml_get_path "$repo")
        local tags
        tags=$(yaml_get_tags "$repo")
        local full_path="$MARS_REPOS_DIR/$path"

        local cloned_text
        if [[ -d "$full_path" ]]; then
            cloned_text="$(ui_green "yes")"
            ((cloned++))
        else
            cloned_text="$(ui_dim "no")"
        fi

        local tags_text
        if [[ -n "$tags" ]]; then
            tags_text="$tags"
        else
            tags_text="$(ui_dim "-")"
        fi

        ui_table_row "$path" "$tags_text" "$cloned_text"
    done <<< "$repos"

    ui_bar_line
    ui_info "Total: $total repositories, $cloned cloned"

    ui_outro "List complete"

    return 0
}
