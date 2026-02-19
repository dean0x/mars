#!/usr/bin/env bash
# Mars CLI - Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/dean0x/mars/main/install.sh | bash
# Override version: MARS_VERSION=0.1.1 curl -fsSL ... | bash

set -euo pipefail

# Configuration
MARS_VERSION="${MARS_VERSION:-latest}"
MARS_INSTALL_DIR="${MARS_INSTALL_DIR:-$HOME/.mars}"
MARS_BIN_DIR="$MARS_INSTALL_DIR/bin"
MARS_REPO="dean0x/mars"

# Colors (if terminal supports it)
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    RED='\033[31m'
    GREEN='\033[32m'
    YELLOW='\033[33m'
    CYAN='\033[36m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    DIM=''
    RESET=''
fi

info() {
    printf "${CYAN}info${RESET}  %s\n" "$1"
}

success() {
    printf "${GREEN}done${RESET}  %s\n" "$1"
}

warn() {
    printf "${YELLOW}warn${RESET}  %s\n" "$1"
}

error() {
    printf "${RED}error${RESET} %s\n" "$1" >&2
}

# Detect shell
detect_shell() {
    local shell_name
    shell_name="$(basename "${SHELL:-/bin/bash}")"

    case "$shell_name" in
        bash)
            echo "$HOME/.bashrc"
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Check for required tools
check_requirements() {
    local missing=()

    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing+=("curl or wget")
    fi

    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing[*]}"
        exit 1
    fi
}

# Download file
download() {
    local url="$1"
    local output="$2"

    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget &> /dev/null; then
        wget -qO "$output" "$url"
    else
        error "No download tool available (need curl or wget)"
        exit 1
    fi
}

# Build download URL based on version
get_download_url() {
    if [[ "$MARS_VERSION" == "latest" ]]; then
        echo "https://github.com/$MARS_REPO/releases/latest/download/mars"
    else
        echo "https://github.com/$MARS_REPO/releases/download/v$MARS_VERSION/mars"
    fi
}

# Add to PATH in shell config
add_to_path() {
    local rc_file="$1"
    local path_line="export PATH=\"\$PATH:$MARS_BIN_DIR\""

    # Check if already added
    if [[ -f "$rc_file" ]] && grep -qF "$MARS_BIN_DIR" "$rc_file"; then
        return 0
    fi

    # Add to rc file
    {
        echo ""
        echo "# Mars CLI"
        echo "$path_line"
    } >> "$rc_file"

    return 0
}

# Main installation
main() {
    printf "\n"
    printf "${CYAN}┌${RESET}  Mars - Multi Agentic Repo Workspace Manager Installer\n"
    printf "${DIM}│${RESET}\n"

    # Check requirements
    info "Checking requirements..."
    check_requirements
    success "Requirements met"

    # Create directories
    info "Creating installation directory..."
    mkdir -p "$MARS_BIN_DIR"
    success "Created $MARS_BIN_DIR"

    # Download mars
    local mars_path="$MARS_BIN_DIR/mars"
    local release_url
    release_url="$(get_download_url)"

    if [[ "$MARS_VERSION" == "latest" ]]; then
        info "Downloading Mars CLI (latest release)..."
    else
        info "Downloading Mars CLI v${MARS_VERSION}..."
    fi

    if download "$release_url" "$mars_path"; then
        chmod +x "$mars_path"
        success "Downloaded mars executable"
    else
        # Fallback to raw.githubusercontent.com
        local fallback_url="https://raw.githubusercontent.com/$MARS_REPO/main/dist/mars"
        warn "Release download failed, trying fallback..."
        if download "$fallback_url" "$mars_path"; then
            chmod +x "$mars_path"
            warn "Downloaded from fallback (unversioned). Consider installing a tagged release."
        else
            error "Failed to download Mars CLI"
            error "Tried: $release_url"
            error "Fallback: $fallback_url"
            exit 1
        fi
    fi

    # Add to PATH
    info "Configuring shell..."
    local rc_file
    rc_file=$(detect_shell)

    if add_to_path "$rc_file"; then
        success "Added to PATH in $rc_file"
    else
        warn "Could not add to PATH automatically"
        warn "Add this to your shell config:"
        printf '  export PATH="$PATH:%s"\n' "$MARS_BIN_DIR"
    fi

    # Verify installation
    printf "${DIM}│${RESET}\n"
    local installed_version
    if installed_version=$("$mars_path" --version 2>/dev/null); then
        success "Installed $installed_version"
    else
        warn "Installation may have issues - please check $mars_path"
    fi

    # Done
    printf "${DIM}│${RESET}\n"
    printf "${CYAN}└${RESET}  ${GREEN}Installation complete!${RESET}\n"
    printf "\n"
    printf "  To get started:\n"
    printf "    1. Restart your shell or run: ${CYAN}source %s${RESET}\n" "$rc_file"
    printf "    2. Create a workspace: ${CYAN}mars init${RESET}\n"
    printf "\n"
    printf "  Documentation: https://github.com/%s\n" "$MARS_REPO"
    printf "\n"
}

main "$@"
