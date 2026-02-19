# Changelog

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
