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
LIGHT_BLUE='\033[1;34m'
LIGHT_CYAN='\033[1;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Command line options
FORCE=false
HELP=false
UPDATE=false
CLEAR=false
CLEAR_ALL=false
VERBOSE=false
IGNORE_SSL=false

write_header() {
    echo -e "${LIGHT_CYAN}initai.dev - LLM Framework Manager ${GRAY}v${CURRENT_VERSION}${NC}"
    echo -e "${GRAY}Initializing your development environment...${NC}"
}

verbose_echo() {
    if [ "$VERBOSE" = true ]; then
        echo -e "$@"
    fi
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
    echo "  --verbose        Show detailed progress messages"
    echo "  --ignore-ssl-issues  Skip SSL certificate verification"
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
        verbose_echo "${YELLOW}WARNING: jq not found. JSON parsing will use basic methods.${NC}"
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
        local curl_flags="-fsSL"
        if [ "$IGNORE_SSL" = true ]; then
            curl_flags="$curl_flags -k"
        fi

        if [ -n "$output_file" ]; then
            eval "curl $curl_flags \"$url\" -o \"$output_file\""
        else
            eval "curl $curl_flags \"$url\""
        fi
    elif command -v wget >/dev/null 2>&1; then
        local wget_flags="-q"
        if [ "$IGNORE_SSL" = true ]; then
            wget_flags="$wget_flags --no-check-certificate"
        fi

        if [ -n "$output_file" ]; then
            eval "wget $wget_flags \"$url\" -O \"$output_file\""
        else
            eval "wget $wget_flags \"$url\" -O -"
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
        # Basic JSON parsing using grep and sed (handle multiline JSON and spaces)
        echo "$json" | tr -d '\n\r' | grep -o "\"$key\":[[:space:]]*\"[^\"]*\"" | sed "s/\"$key\":[[:space:]]*\"//" | sed 's/"$//'
    fi
}

test_script_update() {
    verbose_echo "${CYAN}Checking for script updates...${NC}"

    local update_url="$BASE_URL/api/check-updates?client_version=$CURRENT_VERSION&script=shell"
    local response

    if ! response=$(http_get "$update_url"); then
        verbose_echo "${YELLOW}WARNING: Could not check for updates${NC}"
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
        verbose_echo "${GREEN}Script is up to date (v$CURRENT_VERSION)${NC}"
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

    verbose_echo "${YELLOW}Downloading script update...${NC}"

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
        verbose_echo "${GREEN}Found existing configuration${NC}"
        return 0
    else
        verbose_echo "${YELLOW}Setting up new configuration...${NC}"
        return 1
    fi
}

get_available_packages() {
    local packages_url="$BASE_URL/init/shared/list"
    verbose_echo "${CYAN}Getting available packages from $packages_url...${NC}"

    local response
    if ! response=$(http_get "$packages_url"); then
        echo -e "${RED}ERROR: Failed to get packages from $packages_url${NC}"
        exit 1
    fi

    local total
    total=$(json_get "$response" "total")
    verbose_echo "${GREEN}Found $total available packages${NC}"

    echo "$response"
}

