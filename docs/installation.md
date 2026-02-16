# Installation Guide

Complete installation guide for Joplin Dev Workflow across different platforms.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Install](#quick-install)
- [Platform-Specific Installation](#platform-specific-installation)
  - [macOS](#macos)
  - [Linux](#linux)
  - [Windows (WSL)](#windows-wsl)
- [Manual Installation](#manual-installation)
- [Post-Installation Setup](#post-installation-setup)
- [Verification](#verification)
- [Uninstallation](#uninstallation)

---

## Prerequisites

### Required

| Dependency | Version | Purpose |
|------------|---------|---------|
| **Joplin CLI** | Latest | Core note management |
| **jq** | 1.6+ | JSON processing |
| **Bash** | 4.0+ | Script execution |

### Optional

| Tool | Purpose |
|------|---------|
| **Joplin Desktop** | Visual note management, sync configuration |
| **VS Code** | Edit notes in editor (with Joplin extension) |
| **Git** | Version control (for development) |

---

## Quick Install

For most users, the automated installer is recommended:

```bash
# Clone repository
git clone https://github.com/gcake119/joplin-dev-workflow.git
cd joplin-dev-workflow

# Run installer
./install.sh

# Reload shell configuration
source ~/.zshrc  # or ~/.bashrc
```

The installer will:
- ✅ Check dependencies
- ✅ Create necessary directories
- ✅ Install scripts via symlinks
- ✅ Set up configuration file
- ✅ Configure clipboard support (Linux)

---

## Platform-Specific Installation

### macOS

**Tested on**: macOS 26.2 (Tahoe)

#### Step 1: Install Homebrew (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Step 2: Install Dependencies

```bash
# Install Node.js (for npm)
brew install node

# Install Joplin CLI
npm install -g joplin

# Install jq
brew install jq
```

#### Step 3: Verify Installation

```bash
joplin version
jq --version
```

#### Step 4: Install Joplin Dev Workflow

```bash
git clone https://github.com/gcake119/joplin-dev-workflow.git
cd joplin-dev-workflow
./install.sh
```

#### Step 5: Reload Shell

```bash
# For zsh (default on macOS)
source ~/.zshrc

# For bash
source ~/.bashrc
```

#### macOS-Specific Notes

- ✅ `pbcopy` and `pbpaste` are built-in (no additional setup needed)
- ✅ Works with both zsh (default) and bash
- 💡 If using iTerm2, clipboard integration works seamlessly

---

### Linux

**Distributions**: Ubuntu, Debian, Fedora, Arch Linux

#### Ubuntu/Debian

##### Step 1: Install Dependencies

```bash
# Update package list
sudo apt update

# Install Node.js and npm
sudo apt install -y nodejs npm

# Install Joplin CLI
sudo npm install -g joplin

# Install jq
sudo apt install -y jq

# Install clipboard tool
sudo apt install -y xclip
```

##### Step 2: Install Joplin Dev Workflow

```bash
git clone https://github.com/gcake119/joplin-dev-workflow.git
cd joplin-dev-workflow
./install.sh
```

The installer will automatically configure `pbpaste`/`pbcopy` aliases for xclip.

##### Step 3: Reload Shell

```bash
source ~/.bashrc  # or ~/.zshrc if using zsh
```

#### Fedora/RHEL/CentOS

```bash
# Install Node.js
sudo dnf install -y nodejs npm

# Install Joplin CLI
sudo npm install -g joplin

# Install jq
sudo dnf install -y jq

# Install clipboard tool
sudo dnf install -y xclip

# Continue with standard installation
git clone https://github.com/gcake119/joplin-dev-workflow.git
cd joplin-dev-workflow
./install.sh
source ~/.bashrc
```

#### Arch Linux

```bash
# Install dependencies
sudo pacman -S nodejs npm jq xclip

# Install Joplin CLI
sudo npm install -g joplin

# Continue with standard installation
git clone https://github.com/gcake119/joplin-dev-workflow.git
cd joplin-dev-workflow
./install.sh
source ~/.bashrc
```

#### Linux-Specific Notes

- 🐧 Clipboard tool required: `xclip`, `xsel`, or `wl-clipboard` (Wayland)
- 🔧 The installer will configure aliases automatically
- ⚠️ **Untested**: Community testing needed! Please report results.

---

### Windows (WSL)

**Recommended**: Windows Subsystem for Linux 2 (WSL2)

#### Step 1: Enable WSL2

```powershell
# In PowerShell (as Administrator)
wsl --install
```

#### Step 2: Install Ubuntu in WSL

```bash
# Install Ubuntu from Microsoft Store
# Or via command line:
wsl --install -d Ubuntu
```

#### Step 3: Inside WSL, Follow Linux Instructions

```bash
# Update package manager
sudo apt update

# Install dependencies
sudo apt install -y nodejs npm jq xclip

# Install Joplin CLI
sudo npm install -g joplin

# Clone and install
git clone https://github.com/gcake119/joplin-dev-workflow.git
cd joplin-dev-workflow
./install.sh
```

#### Step 4: Configure Clipboard (WSL-specific)

WSL2 clipboard integration with Windows:

```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'alias pbpaste="powershell.exe Get-Clipboard"' >> ~/.bashrc
echo 'alias pbcopy="clip.exe"' >> ~/.bashrc
source ~/.bashrc
```

#### Windows-Specific Notes

- 🪟 **Experimental**: Not fully tested, feedback welcome
- 💡 WSL2 provides better Linux compatibility than WSL1
- 🔄 Clipboard shares with Windows host
- ⚠️ Native PowerShell version not yet available

---

## Manual Installation

If the automated installer doesn't work, install manually:

### Step 1: Create Directories

```bash
mkdir -p ~/.local/bin
mkdir -p ~/.config/joplin-workflow
```

### Step 2: Clone Repository

```bash
git clone https://github.com/gcake119/joplin-dev-workflow.git
cd joplin-dev-workflow
```

### Step 3: Create Symlinks

```bash
ln -s "$(pwd)/bin/learn" ~/.local/bin/learn
ln -s "$(pwd)/bin/til" ~/.local/bin/til
ln -s "$(pwd)/bin/weekly" ~/.local/bin/weekly
chmod +x ~/.local/bin/{learn,til,weekly}
```

### Step 4: Copy Configuration

```bash
cp config/joplin-workflow.conf.example ~/.config/joplin-workflow/config
```

### Step 5: Add to PATH

Add to `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload:

```bash
source ~/.zshrc  # or ~/.bashrc
```

### Step 6: Configure Clipboard (Linux only)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias pbpaste='xclip -selection clipboard -o'
alias pbcopy='xclip -selection clipboard'
```

---

## Post-Installation Setup

### 1. Configure Joplin CLI

First-time Joplin CLI setup:

```bash
# Start Joplin CLI
joplin

# The CLI will guide you through initial setup
```

### 2. Create Required Notebooks

```bash
# Create the three default notebooks
joplin mkbook "Daily Notes"
joplin mkbook "Blog Posts"
joplin mkbook "Weekly Reviews"

# Verify
joplin ls /
```

### 3. (Optional) Configure Joplin Sync

Set up Joplin Cloud or other sync services:

```bash
# Example: Joplin Cloud
joplin config sync.target 10
joplin config sync.10.username "your-email@example.com"
joplin config sync.10.password "your-password"

# Run sync
joplin sync
```

See [Joplin sync documentation](https://joplinapp.org/help/apps/sync/) for other sync options (Dropbox, OneDrive, etc.).

### 4. Customize Configuration

Edit `~/.config/joplin-workflow/config`:

```bash
# Use your preferred editor
nano ~/.config/joplin-workflow/config
# or
code ~/.config/joplin-workflow/config
```

See [Customization Guide](customization.md) for details.

---

## Verification

Test that everything works:

### 1. Check Commands Exist

```bash
which learn til weekly
# Should output: /Users/you/.local/bin/learn (etc.)
```

### 2. Check Dependencies

```bash
joplin version
jq --version
pbpaste --help  # Should work on macOS, or show xclip help on Linux
```

### 3. Run Test

```bash
# Copy test content
echo "Test note content" | pbcopy

# Create test note
learn "Test Installation"

# Check in Joplin
joplin use "Blog Posts"
joplin ls
```

If you see "Test Installation" in the list, installation is successful! ✅

---

## Uninstallation

To remove Joplin Dev Workflow:

### 1. Remove Symlinks

```bash
rm ~/.local/bin/learn
rm ~/.local/bin/til
rm ~/.local/bin/weekly
```

### 2. Remove Configuration

```bash
rm -rf ~/.config/joplin-workflow
```

### 3. Remove Repository

```bash
rm -rf ~/path/to/joplin-dev-workflow
```

### 4. (Optional) Remove Shell Config

Edit `~/.zshrc` or `~/.bashrc` and remove:
- PATH addition
- Clipboard aliases (Linux)

### 5. Reload Shell

```bash
source ~/.zshrc  # or ~/.bashrc
```

---

## Troubleshooting

If you encounter issues during installation, see the [Troubleshooting Guide](troubleshooting.md).

Common issues:
- [Command not found](troubleshooting.md#command-not-found)
- [Joplin CLI not working](troubleshooting.md#joplin-cli-issues)
- [Clipboard not working](troubleshooting.md#clipboard-issues)
- [Permission denied](troubleshooting.md#permission-issues)

---

## Next Steps

- 📖 Read the [Usage Guide](usage.md)
- ⚙️ Customize your [configuration](customization.md)
- 🔄 Learn recommended [workflows](workflows.md)

---

## Getting Help

- 📫 [GitHub Issues](https://github.com/gcake119/joplin-dev-workflow/issues)
- 💬 [GitHub Discussions](https://github.com/gcake119/joplin-dev-workflow/discussions)
- 📚 [Joplin Forum](https://discourse.joplinapp.org/)
