# 📝 Joplin Dev Workflow

> Automated CLI tools for developers to capture learning notes with Joplin - designed for the modern development workflow.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Joplin](https://img.shields.io/badge/Joplin-Desktop_Data_API-blue.svg)](https://joplinapp.org)
[![macOS](https://img.shields.io/badge/Tested-macOS_26.2-blue.svg)](https://www.apple.com/macos/)

---

## 🎯 Why This Project?

As a **frontend bootcamp student** practicing TDD and learning JavaScript, I needed a frictionless way to:
- 💬 Capture insights from **GitHub Copilot Chat** and **Perplexity** into notes
- 📚 Build a **searchable knowledge base** without leaving the terminal
- 🗓️ Maintain **daily learning logs** (TIL) and weekly reviews
- 🔄 Sync everything across devices (via Joplin Cloud, if configured)
- 💰 **Save on AI API costs** by using clipboard instead of premium AI requests

Traditional GUI note apps break the flow. **These CLI tools run from the terminal while writing into Joplin Desktop through the Data API**, so Joplin Desktop remains the note home and sync manager.

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
- 🔄 **Desktop-managed sync** - notes are written locally, then Joplin Desktop handles cloud sync
- 🖥️ **Cross-platform ready** - developed on macOS, Linux/Windows compatible

---

## 📦 Installation

### Prerequisites

#### Required Dependencies

| Tool | Installation | Purpose |
|------|-------------|---------|
| **Joplin Desktop** | [Download Joplin](https://joplinapp.org/download/) | Note storage, Web Clipper/Data API, sync manager |
| **curl** | Built into macOS<br>`sudo apt install curl` (Linux) | Data API requests |
| **jq** | `brew install jq` (macOS)<br>`sudo apt install jq` (Linux) | JSON processing |

#### Optional (Recommended)

| Tool | Purpose | When You Need It |
|------|---------|------------------|
| **Joplin CLI** | Legacy/fallback terminal workflows | Only if you intentionally use old CLI-only flows |
| **VS Code Joplin Extension** | Edit notes in VS Code | Prefer VS Code over CLI/Desktop |
| **xclip** (Linux) | Clipboard support | Auto-installed by `install.sh` |

> 💡 **Quick Start**: Enable Web Clipper in Joplin Desktop, copy its Data API token into `~/.config/joplin-workflow/config`, then run the commands from your terminal.

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

### First-Time Setup (Joplin Desktop Data API)

1. Open Joplin Desktop.
2. Enable **Tools > Options > Web Clipper > Enable Web Clipper Service**.
3. Copy the authorization token into `~/.config/joplin-workflow/config` as `JOPLIN_API_TOKEN`.
4. Create `Daily Notes`, `Blog Posts`, and `Weekly Reviews` in Joplin Desktop, or configure `NOTEBOOK_DAILY_ID`, `NOTEBOOK_POST_ID`, and `NOTEBOOK_WEEKLY_ID` when notebook titles are duplicated.

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
- ✅ Joplin Desktop Data API write path
- ✅ Desktop-managed sync reminder
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
A: Yes for the default workflow. The scripts write through Joplin Desktop Data API, so Joplin Desktop and Web Clipper service must be running.

**Q: Can I use this without Joplin Cloud?**  
A: Yes. Scripts create notes in local Joplin Desktop. Cloud sync is optional and follows your Joplin Desktop sync settings.

**Q: Why use clipboard instead of direct AI integration?**  
A: Clipboard approach saves premium AI API quotas, lets you review content before saving, and works with any content source. Future versions may add optional AI integration.

**Q: Will this work with VS Code Joplin extension?**  
A: Yes, both use Joplin Desktop as the local note environment. These scripts write through the same Data API family and leave editing to Joplin Desktop or your editor workflow.

**Q: What if I don't have Joplin Desktop?**  
A: Install Joplin Desktop first. Joplin CLI is now legacy/fallback only and is not the default write path.

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
