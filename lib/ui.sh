#!/usr/bin/env bash
# Mars CLI - UI Components (Clack-style)
# Provides terminal UI primitives with Unicode/ASCII fallback

# Detect color support
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    UI_COLOR=1
else
    UI_COLOR=0
fi

# Detect Unicode support
if [[ "${LANG:-}" == *UTF-8* ]] || [[ "${LC_ALL:-}" == *UTF-8* ]]; then
    UI_UNICODE=1
else
    UI_UNICODE=0
fi

# --- Symbols ---
if [[ "$UI_UNICODE" -eq 1 ]]; then
    S_STEP_ACTIVE="◆"
    S_STEP_DONE="◇"
    S_STEP_ERROR="▲"
    S_STEP_CANCEL="■"
    S_BAR="│"
    S_BAR_START="┌"
    S_BAR_END="└"
    S_SPINNER_FRAMES=("◒" "◐" "◓" "◑")
    S_CHECKBOX_ON="◼"
    S_CHECKBOX_OFF="◻"
    S_RADIO_ON="●"
    S_RADIO_OFF="○"
else
    S_STEP_ACTIVE="*"
    S_STEP_DONE="+"
    S_STEP_ERROR="!"
    S_STEP_CANCEL="x"
    S_BAR="|"
    S_BAR_START="/"
    S_BAR_END="\\"
    S_SPINNER_FRAMES=("-" "\\" "|" "/")
    S_CHECKBOX_ON="[x]"
    S_CHECKBOX_OFF="[ ]"
    S_RADIO_ON="(*)"
    S_RADIO_OFF="( )"
fi

# --- Colors ---
ui_reset() {
    [[ "$UI_COLOR" -eq 1 ]] && printf '\033[0m' || true
}

ui_cyan() {
    [[ "$UI_COLOR" -eq 1 ]] && printf '\033[36m%s\033[0m' "$1" || printf '%s' "$1"
}

ui_green() {
    [[ "$UI_COLOR" -eq 1 ]] && printf '\033[32m%s\033[0m' "$1" || printf '%s' "$1"
}

ui_yellow() {
    [[ "$UI_COLOR" -eq 1 ]] && printf '\033[33m%s\033[0m' "$1" || printf '%s' "$1"
}

ui_red() {
    [[ "$UI_COLOR" -eq 1 ]] && printf '\033[31m%s\033[0m' "$1" || printf '%s' "$1"
}

ui_dim() {
    [[ "$UI_COLOR" -eq 1 ]] && printf '\033[2m%s\033[0m' "$1" || printf '%s' "$1"
}

ui_bold() {
    [[ "$UI_COLOR" -eq 1 ]] && printf '\033[1m%s\033[0m' "$1" || printf '%s' "$1"
}

# --- Bar Components ---
ui_bar() {
    ui_dim "$S_BAR"
}

ui_bar_start() {
    ui_dim "$S_BAR_START"
}

ui_bar_end() {
    ui_dim "$S_BAR_END"
}

# --- Layout Components ---

# Intro: Start of a section
# Usage: ui_intro "Title"
ui_intro() {
    local title="$1"
    printf '%s  %s\n' "$(ui_bar_start)" "$(ui_cyan "$title")"
    printf '%s\n' "$(ui_bar)"
}

# Outro: End of a section
# Usage: ui_outro "Message"
ui_outro() {
    local message="$1"
    printf '%s\n' "$(ui_bar)"
    printf '%s  %s\n' "$(ui_bar_end)" "$(ui_green "$message")"
}

# Outro with cancel
ui_outro_cancel() {
    local message="$1"
    printf '%s\n' "$(ui_bar)"
    printf '%s  %s\n' "$(ui_bar_end)" "$(ui_red "$message")"
}

# Step: Active prompt
# Usage: ui_step "Label"
ui_step() {
    local label="$1"
    printf '%s  %s\n' "$(ui_cyan "$S_STEP_ACTIVE")" "$label"
}

# Step done: Completed step
# Usage: ui_step_done "Label" "value"
ui_step_done() {
    local label="$1"
    local value="${2:-}"
    if [[ -n "$value" ]]; then
        printf '%s  %s %s\n' "$(ui_green "$S_STEP_DONE")" "$label" "$(ui_dim "$value")"
    else
        printf '%s  %s\n' "$(ui_green "$S_STEP_DONE")" "$label"
    fi
}

# Step error
ui_step_error() {
    local message="$1"
    printf '%s  %s\n' "$(ui_yellow "$S_STEP_ERROR")" "$(ui_yellow "$message")"
}

# Step cancel
ui_step_cancel() {
    local message="$1"
    printf '%s  %s\n' "$(ui_red "$S_STEP_CANCEL")" "$(ui_red "$message")"
}

# Info line (continuation)
ui_info() {
    local message="$1"
    printf '%s  %s\n' "$(ui_bar)" "$message"
}

# Empty bar line
ui_bar_line() {
    printf '%s\n' "$(ui_bar)"
}

# --- Interactive Components ---

# Text input
# Usage: result=$(ui_text "Prompt" "default")
# Returns: user input or default
ui_text() {
    local prompt="$1"
    local default="${2:-}"
    local input

    ui_step "$prompt"
    if [[ -n "$default" ]]; then
        printf '%s  ' "$(ui_bar)"
        read -r -p "" -e -i "$default" input
    else
        printf '%s  ' "$(ui_bar)"
        read -r input
    fi

    # Return default if empty
    if [[ -z "$input" ]]; then
        input="$default"
    fi

    printf '%s' "$input"
}

