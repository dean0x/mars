#!/usr/bin/env bash
# Mars CLI - init command
# Interactive workspace initialization

cmd_init() {
    local workspace_name=""

    # Check if already initialized
    if [[ -f "mars.yaml" ]]; then
        ui_step_error "Workspace already initialized in this directory"
        return 1
    fi

    ui_intro "Mars - Multi Agentic Repo Workspace"

    # Get workspace name
    ui_step "Workspace name?"
    printf '%s  ' "$(ui_bar)"
    read -r workspace_name

    if [[ -z "$workspace_name" ]]; then
        ui_outro_cancel "Cancelled - workspace name is required"
        return 1
    fi

    ui_step_done "Workspace:" "$workspace_name"
    ui_bar_line

    # Initialize workspace
    if ! config_init "$workspace_name"; then
        ui_step_error "Failed to initialize workspace"
        return 1
    fi

    ui_step_done "Created mars.yaml"
    ui_step_done "Created .gitignore"
    ui_step_done "Created repos/ directory"

    ui_outro "Workspace initialized! Run 'mars add <url>' to add repositories."

    return 0
}
