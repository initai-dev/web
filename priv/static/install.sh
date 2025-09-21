#!/bin/bash

# initai.dev installer
# Initialize LLM frameworks quickly and consistently

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_BASE_URL="https://initai.dev"
CONFIG_FILE=".initai.json"
INITAI_DIR="initai"
INSTALLER_VERSION="1.0.0"

echo -e "${BLUE}🚀 initai.dev - LLM Framework Installer${NC}"
echo "Initializing your development environment..."

# Show version information and check for updates
show_version_info() {
    echo -e "${BLUE}🔍 initai.dev Installer Version Information${NC}"
    echo -e "Current version: ${CYAN}${INSTALLER_VERSION}${NC}"
    echo ""

    echo -e "${YELLOW}📡 Checking for updates...${NC}"

    local version_url="${BASE_URL}/api/check-updates?client_version=${INSTALLER_VERSION}"
    local version_response=$(curl -s "$version_url" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$version_response" ]; then
        # Parse JSON response using basic grep/sed (avoiding jq dependency)
        local update_available=$(echo "$version_response" | grep -o '"update_available":[^,}]*' | sed 's/"update_available"://' | tr -d ' "')
        local current_version=$(echo "$version_response" | grep -o '"current_version":"[^"]*"' | sed 's/"current_version":"//' | sed 's/"//')

        if [ "$update_available" = "true" ]; then
            echo -e "${YELLOW}📦 Update available: ${CYAN}${current_version}${NC}"
            echo -e "${BLUE}💡 To update, download the latest installer:${NC}"
            echo -e "   ${CYAN}curl -sSL ${BASE_URL}/install.sh | bash${NC}"
            echo ""
        else
            echo -e "${GREEN}✅ You have the latest version${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not check for updates (offline?)${NC}"
    fi
}

# Parse command line arguments
BASE_URL="${BASE_URL:-$DEFAULT_BASE_URL}"
FORCE_SETUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --base-url)
            BASE_URL="$2"
            shift 2
            ;;
        --force|-f)
            FORCE_SETUP=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --base-url URL    Custom base URL (default: https://initai.dev)"
            echo "  --force, -f       Force reconfiguration"
            echo "  --version, -v     Show version and check for updates"
            echo "  --help, -h        Show this help"
            echo ""
            echo "Configuration file: $CONFIG_FILE"
            exit 0
            ;;
        --version|-v)
            show_version_info
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if we have required tools
check_dependencies() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}❌ curl is required but not installed${NC}"
        exit 1
    fi

    if ! command -v unzip >/dev/null 2>&1; then
        echo -e "${RED}❌ unzip is required but not installed${NC}"
        exit 1
    fi
}

# Load or create configuration
load_config() {
    if [ -f "$CONFIG_FILE" ] && [ "$FORCE_SETUP" = false ]; then
        echo -e "${GREEN}✅ Found existing configuration${NC}"
        return 0
    else
        echo -e "${YELLOW}📋 Setting up new configuration...${NC}"
        return 1
    fi
}

# Interactive framework selection
select_framework() {
    echo -e "\n${BLUE}📦 Available frameworks:${NC}" >&2

    # For now, we only have blissframework
    echo -e "  ${CYAN}1)${NC} Bliss Framework - Developer happiness and rapid iteration" >&2

    echo -n -e "\n${YELLOW}Select framework (1-1): ${NC}" >&2
    read selection

    case $selection in
        1)
            echo "blissframework"
            ;;
        *)
            echo -e "${RED}❌ Invalid selection${NC}" >&2
            exit 1
            ;;
    esac
}

# Interactive LLM selection (optional)
select_llm() {
    echo -e "\n${BLUE}🤖 LLM optimization (optional):${NC}" >&2

    echo -e "  ${CYAN}1)${NC} Universal (works with all LLMs)" >&2
    echo -e "  ${CYAN}2)${NC} Claude-optimized" >&2
    echo -e "  ${CYAN}3)${NC} Gemini-optimized" >&2

    echo -n -e "\n${YELLOW}Select LLM optimization (1-3) [1]: ${NC}" >&2
    read selection

    case $selection in
        2)
            echo "claude"
            ;;
        3)
            echo "gemini"
            ;;
        1|"")
            echo "universal"
            ;;
        *)
            echo -e "${RED}❌ Invalid selection${NC}" >&2
            exit 1
            ;;
    esac
}