select_framework() {
    local api_response="$1"

    # Extract frameworks from new API structure
    local frameworks=()
    local framework_descriptions=()

    if command -v jq >/dev/null 2>&1; then
        local frameworks_json
        frameworks_json=$(echo "$api_response" | jq -c '.frameworks[]')
        while IFS= read -r framework_obj; do
            if [ -n "$framework_obj" ]; then
                local name description
                name=$(echo "$framework_obj" | jq -r '.name')
                description=$(echo "$framework_obj" | jq -r '.description')
                frameworks+=("$name")
                framework_descriptions+=("$description")
            fi
        done <<< "$frameworks_json"
    else
        # Basic parsing without jq - simplified approach for nested structure
        # Extract framework names from the flattened JSON
        local framework_names
        framework_names=$(echo "$api_response" | tr -d '\n\r' | grep -o '"frameworks":\[{[^]]*\]' | grep -o '"name":"[^"]*"' | head -1 | sed 's/"name":"//' | sed 's/"//')

        if [ -n "$framework_names" ]; then
            frameworks+=("$framework_names")
            framework_descriptions+=("Framework for enhanced development productivity")
        else
            # Fallback - extract the first framework name from anywhere in the response
            local fallback_name
            fallback_name=$(echo "$api_response" | grep -o '"name":"blissframework"' | head -1 | sed 's/"name":"//' | sed 's/"//')
            if [ -n "$fallback_name" ]; then
                frameworks+=("$fallback_name")
                framework_descriptions+=("Framework for enhanced development productivity")
            fi
        fi
    fi

    if [ ${#frameworks[@]} -eq 0 ]; then
        echo -e "${RED}ERROR: No frameworks available${NC}" >&2
        exit 1
    fi

    echo "" >&2
    echo -e "${BLUE}Which framework would you like to use?${NC}" >&2

    local i=1
    for framework in "${frameworks[@]}"; do
        local description="${framework_descriptions[$((i-1))]}"
        echo -e "${CYAN}  $i) $framework${NC}" >&2
        echo "     $description" >&2
        ((i++))
    done

    while true; do
        echo "" >&2
        read -p "Select framework (1-${#frameworks[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#frameworks[@]} ]; then
            local selected_index=$((selection - 1))
            echo "${frameworks[$selected_index]}"
            return
        else
            echo -e "${RED}Invalid selection. Please choose 1-${#frameworks[@]}.${NC}" >&2
        fi
    done
}

select_scope() {
    local api_response="$1"
    local selected_framework="$2"

    # Extract scopes for the selected framework
    local scopes=()
    local scope_descriptions=()

    if command -v jq >/dev/null 2>&1; then
        local framework_obj
        framework_obj=$(echo "$api_response" | jq -c ".frameworks[] | select(.name == \"$selected_framework\")")
        if [ -n "$framework_obj" ]; then
            local scopes_json
            scopes_json=$(echo "$framework_obj" | jq -c '.scopes[]')
            while IFS= read -r scope_obj; do
                if [ -n "$scope_obj" ]; then
                    local name description
                    name=$(echo "$scope_obj" | jq -r '.name')
                    description=$(echo "$scope_obj" | jq -r '.description')
                    scopes+=("$name")
                    scope_descriptions+=("$description")
                fi
            done <<< "$scopes_json"
        fi
    else
        # Basic parsing without jq - simplified fallback for known structure
        # For blissframework, we know it has backend and frontend scopes
        if [ "$selected_framework" = "blissframework" ]; then
            scopes+=("backend")
            scope_descriptions+=("Server-side development and APIs")
            scopes+=("frontend")
            scope_descriptions+=("Client-side user interface development")
        else
            # Generic fallback
            scopes+=("backend")
            scope_descriptions+=("Server-side development")
        fi
    fi

    if [ ${#scopes[@]} -eq 0 ]; then
        echo -e "${RED}ERROR: No scopes available for $selected_framework${NC}" >&2
        exit 1
    fi

    echo "" >&2
    echo -e "${BLUE}Which scope would you like to use with $selected_framework?${NC}" >&2

    local i=1
    for scope in "${scopes[@]}"; do
        local description="${scope_descriptions[$((i-1))]}"
        echo -e "${CYAN}  $i) $scope${NC}" >&2
        echo "     $description" >&2
        ((i++))
    done

    while true; do
        echo "" >&2
        read -p "Select scope (1-${#scopes[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#scopes[@]} ]; then
            local selected_index=$((selection - 1))
            echo "${scopes[$selected_index]}"
            return
        else
            echo -e "${RED}Invalid selection. Please choose 1-${#scopes[@]}.${NC}" >&2
        fi
    done
}

select_llm() {
    local api_response="$1"
    local selected_framework="$2"
    local selected_scope="$3"

    # Extract available LLM variants for the selected framework and scope
    local llms=()
    local llm_descriptions=()

    if command -v jq >/dev/null 2>&1; then
        local framework_obj
        framework_obj=$(echo "$api_response" | jq -c ".frameworks[] | select(.name == \"$selected_framework\")")
        if [ -n "$framework_obj" ]; then
            local scope_obj
            scope_obj=$(echo "$framework_obj" | jq -c ".scopes[] | select(.name == \"$selected_scope\")")
            if [ -n "$scope_obj" ]; then
                local variants_json
                variants_json=$(echo "$scope_obj" | jq -c '.variants[]')
                while IFS= read -r variant_obj; do
                    if [ -n "$variant_obj" ]; then
                        local name description
                        name=$(echo "$variant_obj" | jq -r '.name')
                        description=$(echo "$variant_obj" | jq -r '.description')
                        llms+=("$name")
                        llm_descriptions+=("$description")
                    fi
                done <<< "$variants_json"
            fi
        fi
    else
        # Basic parsing without jq - simplified fallback for known structure
        # For blissframework, we know it has universal and claude variants
        if [ "$selected_framework" = "blissframework" ]; then
            llms+=("universal")
            llm_descriptions+=("Works with any LLM")
            llms+=("claude")
            llm_descriptions+=("Optimized for Claude AI")
        else
            # Generic fallback
            llms+=("universal")
            llm_descriptions+=("Works with any LLM")
        fi
    fi

    if [ ${#llms[@]} -eq 0 ]; then
        echo -e "${RED}ERROR: No LLM variants available for $selected_framework/$selected_scope${NC}" >&2
        exit 1
    fi

    echo "" >&2
    echo -e "${BLUE}Which LLM will you use with $selected_framework ($selected_scope)?${NC}" >&2

    local i=1
    for llm in "${llms[@]}"; do
        local description="${llm_descriptions[$((i-1))]}"
        case "$llm" in
            "claude") echo -e "${CYAN}  $i) Claude (Anthropic) - $description${NC}" >&2 ;;
            "gemini") echo -e "${CYAN}  $i) Gemini (Google) - $description${NC}" >&2 ;;
            "universal") echo -e "${CYAN}  $i) Universal - $description${NC}" >&2 ;;
            *) echo -e "${CYAN}  $i) $llm - $description${NC}" >&2 ;;
        esac
        ((i++))
    done

    while true; do
        echo "" >&2
        read -p "Select LLM (1-${#llms[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#llms[@]} ]; then
            local selected_index=$((selection - 1))
            echo "${llms[$selected_index]}"
            return
        else
            echo -e "${RED}Invalid selection. Please choose 1-${#llms[@]}.${NC}" >&2
        fi
    done
}

find_download_url() {
    local api_response="$1"
    local selected_framework="$2"
    local selected_scope="$3"
    local selected_llm="$4"

    # Find the download URL for the specific combination
    if command -v jq >/dev/null 2>&1; then
        local framework_obj
        framework_obj=$(echo "$api_response" | jq -c ".frameworks[] | select(.name == \"$selected_framework\")")
        if [ -n "$framework_obj" ]; then
            local scope_obj
            scope_obj=$(echo "$framework_obj" | jq -c ".scopes[] | select(.name == \"$selected_scope\")")
            if [ -n "$scope_obj" ]; then
                local variant_obj
                variant_obj=$(echo "$scope_obj" | jq -c ".variants[] | select(.name == \"$selected_llm\")")
                if [ -n "$variant_obj" ]; then
                    local download_url
                    download_url=$(echo "$variant_obj" | jq -r '.download_url')
                    echo "$download_url"
                    return
                fi
            fi
        fi
    else
        # Basic parsing - construct URL from pattern
        if [ "$selected_llm" = "universal" ]; then
            echo "/init/shared/$selected_framework/$selected_scope"
        else
            echo "/init/shared/$selected_framework/$selected_scope/$selected_llm"
        fi
        return
    fi

    echo -e "${RED}ERROR: Download URL not found for $selected_framework/$selected_scope/$selected_llm${NC}" >&2
    exit 1
}

download_package() {
    local framework="$1"
    local scope="$2"
    local llm="$3"
    local download_url="$4"

    local target_dir="$INITAI_DIR/$framework-$scope-$llm"

    echo "" >&2
    verbose_echo "${YELLOW}Downloading $framework ($scope) package for $llm...${NC}" >&2

    mkdir -p "$target_dir"

    local full_download_url="$BASE_URL$download_url"
    local zip_file="$target_dir/package.zip"

    verbose_echo "${CYAN}  Downloading from $full_download_url...${NC}" >&2
    if ! http_get "$full_download_url" "$zip_file"; then
        echo -e "${RED}ERROR: Failed to download package${NC}" >&2
        exit 1
    fi

    verbose_echo "${CYAN}  Extracting package...${NC}" >&2
    if ! (cd "$target_dir" && unzip -qo package.zip); then
        echo -e "${RED}ERROR: Failed to extract package${NC}" >&2
        exit 1
    fi

    rm -f "$zip_file"

    echo -e "${GREEN}Package downloaded and extracted to: $target_dir${NC}" >&2
    echo "$target_dir"
}

save_configuration() {
    local framework="$1"
    local scope="$2"
    local llm="$3"
    local target_dir="$4"

    cat > "$CONFIG_FILE" << EOF
{
  "base_url": "$BASE_URL",
  "framework": "$framework",
  "scope": "$scope",
  "llm": "$llm",
  "description": "$framework $scope development for $llm",
  "download_url": "/init/shared/$framework/$scope$([ "$llm" != "universal" ] && echo "/$llm" || echo "")",
  "target_dir": "$target_dir",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "script_version": "$CURRENT_VERSION"
}
EOF

    echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
}

generate_llm_instructions() {
    local preferred_llm="$1"
    local framework="$2"
    local scope="$3"
    local target_dir="$4"

    local llm_file content

    case "$preferred_llm" in
        "claude")
            llm_file="CLAUDE.md"
            content="# Claude Instructions for $framework ($scope)

## Project Context Management
- **Always save project context and notes to PROJECT.md**
- CLAUDE.md contains only initialization instructions (don't modify)
- Use PROJECT.md for ongoing project documentation, decisions, and context
- Load PROJECT.md content at start of each session to continue where you left off

## Communication Style
- Use bullet points for all responses
- Be concise and direct
- Focus on actionable information

## Project Setup
- Framework: $framework
- Scope: $scope
- LLM specialization: $preferred_llm
- Initialization files: $target_dir

## Instructions
Please read and follow the initialization files in $target_dir on every session start:

- Load the framework configuration
- Apply the coding standards and patterns
- Use the provided templates and conventions
- **Load PROJECT.md to understand current project state**

## File Structure
- CLAUDE.md - Initialization instructions (static - don't modify)
- PROJECT.md - Your working context (dynamic - update regularly)
- $target_dir/ - Framework files and templates

## Key Guidelines
- Always use bullet format for responses
- Prioritize developer productivity
- Follow the framework's best practices
- Maintain consistency across the project
- **Save all project decisions and context to PROJECT.md**

---
Generated by initai.dev on $(date +%Y-%m-%d)"
            ;;
        "gemini")
            llm_file="GEMINI.md"
            content="# Gemini Instructions for $framework ($scope)

## Communication Style
- Use bullet points for all responses
- Provide detailed explanations when needed
- Focus on research and analysis

## Project Setup
- Framework: $framework
- Scope: $scope
- LLM specialization: $preferred_llm
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
            content="# LLM Instructions for $framework ($scope)

## Communication Style
- Use bullet points for all responses
- Adapt to the specific LLM being used
- Focus on clear, actionable guidance

## Project Setup
- Framework: $framework
- Scope: $scope
- LLM specialization: $preferred_llm
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
        # Check if LLM instruction file already exists
        if [ -f "$llm_file" ]; then
            echo ""
            read -p "$llm_file už existuje. Přepsat? (y/n): " overwrite
            if [[ ! "$overwrite" =~ ^[yY]$ ]]; then
                echo -e "${CYAN}Ponecháván stávající $llm_file${NC}"
                echo ""
                echo -e "${YELLOW}UPOZORNĚNÍ: Ujistěte se, že váš $llm_file obsahuje instrukci:${NC}"
                echo -e "${BLUE}\"Please read and follow the initialization files in $target_dir on every session start\"${NC}"
                echo ""
                return
            fi
        fi

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

    verbose_echo "${CYAN}Checking for package updates...${NC}"

    local framework scope llm
    framework=$(json_get "$config" "framework")
    scope=$(json_get "$config" "scope")
    llm=$(json_get "$config" "llm")

    local package_url
    if [ "$llm" = "universal" ]; then
        package_url="$BASE_URL/init/shared/$framework/$scope"
    else
        package_url="$BASE_URL/init/shared/$framework/$scope/$llm"
    fi

    # Simple check - just verify package still exists
    if http_get "$package_url" > /dev/null 2>&1; then
        verbose_echo "${GREEN}Package check completed${NC}"
    else
        verbose_echo "${YELLOW}Could not check for package updates${NC}"
    fi

    return 1  # For now, don't auto-update packages
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
        --verbose)
            VERBOSE=true
            shift
            ;;
        --ignore-ssl-issues)
            IGNORE_SSL=true
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
        # New setup - ask for framework, scope, then LLM
        api_response=$(get_available_packages)

        selected_framework=$(select_framework "$api_response")
        selected_scope=$(select_scope "$api_response" "$selected_framework")
        selected_llm=$(select_llm "$api_response" "$selected_framework" "$selected_scope")
        download_url=$(find_download_url "$api_response" "$selected_framework" "$selected_scope" "$selected_llm")

        echo ""
        echo -e "${BLUE}Selected: $selected_framework ($selected_scope) for $selected_llm${NC}"

        echo -e "${CYAN}Debug: About to download package...${NC}"
        target_dir=$(download_package "$selected_framework" "$selected_scope" "$selected_llm" "$download_url")
        save_configuration "$selected_framework" "$selected_scope" "$selected_llm" "$target_dir"
        generate_llm_instructions "$selected_llm" "$selected_framework" "$selected_scope" "$target_dir"
        show_package_instructions "$target_dir"

        echo ""
        echo -e "${GREEN}Setup complete!${NC}"
        echo -e "${YELLOW}Framework files: ./$target_dir/${NC}"
        echo -e "${YELLOW}LLM instructions: ./CLAUDE.md (or ./GEMINI.md)${NC}"
        echo -e "${BLUE}Tell your LLM: 'Load the initialization files and follow the project instructions'${NC}"

        # Ask if user wants to launch Claude (only if Claude was selected)
        if [ "$selected_llm" = "claude" ]; then
            echo ""
            read -p "Spustit Claude? (y/n): " launch_claude
            if [[ "$launch_claude" =~ ^[yY]$ ]]; then
                # Save preference and launch Claude
                echo "launch_claude=true" >> .initai
                if command -v claude-code >/dev/null 2>&1; then
                    echo -e "${CYAN}Spouštím Claude Code...${NC}"
                    claude-code
                elif command -v claude >/dev/null 2>&1; then
                    echo -e "${CYAN}Spouštím Claude CLI...${NC}"
                    claude
                else
                    echo -e "${YELLOW}Claude CLI nebyl nalezen. Prosím nainstalujte Claude Code CLI:${NC}"
                    echo "https://claude.ai/code"
                fi
            else
                echo "launch_claude=false" >> .initai
            fi
        fi
    else
        # Existing configuration - check for updates and show package instructions
        config=$(get_current_configuration)
        if [ -n "$config" ]; then
            local framework llm scope target_dir
            framework=$(json_get "$config" "framework")
            scope=$(json_get "$config" "scope")
            llm=$(json_get "$config" "llm")
            target_dir=$(json_get "$config" "target_dir")

            echo -e "${CYAN}Current configuration: $framework ($scope) for $llm${NC}"
            echo -e "${YELLOW}Target directory: $target_dir${NC}"

            # Check for package updates
            test_package_update "$config" > /dev/null

            # Show package instructions on every run
            show_package_instructions "$target_dir"

            echo -e "${BLUE}Use --force to reconfigure${NC}"
        fi
    fi
}

# Run main function
main "$@"