#!/bin/bash
# ============================================
# Joplin Dev Workflow - Installation Script
# ============================================
# 
# This script installs joplin-dev-workflow CLI tools.
# 
# Usage:
#   ./install.sh
#
# What it does:
#   1. Checks for required dependencies
#   2. Creates necessary directories
#   3. Creates symlinks for commands
#   4. Sets up configuration file
#   5. Configures clipboard support (Linux)
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/joplin-workflow"

# --------------------------------------------
# Helper Functions
# --------------------------------------------

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Joplin Dev Workflow - Installer${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

# --------------------------------------------
# Main Installation
# --------------------------------------------

print_header

echo "📦 Checking system requirements..."
echo ""

# Check OS
OS_TYPE="$(uname -s)"
case "$OS_TYPE" in
    Darwin*)
        OS_NAME="macOS"
        CLIPBOARD_PASTE="pbpaste"
        CLIPBOARD_COPY="pbcopy"
        ;;
    Linux*)
        OS_NAME="Linux"
        CLIPBOARD_PASTE="xclip -selection clipboard -o"
        CLIPBOARD_COPY="xclip -selection clipboard"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        OS_NAME="Windows"
        print_warning "Windows support is experimental. WSL2 recommended."
        CLIPBOARD_PASTE="powershell.exe Get-Clipboard"
        CLIPBOARD_COPY="clip.exe"
        ;;
    *)
        OS_NAME="Unknown"
        print_error "Unsupported operating system: $OS_TYPE"
        exit 1
        ;;
esac

print_info "Detected OS: $OS_NAME ($OS_TYPE)"
echo ""

# Check dependencies
echo "🔍 Checking dependencies..."
echo ""

DEPENDENCIES_OK=true

# Check Joplin CLI
if check_command joplin; then
    JOPLIN_VERSION=$(joplin version 2>/dev/null || echo "unknown")
    print_info "Joplin CLI version: $JOPLIN_VERSION"
else
    print_error "Joplin CLI is required but not installed"
    echo "  Install with: npm install -g joplin"
    echo "  See: https://joplinapp.org/terminal/"
    DEPENDENCIES_OK=false
fi

echo ""

# Check jq
if check_command jq; then
    JQ_VERSION=$(jq --version 2>/dev/null || echo "unknown")
    print_info "jq version: $JQ_VERSION"
else
    print_error "jq is required but not installed"
    if [[ "$OS_NAME" == "macOS" ]]; then
        echo "  Install with: brew install jq"
    elif [[ "$OS_NAME" == "Linux" ]]; then
        echo "  Install with: sudo apt install jq  (Debian/Ubuntu)"
        echo "            or: sudo yum install jq  (RHEL/CentOS)"
    fi
    DEPENDENCIES_OK=false
fi

echo ""

# Check clipboard tool (Linux only)
if [[ "$OS_NAME" == "Linux" ]]; then
    if ! command -v xclip >/dev/null 2>&1 && ! command -v xsel >/dev/null 2>&1; then
        print_warning "No clipboard tool detected"
        echo "  Installing xclip is recommended"
        echo "  Install with: sudo apt install xclip"
        echo ""
        read -p "  Install xclip now? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get install -y xclip
                print_success "xclip installed"
            else
                print_error "Could not install xclip automatically"
                echo "  Please install manually: sudo apt install xclip"
            fi
        fi
    else
        print_success "Clipboard tool found (xclip or xsel)"
    fi
    echo ""
fi

# Stop if dependencies missing
if [ "$DEPENDENCIES_OK" = false ]; then
    echo ""
    print_error "Missing required dependencies. Please install them first."
    exit 1
fi

# --------------------------------------------
# Create directories
# --------------------------------------------

echo "📁 Creating directories..."
echo ""

mkdir -p "$INSTALL_DIR"
print_success "Created $INSTALL_DIR"

mkdir -p "$CONFIG_DIR"
print_success "Created $CONFIG_DIR"

echo ""

# --------------------------------------------
# Check PATH
# --------------------------------------------

echo "🔍 Checking PATH configuration..."
echo ""

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    print_warning "$INSTALL_DIR is not in your PATH"
    echo ""
    echo "  Add this to your shell config (~/.zshrc or ~/.bashrc):"
    echo "  ${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo ""
    
    SHELL_CONFIG=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_CONFIG="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        read -p "  Add to $SHELL_CONFIG automatically? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "" >> "$SHELL_CONFIG"
            echo "# Added by joplin-dev-workflow installer" >> "$SHELL_CONFIG"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_CONFIG"
            print_success "Added to $SHELL_CONFIG"
            echo "  ${YELLOW}Please run: source $SHELL_CONFIG${NC}"
        fi
    fi
    echo ""
else
    print_success "$INSTALL_DIR is in your PATH"
    echo ""
fi

# --------------------------------------------
# Install scripts
# --------------------------------------------

echo "🔗 Installing scripts..."
echo ""

# Check if bin directory exists
if [ ! -d "$SCRIPT_DIR/bin" ]; then
    print_error "bin/ directory not found in $SCRIPT_DIR"
    echo "  Please make sure you're running install.sh from the project root"
    exit 1
fi

