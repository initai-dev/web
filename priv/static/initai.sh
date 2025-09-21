#!/bin/bash
# initai.dev Shell Framework Manager
# Initialize LLM frameworks quickly and consistently

set -e

# Configuration
BASE_URL="${BASE_URL:-https://initai.dev}"
CONFIG_FILE=".initai.json"
INITAI_DIR="initai"
GLOBAL_CONFIG_FILE="$HOME/.initai"
CURRENT_VERSION="2.1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Command line options
FORCE=false
HELP=false
UPDATE=false
CLEAR=false
CLEAR_ALL=false

write_header() {
    echo -e "${BLUE}initai.dev - LLM Framework Manager${NC}"
    echo "Initializing your development environment..."
}

show_help() {
    echo "Usage: ./initai.sh [options]"
    echo ""
    echo "Options:"
    echo "  --base-url URL   Custom base URL (default: https://initai.dev)"
    echo "  --force          Force reconfiguration"
    echo "  --update         Force check for script updates"
    echo "  --clear          Remove initai folder and downloaded packages"
    echo "  --clear-all      Remove initai folder AND local .initai.json config"
    echo "  --help           Show this help"
    echo ""
    echo "Configuration file: $CONFIG_FILE"
    echo "Global config: $GLOBAL_CONFIG_FILE"
}

test_dependencies() {
    local missing_deps=()

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing_deps+=("curl or wget")
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${YELLOW}WARNING: jq not found. JSON parsing will use basic methods.${NC}"
    fi

    if ! command -v unzip >/dev/null 2>&1; then
        missing_deps+=("unzip")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}ERROR: Missing required dependencies: ${missing_deps[*]}${NC}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

# HTTP request function that works with curl or wget
http_get() {
    local url="$1"
    local output_file="$2"

    if command -v curl >/dev/null 2>&1; then
        if [ -n "$output_file" ]; then
            curl -fsSL "$url" -o "$output_file"
        else
            curl -fsSL "$url"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if [ -n "$output_file" ]; then
            wget -q "$url" -O "$output_file"
        else
            wget -q "$url" -O -
        fi
    else
        echo -e "${RED}ERROR: Neither curl nor wget found${NC}"
        exit 1
    fi
}

# JSON parsing function (works with or without jq)
json_get() {
    local json="$1"
    local key="$2"

    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq -r ".$key // empty"
    else
        # Basic JSON parsing using grep and sed
        echo "$json" | grep -o "\"$key\":[^,}]*" | sed "s/\"$key\"://" | tr -d ' "' | sed 's/,$//'
    fi
}

test_script_update() {
    echo -e "${CYAN}Checking for script updates...${NC}"

    local update_url="$BASE_URL/api/check-updates?client_version=$CURRENT_VERSION&script=shell"
    local response

    if ! response=$(http_get "$update_url"); then
        echo -e "${YELLOW}WARNING: Could not check for updates${NC}"
        return 1
    fi

    local update_available
    update_available=$(json_get "$response" "update_available")

    if [ "$update_available" = "true" ]; then
        local current_version
        current_version=$(json_get "$response" "current_version")

        echo -e "${YELLOW}Update available: v$current_version${NC}"
        echo -e "${CYAN}Current version: v$CURRENT_VERSION${NC}"

        if [ "$UPDATE" = true ] || confirm_update "$response"; then
            update_script "$response"
            return 0
        fi
    else
        echo -e "${GREEN}Script is up to date (v$CURRENT_VERSION)${NC}"
    fi

    return 1
}

