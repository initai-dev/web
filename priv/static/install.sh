#!/bin/bash
# initai.dev Shell installer
# Downloads and installs initai.sh to user's local bin

set -e

# Configuration
BASE_URL="${1:-https://initai.dev}"
LOCAL_BIN="$HOME/.local/bin"
INITAI_SCRIPT_PATH="$LOCAL_BIN/initai.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

write_header() {
    echo -e "${BLUE}initai.dev - Installer${NC}"
    echo "Installing initai.sh to local bin..."
}

initialize_local_bin() {
    if [ ! -d "$LOCAL_BIN" ]; then
        mkdir -p "$LOCAL_BIN"
        echo -e "${GREEN}Created directory: $LOCAL_BIN${NC}"
    fi
}

download_initai_script() {
    write_header
    initialize_local_bin

    local download_url="$BASE_URL/initai.sh"

    echo -e "${YELLOW}Downloading from $download_url...${NC}"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$download_url" -o "$INITAI_SCRIPT_PATH"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$download_url" -O "$INITAI_SCRIPT_PATH"
    else
        echo -e "${RED}ERROR: Neither curl nor wget found. Please install one of them.${NC}"
        exit 1
    fi

    chmod +x "$INITAI_SCRIPT_PATH"

    echo -e "${GREEN}Installed initai.sh successfully!${NC}"
    echo ""
    echo -e "${BLUE}=== Installation Complete ===${NC}"
    echo -e "${CYAN}Script location: $INITAI_SCRIPT_PATH${NC}"
    echo ""
    echo -e "${YELLOW}To run from anywhere, add this path to your PATH environment variable:${NC}"
    echo -e "${CYAN}$LOCAL_BIN${NC}"
    echo ""
    echo -e "${YELLOW}Add to your ~/.bashrc or ~/.zshrc:${NC}"
    echo -e "${CYAN}export PATH=\"\$PATH:$LOCAL_BIN\"${NC}"
    echo ""
    echo -e "${BLUE}Usage:${NC}"
    echo "  Run directly: $INITAI_SCRIPT_PATH"
    echo "  Or after adding to PATH: initai.sh"
    echo ""

    return 0
}

# Main execution
download_initai_script