#!/usr/bin/env bash
# Mars CLI - init command
# Interactive workspace initialization

cmd_init() {
    local workspace_name=""
    local create_claude=0

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

    # Ask about claude config
    if ui_confirm "Create claude.md and .claude/ for shared config?"; then
        create_claude=1
        ui_step_done "Claude config: enabled"
    else
        ui_step_done "Claude config: skipped"
    fi

    ui_bar_line

    # Initialize workspace
    if ! config_init "$workspace_name"; then
        ui_step_error "Failed to initialize workspace"
        return 1
    fi

    # Create claude files if requested
    if [[ $create_claude -eq 1 ]]; then
        mkdir -p ".claude"
        cat > "claude.md" << 'EOF'
# Workspace Configuration

This is a shared Claude configuration for the workspace.
Add your project-specific instructions here.
EOF
        ui_step_done "Created claude.md"
        ui_step_done "Created .claude/"
    fi

    ui_step_done "Created mars.yaml"
    ui_step_done "Created .gitignore"
    ui_step_done "Created repos/ directory"

    ui_outro "Workspace initialized! Run 'mars add <url>' to add repositories."

    return 0
}