confirm_update() {
    local update_info="$1"

    echo ""
    echo -e "${BLUE}Changelog:${NC}"
    # Basic changelog parsing (this would need to be enhanced based on actual API response format)
    echo "$update_info" | grep -o '"changes":\[[^]]*\]' | sed 's/"changes":\[//' | sed 's/\]$//' | tr ',' '\n' | sed 's/^"/  - /' | sed 's/"$//'

    echo ""
    read -p "Update to new version? (y/N): " response
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

update_script() {
    local update_info="$1"

    echo -e "${YELLOW}Downloading script update...${NC}"

    local download_url="$BASE_URL/initai.sh"
    local current_script="$0"
    local temp_script="${current_script}.new"

    if ! http_get "$download_url" "$temp_script"; then
        echo -e "${RED}ERROR: Failed to download script update${NC}"
        return 1
    fi

    # Backup current script
    if [ -f "$current_script" ]; then
        cp "$current_script" "${current_script}.backup"
    fi

    # Replace current script
    mv "$temp_script" "$current_script"
    chmod +x "$current_script"

    local new_version
    new_version=$(json_get "$update_info" "current_version")

    echo -e "${GREEN}Script updated to v$new_version${NC}"
    echo ""
    echo -e "${BLUE}Please restart initai.sh to use the new version:${NC}"
    echo -e "${YELLOW}  ./initai.sh${NC}"
    echo ""

    exit 0
}

test_configuration() {
    if [ -f "$CONFIG_FILE" ] && [ "$FORCE" != true ]; then
        echo -e "${GREEN}Found existing configuration${NC}"
        return 0
    else
        echo -e "${YELLOW}Setting up new configuration...${NC}"
        return 1
    fi
}

get_available_packages() {
    local packages_url="$BASE_URL/init/shared/list"
    echo -e "${CYAN}Getting available packages from $packages_url...${NC}"

    local response
    if ! response=$(http_get "$packages_url"); then
        echo -e "${RED}ERROR: Failed to get packages from $packages_url${NC}"
        exit 1
    fi

    local total
    total=$(json_get "$response" "total")
    echo -e "${GREEN}Found $total available packages${NC}"

    echo "$response"
}

select_llm() {
    echo ""
    echo -e "${BLUE}Which LLM will you primarily use in this project?${NC}"
    echo -e "${CYAN}  1) Claude (Anthropic) - Recommended for most development tasks${NC}"
    echo -e "${CYAN}  2) Gemini (Google) - Great for research and analysis${NC}"
    echo -e "${CYAN}  3) Universal - Works with any LLM${NC}"

    while true; do
        echo ""
        read -p "Select LLM (1-3): " selection
        case "$selection" in
            1) echo "claude"; return ;;
            2) echo "gemini"; return ;;
            3) echo "universal"; return ;;
            *) echo -e "${RED}Invalid selection. Please choose 1-3.${NC}" ;;
        esac
    done
}

select_package() {
    local packages_response="$1"
    local preferred_llm="$2"

    # Extract packages array from JSON (simplified)
    local packages
    if command -v jq >/dev/null 2>&1; then
        packages=$(echo "$packages_response" | jq -c '.packages[]')
    else
        # Basic extraction - this is simplified and may need refinement
        packages=$(echo "$packages_response" | grep -o '"framework":"[^"]*"[^}]*"llm":"[^"]*"[^}]*}' | sed 's/^/{/' | sed 's/$/}/')
    fi

    # Filter packages by preferred LLM
    local filtered_packages=()
    local package_count=0

    while IFS= read -r package; do
        if [ -n "$package" ]; then
            local package_llm
            package_llm=$(json_get "$package" "llm")

            if [ "$package_llm" = "$preferred_llm" ] || ([ "$preferred_llm" = "universal" ] && [ "$package_llm" = "universal" ]); then
                filtered_packages+=("$package")
                ((package_count++))
            fi
        fi
    done <<< "$packages"

    # If no packages found for preferred LLM, show all
    if [ $package_count -eq 0 ]; then
        echo -e "${YELLOW}No packages found for $preferred_llm, showing all packages...${NC}"
        while IFS= read -r package; do
            if [ -n "$package" ]; then
                filtered_packages+=("$package")
                ((package_count++))
            fi
        done <<< "$packages"
    fi

    if [ $package_count -eq 0 ]; then
        echo -e "${RED}ERROR: No packages available${NC}"
        exit 1
    fi

    echo ""
    echo -e "${BLUE}Available packages for $preferred_llm:${NC}"

    local i=1
    for package in "${filtered_packages[@]}"; do
        local framework description llm
        framework=$(json_get "$package" "framework")
        description=$(json_get "$package" "description")
        llm=$(json_get "$package" "llm")

        local display_name
        if [ "$llm" = "universal" ]; then
            display_name="$framework (Universal)"
        else
            display_name="$framework ($llm)"
        fi

        echo -e "${CYAN}  $i) $display_name${NC}"
        echo "     $description"
        ((i++))
    done

    while true; do
        echo ""
        read -p "Select package (1-$package_count): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le $package_count ]; then
            local selected_index=$((selection - 1))
            echo "${filtered_packages[$selected_index]}"
            return
        else
            echo -e "${RED}Invalid selection. Please choose 1-$package_count.${NC}"
        fi
    done
}

