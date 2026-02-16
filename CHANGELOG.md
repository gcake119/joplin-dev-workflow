# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Auto-scan git commits to generate technical notes
- Parse existing notes to create structured documentation
- Template-based content generation
- Learning analytics dashboard
- VS Code deep integration
- Windows native support (PowerShell version)
- Automated test suite
- Package manager distribution (Homebrew, apt)

---

## [0.1.0] - 2026-02-16

### 🎉 Initial Release

First public release of Joplin Dev Workflow - automated CLI tools for developers to capture learning notes.

### Added

#### Core Commands
- **`learn`** - Create technical article drafts in "Blog Posts" notebook
- **`til`** - Append Today I Learned entries to daily notes in "Daily Notes" notebook
- **`weekly`** - Generate weekly review templates in "Weekly Reviews" notebook

#### Features
- ✅ Clipboard-first workflow (saves AI API quota)
- ✅ Auto-append TIL entries to same-day notes
- ✅ Pre-configured note templates with metadata
- ✅ Automatic Joplin sync after note creation
- ✅ Configurable notebook mappings
- ✅ Customizable tags and date formats
- ✅ Pure CLI workflow (no Desktop required during note-taking)

#### Configuration
- Configuration file support at `~/.config/joplin-workflow/config`
- Example configuration with detailed comments
- Support for custom notebook names
- Customizable template tags
- Configurable date/time formats

#### Installation
- Automated installation script (`install.sh`)
- Dependency checking (Joplin CLI, jq)
- Cross-platform clipboard detection
- Automatic PATH configuration
- Shell config integration (bash/zsh)

#### Documentation
- Comprehensive README with usage examples
- Installation guide with platform-specific instructions
- Configuration examples
- FAQ section
- Contribution guidelines

#### Platform Support
- ✅ **macOS 26.2** - Fully tested and working
- 🧪 **Linux** - Should work with xclip (untested, feedback welcome)
- 🧪 **Windows WSL** - Experimental support

### Technical Details

#### Dependencies
- Joplin CLI (npm package)
- jq (JSON processor)
- pbpaste/pbcopy (macOS) or xclip (Linux)

#### Architecture
- Pure Bash shell scripts
- Joplin CLI integration
- No external API dependencies
- Minimal system requirements

### Known Limitations

- Desktop app recommended (but not required) for:
  - Visual note management
  - Joplin Cloud sync setup
  - VS Code extension integration
  
- Platform testing:
  - Only tested on macOS 26.2
  - Linux and Windows need community testing
  
- Clipboard tools vary by platform:
  - Linux users need xclip or xsel
  - Windows WSL users may need additional setup

### Breaking Changes
- N/A (initial release)

### Migration Guide
- N/A (initial release)

---

## Version Numbering

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backwards compatible manner
- **PATCH** version for backwards compatible bug fixes

---

## Release Process

1. Update version number in scripts (if applicable)
2. Update CHANGELOG.md with release date
3. Create git tag: `git tag -a v0.1.0 -m "Release v0.1.0"`
4. Push tag: `git push origin v0.1.0`
5. Create GitHub Release with changelog
6. Update README badges if needed

---

## Links

- [GitHub Repository](https://github.com/gcake119/joplin-dev-workflow)
- [Issue Tracker](https://github.com/gcake119/joplin-dev-workflow/issues)
- [Releases](https://github.com/gcake119/joplin-dev-workflow/releases)

---

## Legend

- `Added` - New features
- `Changed` - Changes in existing functionality
- `Deprecated` - Soon-to-be removed features
- `Removed` - Removed features
- `Fixed` - Bug fixes
- `Security` - Security vulnerability fixes
