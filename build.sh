#!/usr/bin/env bash
# Mars CLI - Build Script
# Concatenates all source files into a single executable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/dist/mars"

# Create dist directory
mkdir -p "$SCRIPT_DIR/dist"

# Start with header
cat > "$OUTPUT_FILE" << 'HEADER'
#!/usr/bin/env bash
# Mars CLI - Multi-Repo Workspace Manager
# https://github.com/dean0x/mars
# This is a bundled distribution - do not edit

set -euo pipefail

MARS_VERSION="0.1.0"

HEADER

# Source files in dependency order
SOURCE_FILES=(
    "lib/ui.sh"
    "lib/yaml.sh"
    "lib/config.sh"
    "lib/git.sh"
    "lib/commands/init.sh"
    "lib/commands/clone.sh"
    "lib/commands/status.sh"
    "lib/commands/branch.sh"
    "lib/commands/checkout.sh"
    "lib/commands/sync.sh"
    "lib/commands/exec.sh"
    "lib/commands/add.sh"
    "lib/commands/list.sh"
)

# Append each source file, stripping shebang and comments at start
for src in "${SOURCE_FILES[@]}"; do
    echo "" >> "$OUTPUT_FILE"
    echo "# === $src ===" >> "$OUTPUT_FILE"

    # Skip shebang and initial comment block
    tail -n +2 "$SCRIPT_DIR/$src" | while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip lines that are just the shebang or file header comment
        if [[ "$line" =~ ^#!.*bash ]]; then
            continue
        fi
        echo "$line"
    done >> "$OUTPUT_FILE"
done

# Append main entry point (excluding the lib loading and shebang)
echo "" >> "$OUTPUT_FILE"
echo "# === Main ===" >> "$OUTPUT_FILE"

# Extract just the help and main functions from mars
awk '
    /^# --- Help ---$/,0 { print }
' "$SCRIPT_DIR/mars" >> "$OUTPUT_FILE"

# Make executable
chmod +x "$OUTPUT_FILE"

# Show result
echo "Built: $OUTPUT_FILE"
ls -la "$OUTPUT_FILE"
wc -l "$OUTPUT_FILE"