download_package() {
    local package="$1"
    local framework llm download_url

    framework=$(json_get "$package" "framework")
    llm=$(json_get "$package" "llm")
    download_url=$(json_get "$package" "download_url")

    local target_dir="$INITAI_DIR/$framework-$llm"

    echo ""
    echo -e "${YELLOW}Downloading $framework ($llm) package...${NC}"

    mkdir -p "$target_dir"

    local full_download_url="$BASE_URL$download_url"
    local zip_file="$target_dir/package.zip"

    echo -e "${CYAN}  Downloading from $full_download_url...${NC}"
    if ! http_get "$full_download_url" "$zip_file"; then
        echo -e "${RED}ERROR: Failed to download package${NC}"
        exit 1
    fi

    echo -e "${CYAN}  Extracting package...${NC}"
    if ! (cd "$target_dir" && unzip -q package.zip); then
        echo -e "${RED}ERROR: Failed to extract package${NC}"
        exit 1
    fi

    rm -f "$zip_file"

    echo -e "${GREEN}Package downloaded and extracted to: $target_dir${NC}"
    echo "$target_dir"
}

save_configuration() {
    local package="$1"
    local target_dir="$2"
    local preferred_llm="$3"

    local framework llm description download_url
    framework=$(json_get "$package" "framework")
    llm=$(json_get "$package" "llm")
    description=$(json_get "$package" "description")
    download_url=$(json_get "$package" "download_url")

    cat > "$CONFIG_FILE" << EOF
{
  "base_url": "$BASE_URL",
  "framework": "$framework",
  "llm": "$llm",
  "preferred_llm": "$preferred_llm",
  "description": "$description",
  "download_url": "$download_url",
  "target_dir": "$target_dir",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "script_version": "$CURRENT_VERSION"
}
EOF

    echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
}

generate_llm_instructions() {
    local preferred_llm="$1"
    local package="$2"
    local target_dir="$3"

    local framework
    framework=$(json_get "$package" "framework")

    local llm_file content

    case "$preferred_llm" in
        "claude")
            llm_file="CLAUDE.md"
            content="# Claude Instructions for $framework

## Communication Style
- Use bullet points for all responses
- Be concise and direct
- Focus on actionable information

## Project Setup
- Framework: $framework
- Package: $(json_get "$package" "llm")
- Initialization files: $target_dir

## Instructions
Please read and follow the initialization files in $target_dir on every session start:

- Load the framework configuration
- Apply the coding standards and patterns
- Use the provided templates and conventions

## Key Guidelines
- Always use bullet format for responses
- Prioritize developer productivity
- Follow the framework's best practices
- Maintain consistency across the project

---
Generated by initai.dev on $(date +%Y-%m-%d)"
            ;;
        "gemini")
            llm_file="GEMINI.md"
            content="# Gemini Instructions for $framework

## Communication Style
- Use bullet points for all responses
- Provide detailed explanations when needed
- Focus on research and analysis

## Project Setup
- Framework: $framework
- Package: $(json_get "$package" "llm")
- Initialization files: $target_dir