# Create symlinks
for script in learn til weekly; do
    SOURCE_FILE="$SCRIPT_DIR/bin/$script"
    TARGET_FILE="$INSTALL_DIR/$script"
    
    if [ ! -f "$SOURCE_FILE" ]; then
        print_error "Script not found: $SOURCE_FILE"
        continue
    fi
    
    # Remove existing symlink or file
    if [ -L "$TARGET_FILE" ] || [ -f "$TARGET_FILE" ]; then
        rm "$TARGET_FILE"
    fi
    
    # Create symlink
    ln -s "$SOURCE_FILE" "$TARGET_FILE"
    chmod +x "$SOURCE_FILE"
    
    print_success "Installed $script → $TARGET_FILE"
done

echo ""

# --------------------------------------------
# Setup configuration
# --------------------------------------------

echo "⚙️  Setting up configuration..."
echo ""

CONFIG_FILE="$CONFIG_DIR/config"

if [ -f "$CONFIG_FILE" ]; then
    print_warning "Configuration file already exists: $CONFIG_FILE"
    echo "  Skipping to preserve your settings"
else
    if [ -f "$SCRIPT_DIR/config/joplin-workflow.conf.example" ]; then
        cp "$SCRIPT_DIR/config/joplin-workflow.conf.example" "$CONFIG_FILE"
        print_success "Created configuration: $CONFIG_FILE"
    else
        print_warning "Config example not found, creating default config"
        cat > "$CONFIG_FILE" << 'EOF'
# Joplin Dev Workflow Configuration
NOTEBOOK_DAILY="Daily Notes"
NOTEBOOK_POST="Blog Posts"
NOTEBOOK_WEEKLY="Weekly Reviews"
TEMPLATE_TAGS_TIL="#til #daily"
TEMPLATE_TAGS_LEARN="#article #draft"
TEMPLATE_TAGS_WEEKLY="#weekly #review"
DATE_FORMAT="%Y-%m-%d"
TIME_FORMAT="%H:%M"
AUTO_SYNC="true"
EOF
        print_success "Created default configuration: $CONFIG_FILE"
    fi
fi

echo ""

# --------------------------------------------
# Setup clipboard aliases (Linux)
# --------------------------------------------

if [[ "$OS_NAME" == "Linux" ]]; then
    echo "📋 Setting up clipboard aliases..."
    echo ""
    
    SHELL_CONFIG=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_CONFIG="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        # Check if aliases already exist
        if grep -q "alias pbpaste=" "$SHELL_CONFIG" 2>/dev/null; then
            print_info "Clipboard aliases already configured"
        else
            echo "" >> "$SHELL_CONFIG"
            echo "# Added by joplin-dev-workflow installer" >> "$SHELL_CONFIG"
            echo "alias pbpaste='xclip -selection clipboard -o'" >> "$SHELL_CONFIG"
            echo "alias pbcopy='xclip -selection clipboard'" >> "$SHELL_CONFIG"
            print_success "Added clipboard aliases to $SHELL_CONFIG"
            echo "  ${YELLOW}Please run: source $SHELL_CONFIG${NC}"
        fi
    fi
    echo ""
fi

# --------------------------------------------
# Create Joplin notebooks
# --------------------------------------------

echo "📓 Checking Joplin notebooks..."
echo ""

# Check if Joplin is configured
if joplin status >/dev/null 2>&1; then
    print_info "Joplin is configured and running"
    echo ""
    echo "  The following notebooks should exist:"
    echo "    • Daily Notes"
    echo "    • Blog Posts"
    echo "    • Weekly Reviews"
    echo ""
    echo "  Create them using Joplin CLI or Desktop if they don't exist:"
    echo "    ${BLUE}joplin mkbook \"Daily Notes\"${NC}"
    echo "    ${BLUE}joplin mkbook \"Blog Posts\"${NC}"
    echo "    ${BLUE}joplin mkbook \"Weekly Reviews\"${NC}"
else
    print_warning "Joplin CLI is not configured yet"
    echo ""
    echo "  Please run ${BLUE}joplin${NC} to set up Joplin CLI first"
    echo "  Then create the required notebooks"
fi

echo ""

# --------------------------------------------
# Installation complete
# --------------------------------------------

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Installation Complete! 🎉${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

echo "📝 Quick Start:"
echo ""
echo "  1. Create Joplin notebooks (if not exists):"
echo "     ${BLUE}joplin mkbook \"Daily Notes\"${NC}"
echo "     ${BLUE}joplin mkbook \"Blog Posts\"${NC}"
echo "     ${BLUE}joplin mkbook \"Weekly Reviews\"${NC}"
echo ""
echo "  2. Copy content to clipboard:"
echo "     ${BLUE}echo \"Your learning notes\" | pbcopy${NC}"
echo ""
echo "  3. Run a command:"
echo "     ${BLUE}learn \"Understanding React Hooks\"${NC}"
echo "     ${BLUE}til \"JavaScript Closures\"${NC}"
echo "     ${BLUE}weekly \"W07 Learning Summary\"${NC}"
echo ""
echo "📚 Documentation:"
echo "  • Configuration: ${CONFIG_FILE}"
echo "  • Usage Guide: ${SCRIPT_DIR}/docs/usage.md"
echo "  • README: ${SCRIPT_DIR}/README.md"
echo ""
echo "🐛 Issues? Report at:"
echo "  https://github.com/gcake119/joplin-dev-workflow/issues"
echo ""

# Check if need to reload shell
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]] || [[ "$OS_NAME" == "Linux" ]]; then
    echo -e "${YELLOW}⚠  Important: Reload your shell configuration${NC}"
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "  ${BLUE}source ~/.zshrc${NC}"
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo "  ${BLUE}source ~/.bashrc${NC}"
    else
        echo "  Or restart your terminal"
    fi
    echo ""
fi

exit 0