# Confirm (y/n)
# Usage: if ui_confirm "Question?"; then ... fi
ui_confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local hint
    local response

    if [[ "$default" == "y" ]]; then
        hint="Y/n"
    else
        hint="y/N"
    fi

    ui_step "$prompt ($hint)"
    printf '%s  ' "$(ui_bar)"
    read -r -n 1 response
    printf '\n'

    # Handle empty (use default)
    if [[ -z "$response" ]]; then
        response="$default"
    fi

    [[ "$response" =~ ^[Yy]$ ]]
}

# Select from options
# Usage: result=$(ui_select "Prompt" "opt1" "opt2" "opt3")
# Returns: selected option
ui_select() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=0
    local count=${#options[@]}
    local key

    ui_step "$prompt"

    # Save cursor position and hide cursor
    printf '\033[?25l'

    while true; do
        # Draw options
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                printf '%s  %s %s\n' "$(ui_bar)" "$(ui_cyan "$S_RADIO_ON")" "${options[$i]}"
            else
                printf '%s  %s %s\n' "$(ui_bar)" "$(ui_dim "$S_RADIO_OFF")" "$(ui_dim "${options[$i]}")"
            fi
        done

        # Read key
        read -rsn1 key

        # Handle arrow keys (escape sequences)
        if [[ "$key" == $'\033' ]]; then
            read -rsn2 key
            case "$key" in
                '[A') # Up
                    ((selected > 0)) && ((selected--))
                    ;;
                '[B') # Down
                    ((selected < count - 1)) && selected=$((selected + 1))
                    ;;
            esac
        elif [[ "$key" == "" ]]; then
            # Enter pressed
            break
        elif [[ "$key" == "j" ]]; then
            ((selected < count - 1)) && selected=$((selected + 1))
        elif [[ "$key" == "k" ]]; then
            ((selected > 0)) && ((selected--))
        fi

        # Move cursor up to redraw
        printf '\033[%dA' "$count"
    done

    # Show cursor
    printf '\033[?25h'

    printf '%s' "${options[$selected]}"
}

# --- Spinner ---
# Usage:
#   ui_spinner_start "Loading..."
#   ... do work ...
#   ui_spinner_stop "Done!" # or ui_spinner_stop
_SPINNER_PID=""
_SPINNER_MSG=""

ui_spinner_start() {
    local message="$1"
    _SPINNER_MSG="$message"

    (
        local i=0
        local frame_count=${#S_SPINNER_FRAMES[@]}

        while true; do
            printf '\r%s  %s %s' "$(ui_bar)" "$(ui_cyan "${S_SPINNER_FRAMES[$i]}")" "$message"
            ((i = (i + 1) % frame_count))
            sleep 0.1
        done
    ) &
    _SPINNER_PID=$!

    # Ensure cleanup on script exit
    trap 'ui_spinner_stop 2>/dev/null' EXIT
}

ui_spinner_stop() {
    local final_message="${1:-}"

    if [[ -n "$_SPINNER_PID" ]] && kill -0 "$_SPINNER_PID" 2>/dev/null; then
        kill "$_SPINNER_PID" 2>/dev/null
        wait "$_SPINNER_PID" 2>/dev/null || true
    fi
    _SPINNER_PID=""

    # Clear spinner line
    printf '\r\033[K'

    # Show final message if provided
    if [[ -n "$final_message" ]]; then
        ui_step_done "$final_message"
    fi
}

ui_spinner_error() {
    local message="$1"

    if [[ -n "$_SPINNER_PID" ]] && kill -0 "$_SPINNER_PID" 2>/dev/null; then
        kill "$_SPINNER_PID" 2>/dev/null
        wait "$_SPINNER_PID" 2>/dev/null || true
    fi
    _SPINNER_PID=""

    printf '\r\033[K'
    ui_step_error "$message"
}

# --- Progress ---
# Usage: ui_progress "message" current total
ui_progress() {
    local message="$1"
    local current="$2"
    local total="$3"
    local percent=$((current * 100 / total))
    local bar_width=20
    local filled=$((percent * bar_width / 100))
    local empty=$((bar_width - filled))

    printf '\r%s  ' "$(ui_bar)"
    printf '%s [' "$message"
    printf '%*s' "$filled" '' | tr ' ' '='
    printf '%*s' "$empty" '' | tr ' ' ' '
    printf '] %d%%' "$percent"
}

# --- Table ---
# Usage: ui_table_header "Col1" "Col2" "Col3"
#        ui_table_row "val1" "val2" "val3"
_TABLE_WIDTHS=()

ui_table_header() {
    local cols=("$@")
    _TABLE_WIDTHS=()

    printf '%s  ' "$(ui_bar)"
    for col in "${cols[@]}"; do
        printf '%-20s' "$(ui_bold "$col")"
        _TABLE_WIDTHS+=("20")
    done
    printf '\n'

    # Separator
    printf '%s  ' "$(ui_bar)"
    for _ in "${cols[@]}"; do
        printf '%-20s' "$(ui_dim "────────────────────")"
    done
    printf '\n'
}

ui_table_row() {
    local vals=("$@")

    printf '%s  ' "$(ui_bar)"
    for val in "${vals[@]}"; do
        printf '%-20s' "$val"
    done
    printf '\n'
}

# --- Utilities ---

# Clear line
ui_clear_line() {
    printf '\r\033[K'
}

# Move cursor up N lines
ui_cursor_up() {
    local n="${1:-1}"
    printf '\033[%dA' "$n"
}

# Hide cursor
ui_cursor_hide() {
    printf '\033[?25l'
}

# Show cursor
ui_cursor_show() {
    printf '\033[?25h'
}

# Ensure cursor is shown on exit
trap 'ui_cursor_show' EXIT
