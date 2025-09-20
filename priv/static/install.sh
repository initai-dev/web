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

echo -e "${BLUE}🚀 initai.dev - LLM Framework Installer${NC}"
echo "Initializing your development environment..."

# Parse command line arguments
BASE_URL="$DEFAULT_BASE_URL"
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
            echo "  --help, -h        Show this help"
            echo ""
            echo "Configuration file: $CONFIG_FILE"
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

    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${RED}❌ python3 is required but not installed${NC}"
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

# Download manifest from server
download_manifest() {
    local manifest_url="${BASE_URL}/manifest.json"
    echo -e "${CYAN}📡 Downloading manifest from ${manifest_url}...${NC}"

    if ! curl -sL "$manifest_url" -o ".manifest.json"; then
        echo -e "${RED}❌ Failed to download manifest from ${manifest_url}${NC}"
        exit 1
    fi

    # Verify manifest is valid JSON
    if ! python3 -m json.tool ".manifest.json" > /dev/null 2>&1; then
        echo -e "${RED}❌ Invalid manifest format${NC}"
        rm -f ".manifest.json"
        exit 1
    fi

    echo -e "${GREEN}✅ Manifest downloaded successfully${NC}"
}

# Interactive LLM selection
select_llm() {
    echo -e "\n${BLUE}🤖 Available LLMs:${NC}"

    # Parse LLMs from manifest
    local llms=($(python3 -c "
import json
with open('.manifest.json') as f:
    data = json.load(f)
    for llm in data['llms']:
        print(llm)
"))

    local i=1
    for llm in "${llms[@]}"; do
        local name=$(python3 -c "
import json
with open('.manifest.json') as f:
    data = json.load(f)
    print(data['llms']['$llm']['name'])
")
        local desc=$(python3 -c "
import json
with open('.manifest.json') as f:
    data = json.load(f)
    print(data['llms']['$llm']['description'])
")
        echo -e "  ${CYAN}$i)${NC} $name - $desc"
        ((i++))
    done

    echo -n -e "\n${YELLOW}Select LLM (1-${#llms[@]}): ${NC}"
    read selection

    if [[ $selection -ge 1 && $selection -le ${#llms[@]} ]]; then
        echo "${llms[$((selection-1))]}"
    else
        echo -e "${RED}❌ Invalid selection${NC}"
        exit 1
    fi
}

# Interactive framework selection
select_framework() {
    local llm=$1
    echo -e "\n${BLUE}⚡ Available frameworks for $llm:${NC}"

    # Parse frameworks from manifest
    local frameworks=($(python3 -c "
import json
with open('.manifest.json') as f:
    data = json.load(f)
    for fw in data['llms']['$llm']['frameworks']:
        print(fw)
"))

    local i=1
    for fw in "${frameworks[@]}"; do
        local name=$(python3 -c "
import json
with open('.manifest.json') as f:
    data = json.load(f)
    print(data['llms']['$llm']['frameworks']['$fw']['name'])
")
        local desc=$(python3 -c "
import json
with open('.manifest.json') as f:
    data = json.load(f)
    print(data['llms']['$llm']['frameworks']['$fw']['description'])
")
        echo -e "  ${CYAN}$i)${NC} $name - $desc"
        ((i++))
    done

    echo -n -e "\n${YELLOW}Select framework (1-${#frameworks[@]}): ${NC}"
    read selection

    if [[ $selection -ge 1 && $selection -le ${#frameworks[@]} ]]; then
        echo "${frameworks[$((selection-1))]}"
    else
        echo -e "${RED}❌ Invalid selection${NC}"
        exit 1
    fi
}

# Download framework files
download_framework_files() {
    local llm=$1
    local framework=$2
    local target_dir="${INITAI_DIR}/${llm}/${framework}"

    echo -e "\n${YELLOW}📦 Downloading ${llm} ${framework} framework files...${NC}"

    mkdir -p "$target_dir"

    # Get file list from manifest
    local files=($(python3 -c "
import json
with open('.manifest.json') as f:
    data = json.load(f)
    for file in data['llms']['$llm']['frameworks']['$framework']['files']:
        print(file)
"))

    # Download each file
    for file in "${files[@]}"; do
        local file_url="${BASE_URL}/${llm}/${framework}/${file}"
        local target_file="${target_dir}/${file}"

        echo -e "  ${CYAN}↓${NC} Downloading $file..."
        if curl -sL "$file_url" -o "$target_file"; then
            echo -e "    ${GREEN}✅${NC} $file"
        else
            echo -e "    ${RED}❌${NC} Failed to download $file"
        fi
    done
}

# Save configuration
save_config() {
    local llm=$1
    local framework=$2
    local version=$(python3 -c "
import json
with open('.manifest.json') as f:
    data = json.load(f)
    print(data['llms']['$llm']['frameworks']['$framework']['version'])
")

    cat > "$CONFIG_FILE" << EOF
{
  "base_url": "$BASE_URL",
  "llm": "$llm",
  "framework": "$framework",
  "version": "$version",
  "last_updated": "$(date -Iseconds)"
}
EOF

    echo -e "${GREEN}✅ Configuration saved to $CONFIG_FILE${NC}"
}

# Main installation logic
main() {
    # Check dependencies
    check_dependencies

    # Check if configuration exists
    if ! load_config; then
        # Download manifest
        download_manifest

        # Interactive setup
        local llm=$(select_llm)
        local framework=$(select_framework "$llm")

        echo -e "\n${BLUE}🎯 Selected: ${llm} ${framework} framework${NC}"

        # Download files
        download_framework_files "$llm" "$framework"

        # Save configuration
        save_config "$llm" "$framework"

        # Cleanup
        rm -f ".manifest.json"

        echo -e "\n${GREEN}✅ Setup complete!${NC}"
        echo -e "${YELLOW}📖 Framework files: ./${INITAI_DIR}/${llm}/${framework}/${NC}"
        echo -e "${BLUE}💡 Tell your LLM: 'Load initialization files from ./${INITAI_DIR}/${llm}/${framework}/'${NC}"
    else
        # Load existing config
        local current_llm=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
    print(data.get('llm', 'unknown'))
")
        local current_framework=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    data = json.load(f)
    print(data.get('framework', 'unknown'))
")

        echo -e "${CYAN}Current configuration: ${current_llm} ${current_framework}${NC}"
        echo -e "${BLUE}💡 Use --force to reconfigure${NC}"
    fi

    echo -e "\n${GREEN}🎉 Ready to code with initai.dev!${NC}"
}

main "$@"