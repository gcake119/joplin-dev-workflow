# 📝 Joplin Dev Workflow

> Automated CLI tools for developers to capture learning notes with Joplin - designed for the modern development workflow.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Joplin](https://img.shields.io/badge/Joplin-CLI-blue.svg)](https://joplinapp.org)
[![macOS](https://img.shields.io/badge/Tested-macOS_26.2-blue.svg)](https://www.apple.com/macos/)

---

## 🎯 Why This Project?

As a **frontend bootcamp student** practicing TDD and learning JavaScript, I needed a frictionless way to:
- 💬 Capture insights from **GitHub Copilot Chat** and **Perplexity** into notes
- 📚 Build a **searchable knowledge base** without leaving the terminal
- 🗓️ Maintain **daily learning logs** (TIL) and weekly reviews
- 🔄 Sync everything across devices (via Joplin Cloud, if configured)
- 💰 **Save on AI API costs** by using clipboard instead of premium AI requests

Traditional GUI note apps break the flow. **These CLI tools work entirely in the terminal** - no desktop app required during active note-taking.

### Design Philosophy: Clipboard-First Approach

> 💡 **Why clipboard?** This workflow uses your clipboard as the content bridge, which:
> - Saves premium AI API request quotas (no need to re-query AI for content)
> - Lets you review/edit AI responses before saving
> - Works with any content source (Copilot, Perplexity, browser, files)
> - Keeps the workflow simple and universal

**Future Vision**: Automatically scan git commits and existing notes to generate technical documentation using templates - all editable in VS Code. For now, clipboard provides the best balance of automation and flexibility.

---

## ✨ Features

### Three Powerful Commands

| Command | Purpose | Notebook |
|---------|---------|----------|
| `learn "Title"` | Create technical article drafts | `Blog Posts` |
| `til "Concept"` | Append to today's learning log | `Daily Notes` |
| `weekly "Title"` | Generate weekly review template | `Weekly Reviews` |

### Smart Workflows

- 🚀 **No context switching** - run from your terminal, content in clipboard
- 📎 **Auto-append TIL entries** - multiple learnings in one daily note
- 🏷️ **Pre-configured templates** - tags, metadata, and structure
- 🔄 **Auto-sync** - changes sync to Joplin Cloud immediately
- 🖥️ **Cross-platform ready** - developed on macOS, Linux/Windows compatible

---

## 📦 Installation

### Prerequisites

#### Required Dependencies

| Tool | Installation | Purpose |
|------|-------------|---------|
| **Joplin CLI** | `npm install -g joplin` | Core note management |
| **jq** | `brew install jq` (macOS)<br>`sudo apt install jq` (Linux) | JSON processing |

#### Optional (Recommended)

| Tool | Purpose | When You Need It |
|------|---------|------------------|
| **Joplin Desktop** | Visual interface, sync setup | Want GUI preview, configure Joplin Cloud |
| **VS Code Joplin Extension** | Edit notes in VS Code | Prefer VS Code over CLI/Desktop |
| **xclip** (Linux) | Clipboard support | Auto-installed by `install.sh` |

> 💡 **Quick Start**: You can start using these scripts with just Joplin CLI + jq. Add Desktop later if you want visual management.

### Quick Install

```bash
# Clone the repository
git clone https://github.com/gcake119/joplin-dev-workflow.git
cd joplin-dev-workflow

# Run installer (checks dependencies)
./install.sh

# Restart your terminal
source ~/.zshrc  # or ~/.bashrc
```

### First-Time Setup (CLI Only)

If using without Desktop:

```bash
# 1. Configure Joplin CLI
joplin config editor "nano"  # or vim, code, etc.

# 2. Create notebooks (or customize in config)
joplin mkbook "Daily Notes"
joplin mkbook "Blog Posts"
joplin mkbook "Weekly Reviews"

# 3. (Optional) Set up sync
joplin config sync.target 10  # Joplin Cloud
joplin sync
```

See [docs/installation.md](docs/installation.md) for detailed setup guides.

---

## 🚀 Quick Start

### 1. Prepare Content

Copy content from anywhere (Copilot Chat, Perplexity, browser):

```bash
# From file
cat notes.md | pbcopy

# From command output
echo "Closures are functions with lexical scope" | pbcopy

# Or just Cmd+C / Ctrl+C from your editor/browser
```

### 2. Run Command

```bash
# Create a learning article
learn "Understanding React Hooks"

# Add to today's TIL
til "Array.reduce() Advanced Usage"

# Start weekly review
weekly "W07 Frontend Learning Summary"
```

### 3. Access Your Notes

**Option 1: Joplin CLI (always available)**
```bash
# View notes in terminal
joplin use "Blog Posts"
joplin ls

# Read a note
joplin cat <note-id>
```

**Option 2: Joplin Desktop (if installed)**
- Syncs automatically via Joplin Cloud
- Visual interface for editing

**Option 3: VS Code Joplin Extension (requires Desktop running)**
- Install extension: `rxliuli.joplin-vscode-plugin`
- Refresh to see new notes

---

## 📚 Usage Examples

### Scenario 1: Capturing Copilot Insights

```bash
# In VS Code:
# 1. Ask Copilot Chat about a concept
# 2. Review the response (edit if needed)
# 3. Copy the response (Cmd+C)
# 4. In terminal:
learn "TDD Best Practices from Copilot"

# Result: New note in "Blog Posts" with full content + metadata
# Saved 1 premium AI request! ✅
```

### Scenario 2: Daily Learning Journal

```bash
# Morning learning
echo "Learned about Promise.all() vs Promise.allSettled()" | pbcopy
til "Promise Parallel Execution"

# Afternoon learning (appends to same note)
echo "Discovered useCallback() prevents re-renders" | pbcopy
til "React Performance Optimization"

# Result: Single "2026-02-16 Daily Notes" with both entries
```

### Scenario 3: Weekly Review

```bash
# Copy your weekly summary from Perplexity or anywhere
pbcopy < weekly-summary.md

weekly "W07 TypeScript Basics Complete"

# Result: Structured weekly review with templates for:
# - Learning hours
# - Completed courses
# - Projects
# - Next week goals
```

---

## ⚙️ Configuration

Edit `~/.config/joplin-workflow/config` to customize:

```bash
# Notebook mappings (use your own notebook names)
NOTEBOOK_DAILY="Daily Notes"
NOTEBOOK_POST="Blog Posts"
NOTEBOOK_WEEKLY="Weekly Reviews"

# Template tags
TEMPLATE_TAGS_TIL="#til #daily"
TEMPLATE_TAGS_LEARN="#article #draft"
TEMPLATE_TAGS_WEEKLY="#weekly #review"

# Date formats
DATE_FORMAT="%Y-%m-%d"
TIME_FORMAT="%H:%M"
```

**Default notebook structure** (customize as needed):
- `Daily Notes` - For `til` command (TIL entries)
- `Blog Posts` - For `learn` command (technical articles)
- `Weekly Reviews` - For `weekly` command (weekly summaries)

See [docs/customization.md](docs/customization.md) for template customization.

---

## 🛠️ Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS 26.2 | ✅ **Tested & Working** | Native `pbpaste` support |
| Linux | 🧪 **Should Work** | Requires `xclip` (auto-configured by installer) |
| Windows | 🧪 **Untested** | WSL2 with `clip.exe` should work |

> ⚠️ **Testing Status**: Currently tested only on **macOS 26.2**. Linux and Windows may require different clipboard tools (`xclip`, `xsel`, `clip.exe`). 
> 
> 📣 **Call for Testing**: If you test on other platforms, please [open an issue](https://github.com/gcake119/joplin-dev-workflow/issues) with your results!

### Known Clipboard Tools by Platform

- **macOS**: `pbcopy` / `pbpaste` (built-in)
- **Linux**: `xclip`, `xsel`, or `wl-clipboard` (Wayland)
- **Windows**: `clip.exe` (built-in), or WSL clipboard integration

The `install.sh` script attempts to configure these automatically.

---

## 📖 Documentation

- [Installation Guide](docs/installation.md) - Detailed setup for each platform
- [Usage Guide](docs/usage.md) - Complete usage examples
- [Customization](docs/customization.md) - Templates and configuration
- [Workflows](docs/workflows.md) - Recommended learning workflows
- [Troubleshooting](docs/troubleshooting.md) - Common issues

---

## 🚧 Roadmap

### Current (v0.1.0)
- ✅ Clipboard-based content capture
- ✅ Three core commands (learn, til, weekly)
- ✅ Auto-sync with Joplin CLI
- ✅ Configurable templates

### Future Plans

**v0.2.0 - Enhanced Automation**
- 🔄 Auto-scan git commits to generate technical notes
- 📝 Parse existing notes to create structured documentation
- 🤖 Template-based content generation
- 📊 Learning analytics dashboard

**v0.3.0 - VS Code Deep Integration**
- 🎨 Edit and manage notes directly in VS Code
- 🔍 Smart search across all learning notes
- 🏷️ Auto-tagging based on content analysis

**Community Requests Welcome!** [Suggest features →](https://github.com/gcake119/joplin-dev-workflow/issues/new?template=feature_request.md)

---

## ❓ FAQ

**Q: Do I need Joplin Desktop installed?**  
A: No, the scripts work with Joplin CLI only. Desktop is recommended for visual management and setting up sync, but not required for the automation workflow.

**Q: Can I use this without Joplin Cloud?**  
A: Yes! Scripts create notes locally. Cloud sync is optional. Run `joplin sync` manually or use any sync method (Dropbox, OneDrive, etc.) configured in Joplin.

**Q: Why use clipboard instead of direct AI integration?**  
A: Clipboard approach saves premium AI API quotas, lets you review content before saving, and works with any content source. Future versions may add optional AI integration.

**Q: Will this work with VS Code Joplin extension?**  
A: The extension requires Joplin Desktop running in the background (for Web Clipper API). But the CLI scripts work independently.

**Q: What if I don't have Joplin Desktop?**  
A: Just install Joplin CLI and you're good to go! Use `joplin` commands to view/edit notes in the terminal.

**Q: Does this work on Linux/Windows?**  
A: The scripts should work on Linux (with `xclip`) and Windows WSL. Not tested yet - please report your experience!

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ideas for Contribution

- 📝 Add new note templates
- 🧪 Test on Linux/Windows and report compatibility
- 🌍 i18n support for other languages
- 🪟 Windows native support (PowerShell version?)
- 🧪 Automated test suite
- 📦 Package manager distribution (Homebrew formula, apt package)

---

## 🎓 Backstory

This project was born from my experience in a **frontend bootcamp** where I was juggling:
- 📚 Daily JavaScript/TDD lessons
- 🤖 Learning with GitHub Copilot as my pair programmer
- 🔮 Researching concepts with Perplexity AI
- 📓 Needing to document everything for future reference
- ⚡ Wanting to stay in the terminal/VS Code flow
- 💰 Managing limited AI API request quotas

Traditional note apps felt clunky. Copying AI responses manually wasted time. Joplin's CLI + these automation scripts + clipboard workflow solved all of these perfectly.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Joplin](https://joplinapp.org) - Amazing open-source note-taking app
- Inspired by the developer community practicing **learning in public**
- Built with insights from GitHub Copilot and Perplexity AI

---

## 📬 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/gcake119/joplin-dev-workflow/issues)
- **Discussions**: [GitHub Discussions](https://github.com/gcake119/joplin-dev-workflow/discussions)
- **Author**: [@gcake119](https://github.com/gcake119)

---

⭐ If this project helps your learning workflow, consider giving it a star!

💬 Share your workflows and use cases in [Discussions](https://github.com/gcake119/joplin-dev-workflow/discussions)