# Download and extract framework package
download_framework_package() {
    local framework=$1
    local llm=$2
    local target_dir="${INITAI_DIR}/${framework}"

    echo -e "\n${YELLOW}📦 Downloading ${framework} framework package (${llm} optimization)...${NC}"

    mkdir -p "$target_dir"

    # Determine download URL based on LLM
    local download_url
    if [ "$llm" = "universal" ]; then
        download_url="${BASE_URL}/init/shared/${framework}"
    else
        download_url="${BASE_URL}/init/shared/${framework}/${llm}"
    fi

    local zip_file="${target_dir}/package.zip"

    echo -e "  ${CYAN}↓${NC} Downloading from ${download_url}..."
    if curl -sL "$download_url" -o "$zip_file"; then
        echo -e "    ${GREEN}✅${NC} Package downloaded"

        echo -e "  ${CYAN}📂${NC} Extracting package..."
        if unzip -q "$zip_file" -d "$target_dir"; then
            rm "$zip_file"
            echo -e "    ${GREEN}✅${NC} Package extracted"

            # Check if manifest exists and show info
            if [ -f "${target_dir}/manifest.json" ]; then
                echo -e "  ${CYAN}📄${NC} Package manifest found"
            fi
        else
            echo -e "    ${RED}❌${NC} Failed to extract package"
            rm -f "$zip_file"
            exit 1
        fi
    else
        echo -e "    ${RED}❌${NC} Failed to download package from ${download_url}"
        exit 1
    fi
}

# Save configuration
save_config() {
    local framework=$1
    local llm=$2

    cat > "$CONFIG_FILE" << EOF
{
  "base_url": "$BASE_URL",
  "framework": "$framework",
  "llm": "$llm",
  "version": "1.0.0",
  "last_updated": "$(date -Iseconds)"
}
EOF

    echo -e "${GREEN}✅ Configuration saved to $CONFIG_FILE${NC}"
}

# Check for updates automatically (silent)
check_updates_silent() {
    local version_url="${BASE_URL}/api/check-updates?client_version=${INSTALLER_VERSION}"
    local version_response=$(curl -s "$version_url" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$version_response" ]; then
        local update_available=$(echo "$version_response" | grep -o '"update_available":[^,}]*' | sed 's/"update_available"://' | tr -d ' "')
        local current_version=$(echo "$version_response" | grep -o '"current_version":"[^"]*"' | sed 's/"current_version":"//' | sed 's/"//')

        if [ "$update_available" = "true" ]; then
            echo -e "${YELLOW}💡 Installer update available: ${current_version} (run with --version for details)${NC}"
        fi
    fi
}

# Main installation logic
main() {
    # Check dependencies
    check_dependencies

    # Check if configuration exists
    if ! load_config; then
        # Interactive setup
        local framework=$(select_framework)
        local llm=$(select_llm)

        echo -e "\n${BLUE}🎯 Selected: ${framework} framework with ${llm} optimization${NC}"

        # Download and extract package
        download_framework_package "$framework" "$llm"

        # Save configuration
        save_config "$framework" "$llm"

        echo -e "\n${GREEN}✅ Setup complete!${NC}"
        echo -e "${YELLOW}📖 Framework files: ./${INITAI_DIR}/${framework}/${NC}"
        echo -e "${BLUE}💡 Tell your LLM: 'Load initialization files from ./${INITAI_DIR}/${framework}/'${NC}"
    else
        # Load existing config
        if [ -f "$CONFIG_FILE" ]; then
            echo -e "${CYAN}Use --force to reconfigure${NC}"
        fi
    fi

    echo -e "\n${GREEN}🎉 Ready to code with initai.dev!${NC}"
}

main "$@"