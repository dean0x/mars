# Changelog

## [0.1.2] - 2026-02-21

### Fixed
- Clone command rewritten from parallel background jobs to sequential with per-repo spinner feedback
- Exec command argument parsing no longer silently swallows extra arguments
- Table column alignment now uses explicit widths with ANSI-aware padding

### Changed
- Removed Claude config prompts from `mars init` (no longer asks about claude.md/.claude)
- Spinner and cursor cleanup only runs when connected to a terminal (safe for piped output)

### Added
- SIGPIPE trap for clean exit when output is piped (e.g., `mars status | head`)
- `ui_table_widths` function for explicit column width control

## [0.1.1] - 2026-02-19

### Changed
- Install script now downloads from GitHub Releases instead of raw.githubusercontent.com
- README overhaul with demo GIF, badges, and restructured content

### Added
- CONTRIBUTING.md with development and architecture documentation
- CHANGELOG.md
- VHS demo tape for recording demo GIFs
- Launch materials

## [0.1.0] - 2026-02-16

### Added
- Workspace initialization (`mars init`)
- Repository management (`add`, `clone`, `list`)
- Git operations (`status`, `branch`, `checkout`, `sync`)
- Cross-repo command execution (`mars exec`)
- Tag-based filtering for all operations
- Parallel cloning (4 concurrent jobs)
- Clack-style terminal UI with Unicode/ASCII fallback
- Distribution via npm, Homebrew, and curl installer