## Instructions
Please read and follow the initialization files in $target_dir on every session start:

- Load the framework configuration
- Apply the coding standards and patterns
- Use the provided templates and conventions

## Key Guidelines
- Always use bullet format for responses
- Leverage analytical capabilities for complex problems
- Follow the framework's best practices
- Provide comprehensive documentation

---
Generated by initai.dev on $(date +%Y-%m-%d)"
            ;;
        "universal")
            llm_file="LLM_INSTRUCTIONS.md"
            content="# LLM Instructions for $framework

## Communication Style
- Use bullet points for all responses
- Adapt to the specific LLM being used
- Focus on clear, actionable guidance

## Project Setup
- Framework: $framework
- Package: $(json_get "$package" "llm")
- Initialization files: $target_dir

## Instructions
Please read and follow the initialization files in $target_dir on every session start:

- Load the framework configuration
- Apply the coding standards and patterns
- Use the provided templates and conventions

## Key Guidelines
- Always use bullet format for responses
- Work with any LLM provider
- Follow the framework's best practices
- Maintain consistency across the project

---
Generated by initai.dev on $(date +%Y-%m-%d)"
            ;;
    esac

    if [ -n "$content" ]; then
        if echo "$content" > "$llm_file"; then
            echo -e "${GREEN}Created $llm_file with project instructions${NC}"
        else
            echo -e "${YELLOW}WARNING: Could not create $llm_file${NC}"
        fi
    fi
}

show_package_instructions() {
    local target_dir="$1"
    local init_file="$target_dir/init.md"

    if [ -f "$init_file" ]; then
        echo ""
        echo -e "${BLUE}=== Package Instructions ===${NC}"
        head -10 "$init_file"
        if [ "$(wc -l < "$init_file")" -gt 10 ]; then
            echo -e "${YELLOW}... (see $init_file for full instructions)${NC}"
        fi
        echo -e "${BLUE}===========================${NC}"
    fi
}

clear_initai_folder() {
    echo -e "${YELLOW}Cleaning up initai folder...${NC}"

    if [ -d "$INITAI_DIR" ]; then
        if rm -rf "$INITAI_DIR"; then
            echo -e "${GREEN}Removed initai folder: $INITAI_DIR${NC}"
        else
            echo -e "${YELLOW}WARNING: Could not remove initai folder${NC}"
        fi
    else
        echo -e "${CYAN}No initai folder found to remove${NC}"
    fi

    # Also remove LLM instruction files
    local llm_files=("CLAUDE.md" "GEMINI.md" "LLM_INSTRUCTIONS.md")
    for file in "${llm_files[@]}"; do
        if [ -f "$file" ]; then
            if rm -f "$file"; then
                echo -e "${GREEN}Removed LLM instruction file: $file${NC}"
            else
                echo -e "${YELLOW}WARNING: Could not remove $file${NC}"
            fi
        fi
    done
}

clear_all_local_files() {
    echo -e "${YELLOW}Cleaning up all local initai files...${NC}"

    clear_initai_folder

    if [ -f "$CONFIG_FILE" ]; then
        if rm -f "$CONFIG_FILE"; then
            echo -e "${GREEN}Removed local configuration: $CONFIG_FILE${NC}"
        else
            echo -e "${YELLOW}WARNING: Could not remove $CONFIG_FILE${NC}"
        fi
    else
        echo -e "${CYAN}No local configuration found to remove${NC}"
    fi

    echo ""
    echo -e "${GREEN}Local cleanup complete!${NC}"
    echo -e "${BLUE}Note: Global user preferences in $GLOBAL_CONFIG_FILE are preserved${NC}"
}

get_current_configuration() {
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    fi
}

test_package_update() {
    local config="$1"

    if [ -z "$config" ]; then
        return 1
    fi

    echo -e "${CYAN}Checking for package updates...${NC}"

    local framework llm
    framework=$(json_get "$config" "framework")
    llm=$(json_get "$config" "llm")

    local package_url="$BASE_URL/init/shared/$framework/$llm"

    # Simple check - just verify package still exists
    if http_get "$package_url" > /dev/null 2>&1; then
        echo -e "${GREEN}Package check completed${NC}"
    else
        echo -e "${YELLOW}Could not check for package updates${NC}"
    fi

    return 1  # For now, don't auto-update packages
}

start_claude() {
    local config="$1"

    echo ""
    echo -e "${GREEN}Starting Claude in console...${NC}"

    if command -v claude-code >/dev/null 2>&1; then
        echo -e "${CYAN}Launching Claude Code CLI...${NC}"
        claude-code
    elif command -v claude >/dev/null 2>&1; then
        echo -e "${CYAN}Launching Claude CLI...${NC}"
        claude
    else
        echo -e "${YELLOW}Claude CLI not found. Please install Claude Code CLI:${NC}"
        echo "Visit: https://claude.ai/code for installation instructions"
    fi

    echo ""
    echo -e "${BLUE}=== Quick Start ===${NC}"
    echo "1. Open your project files"

    local target_dir
    target_dir=$(json_get "$config" "target_dir")
    echo "2. Load the framework configuration from: $target_dir"
    echo "3. Follow the instructions in your LLM-specific .md file"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --base-url)
            BASE_URL="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            HELP=true
            shift
            ;;
        --update)
            UPDATE=true
            shift
            ;;
        --clear)
            CLEAR=true
            shift
            ;;
        --clear-all)
            CLEAR_ALL=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    write_header

    if [ "$HELP" = true ]; then
        show_help
        exit 0
    fi

    # Handle clear operations
    if [ "$CLEAR" = true ]; then
        clear_initai_folder
        exit 0
    fi

    if [ "$CLEAR_ALL" = true ]; then
        clear_all_local_files
        exit 0
    fi

    test_dependencies

    # Always check for script updates
    if test_script_update; then
        return  # Script was updated, exit current execution
    fi

    if ! test_configuration; then
        # New setup - ask for LLM preference first
        preferred_llm=$(select_llm)

        packages_response=$(get_available_packages)
        selected_package=$(select_package "$packages_response" "$preferred_llm")

        echo ""
        local framework llm
        framework=$(json_get "$selected_package" "framework")
        llm=$(json_get "$selected_package" "llm")
        echo -e "${BLUE}Selected: $framework ($llm) for $preferred_llm${NC}"

        target_dir=$(download_package "$selected_package")
        save_configuration "$selected_package" "$target_dir" "$preferred_llm"
        generate_llm_instructions "$preferred_llm" "$selected_package" "$target_dir"
        show_package_instructions "$target_dir"

        echo ""
        echo -e "${GREEN}Setup complete!${NC}"
        echo -e "${YELLOW}Framework files: ./$target_dir/${NC}"
        echo -e "${YELLOW}LLM instructions: ./CLAUDE.md (or ./GEMINI.md)${NC}"
        echo -e "${BLUE}Tell your LLM: 'Load the initialization files and follow the project instructions'${NC}"
    else
        # Existing configuration - check for updates and show package instructions
        config=$(get_current_configuration)
        if [ -n "$config" ]; then
            local framework llm preferred_llm target_dir
            framework=$(json_get "$config" "framework")
            llm=$(json_get "$config" "llm")
            preferred_llm=$(json_get "$config" "preferred_llm")
            target_dir=$(json_get "$config" "target_dir")

            echo -e "${CYAN}Current configuration: $framework ($llm) for $preferred_llm${NC}"
            echo -e "${YELLOW}Target directory: $target_dir${NC}"

            # Check for package updates
            test_package_update "$config" > /dev/null

            # Show package instructions on every run
            show_package_instructions "$target_dir"

            echo -e "${BLUE}Use --force to reconfigure${NC}"

            # Launch Claude after configuration
            start_claude "$config"
        fi
    fi

    echo ""
    echo -e "${GREEN}Ready to code with initai.dev!${NC}"
}

# Run main function
main "$@"