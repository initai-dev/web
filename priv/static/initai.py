#!/usr/bin/env python3
"""
initai.dev Python installer
Initialize LLM frameworks quickly and consistently
"""

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import zipfile
from datetime import datetime
from pathlib import Path
import urllib.request
import urllib.error


class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    LIGHT_CYAN = '\033[96m'
    GRAY = '\033[90m'
    WHITE = '\033[97m'
    RESET = '\033[0m'

    @staticmethod
    def print_colored(message, color):
        print(f"{color}{message}{Colors.RESET}")


class InitAI:
    def __init__(self, base_url="https://initai.dev", force=False, verbose=False,
                 ignore_ssl_issues=False, update=False, clear=False, clear_all=False):
        self.base_url = base_url
        self.force = force
        self.verbose = verbose
        self.ignore_ssl_issues = ignore_ssl_issues
        self.update = update
        self.clear = clear
        self.clear_all = clear_all

        self.config_file = ".initai.json"
        self.initai_dir = "initai"
        self.current_version = "2.1.0"

        # Platform-specific paths
        if platform.system() == "Windows":
            self.app_data_path = Path(os.environ.get("LOCALAPPDATA", "")) / "initai"
            self.global_config_file = Path.home() / ".initai"
        else:
            self.app_data_path = Path.home() / ".local/share/initai"
            self.global_config_file = Path.home() / ".initai"

        self.installed_script_path = self.app_data_path / "install.py"
        self.version_file = self.app_data_path / ".initai-version"

    def write_header(self):
        Colors.print_colored(f"initai.dev - LLM Framework Manager v{self.current_version}", Colors.CYAN)
        Colors.print_colored("Initializing your development environment...", Colors.GRAY)

    def write_verbose_message(self, message, color=None):
        if self.verbose:
            if color:
                Colors.print_colored(message, color)
            else:
                print(message)

    def show_help(self):
        print("Usage: python initai.py [options]")
        print()
        print("Options:")
        print("  --base-url URL       Custom base URL (default: https://initai.dev)")
        print("  --force              Force reconfiguration")
        print("  --update             Force check for script updates")
        print("  --clear              Remove initai folder and downloaded packages")
        print("  --clear-all          Remove initai folder AND local .initai.json config")
        print("  --verbose            Show detailed progress messages")
        print("  --ignore-ssl-issues  Skip SSL certificate verification")
        print("  --help               Show this help")
        print()
        print(f"Configuration file: {self.config_file}")
        print(f"App data location: {self.app_data_path}")

    def test_dependencies(self):
        # Python has urllib built-in, so no external dependencies needed
        pass

    def initialize_app_data(self):
        if not self.app_data_path.exists():
            self.app_data_path.mkdir(parents=True, exist_ok=True)
            Colors.print_colored(f"Created app data directory: {self.app_data_path}", Colors.GREEN)

    def http_request(self, url, use_json=False):
        """Make HTTP request with optional SSL bypass"""
        try:
            if self.ignore_ssl_issues:
                import ssl
                ssl_context = ssl.create_default_context()
                ssl_context.check_hostname = False
                ssl_context.verify_mode = ssl.CERT_NONE
            else:
                ssl_context = None

            req = urllib.request.Request(url)

            if ssl_context:
                response = urllib.request.urlopen(req, context=ssl_context)
            else:
                response = urllib.request.urlopen(req)

            if use_json:
                return json.loads(response.read().decode('utf-8'))
            else:
                return response.read()
        except Exception as e:
            raise Exception(f"HTTP request failed: {e}")

    def test_script_update(self):
        self.write_verbose_message("Checking for script updates...", Colors.CYAN)

        try:
            update_url = f"{self.base_url}/api/check-updates?client_version={self.current_version}&script=python"
            response = self.http_request(update_url, use_json=True)

            if response.get('update_available'):
                Colors.print_colored(f"Update available: v{response.get('current_version')}", Colors.YELLOW)
                Colors.print_colored(f"Current version: v{self.current_version}", Colors.CYAN)

                if self.update or self.confirm_update(response):
                    self.update_script(response)
                    return True
            else:
                Colors.print_colored(f"Script is up to date (v{self.current_version})", Colors.GREEN)

            return False
        except Exception as e:
            self.write_verbose_message(f"WARNING: Could not check for updates: {e}", Colors.YELLOW)
            return False

    def confirm_update(self, update_info):
        print()
        Colors.print_colored("Changelog:", Colors.BLUE)
        for change in update_info.get('changelog', []):
            Colors.print_colored(f"  v{change.get('version')} ({change.get('date')}):", Colors.CYAN)
            for item in change.get('changes', []):
                Colors.print_colored(f"    - {item}", Colors.WHITE)

        print()
        response = input(f"Update to v{update_info.get('current_version')}? (y/N): ").strip()
        return response.lower() in ['y', 'yes']

    def update_script(self, update_info):
        self.write_verbose_message("Downloading script update...", Colors.YELLOW)

        try:
            # Download new initai.py script
            download_url = f"{self.base_url}/initai.py"
            current_script = Path(__file__)
            temp_script = current_script.with_suffix('.new')

            urllib.request.urlretrieve(download_url, temp_script)

            # Backup current script
            if current_script.exists():
                backup_script = current_script.with_suffix('.backup')
                shutil.copy2(current_script, backup_script)

            # Replace current script
            shutil.move(temp_script, current_script)

            Colors.print_colored(f"Script updated to v{update_info.get('current_version')}", Colors.GREEN)
            print()
            Colors.print_colored("Please restart initai.py to use the new version:", Colors.BLUE)
            Colors.print_colored("  python initai.py", Colors.YELLOW)
            print()

            sys.exit(0)
        except Exception as e:
            Colors.print_colored(f"ERROR: Failed to update script: {e}", Colors.RED)
            backup_script = Path(__file__).with_suffix('.backup')
            if backup_script.exists():
                shutil.move(backup_script, Path(__file__))
                Colors.print_colored("Restored backup script", Colors.YELLOW)
            raise

    def test_configuration(self):
        config_path = Path(self.config_file)
        if config_path.exists() and not self.force:
            self.write_verbose_message("Found existing configuration", Colors.GREEN)
            return True
        else:
            Colors.print_colored("Setting up new configuration...", Colors.YELLOW)
            return False

    def get_available_packages(self):
        packages_url = f"{self.base_url}/init/shared/list"
        self.write_verbose_message(f"Getting available frameworks from {packages_url}...", Colors.CYAN)

        try:
            response = self.http_request(packages_url, use_json=True)
            frameworks = response.get('frameworks', [])
            self.write_verbose_message(f"Found {len(frameworks)} available frameworks", Colors.GREEN)
            return frameworks
        except Exception as e:
            Colors.print_colored(f"ERROR: Failed to get frameworks from {packages_url}", Colors.RED)
            Colors.print_colored(str(e), Colors.RED)
            sys.exit(1)

    def select_framework(self, frameworks):
        if not frameworks:
            Colors.print_colored("ERROR: No frameworks available", Colors.RED)
            sys.exit(1)

        print()
        Colors.print_colored("Which framework would you like to use?", Colors.BLUE)

        for i, framework in enumerate(frameworks):
            Colors.print_colored(f"  {i + 1}) {framework.get('name')}", Colors.CYAN)
            print(f"     {framework.get('description', '')}")

        while True:
            try:
                selection = input(f"\nSelect framework (1-{len(frameworks)}): ").strip()
                selection_num = int(selection)
                if 1 <= selection_num <= len(frameworks):
                    return frameworks[selection_num - 1].get('name')
                else:
                    print("Invalid selection. Please try again.")
            except ValueError:
                print("Please enter a valid number.")

    def select_scope(self, frameworks, selected_framework):
        framework = next((f for f in frameworks if f.get('name') == selected_framework), None)
        if not framework:
            Colors.print_colored(f"ERROR: Framework '{selected_framework}' not found", Colors.RED)
            sys.exit(1)

        scopes = framework.get('scopes', [])
        if not scopes:
            Colors.print_colored(f"ERROR: No scopes available for {selected_framework}", Colors.RED)
            sys.exit(1)

        print()
        Colors.print_colored(f"Which development scope for {selected_framework}?", Colors.BLUE)

        scope_descriptions = {
            "backend": "Backend - Server-side development, APIs, databases",
            "frontend": "Frontend - Client-side development, UI/UX",
            "fullstack": "Fullstack - Complete application development"
        }

        for i, scope in enumerate(scopes):
            scope_name = scope.get('name')
            description = scope_descriptions.get(scope_name, f"{scope_name} - {scope.get('description', '')}")
            Colors.print_colored(f"  {i + 1}) {description}", Colors.CYAN)

        while True:
            try:
                selection = input(f"\nSelect scope (1-{len(scopes)}): ").strip()
                selection_num = int(selection)
                if 1 <= selection_num <= len(scopes):
                    return scopes[selection_num - 1].get('name')
                else:
                    print("Invalid selection. Please try again.")
            except ValueError:
                print("Please enter a valid number.")

    def select_llm(self, frameworks, selected_framework, selected_scope):
        framework = next((f for f in frameworks if f.get('name') == selected_framework), None)
        if not framework:
            Colors.print_colored(f"ERROR: Framework '{selected_framework}' not found", Colors.RED)
            sys.exit(1)

        scope = next((s for s in framework.get('scopes', []) if s.get('name') == selected_scope), None)
        if not scope:
            Colors.print_colored(f"ERROR: Scope '{selected_scope}' not found for {selected_framework}", Colors.RED)
            sys.exit(1)

        variants = scope.get('variants', [])
        if not variants:
            Colors.print_colored(f"ERROR: No LLM variants available for {selected_framework}/{selected_scope}", Colors.RED)
            sys.exit(1)

        print()
        Colors.print_colored(f"Which LLM will you use with {selected_framework} ({selected_scope})?", Colors.BLUE)

        llm_descriptions = {
            "claude": lambda v: f"Claude (Anthropic) - {v.get('description', '')}",
            "gemini": lambda v: f"Gemini (Google) - {v.get('description', '')}",
            "universal": lambda v: f"Universal - {v.get('description', '')}"
        }

        for i, variant in enumerate(variants):
            variant_name = variant.get('name')
            if variant_name in llm_descriptions:
                description = llm_descriptions[variant_name](variant)
            else:
                description = f"{variant_name} - {variant.get('description', '')}"
            Colors.print_colored(f"  {i + 1}) {description}", Colors.CYAN)

        while True:
            try:
                selection = input(f"\nSelect LLM (1-{len(variants)}): ").strip()
                selection_num = int(selection)
                if 1 <= selection_num <= len(variants):
                    return variants[selection_num - 1].get('name')
                else:
                    print("Invalid selection. Please try again.")
            except ValueError:
                print("Please enter a valid number.")

    def find_download_url(self, frameworks, selected_framework, selected_scope, selected_llm):
        framework = next((f for f in frameworks if f.get('name') == selected_framework), None)
        if not framework:
            Colors.print_colored(f"ERROR: Framework '{selected_framework}' not found", Colors.RED)
            sys.exit(1)

        scope = next((s for s in framework.get('scopes', []) if s.get('name') == selected_scope), None)
        if not scope:
            Colors.print_colored(f"ERROR: Scope '{selected_scope}' not found for {selected_framework}", Colors.RED)
            sys.exit(1)

        variant = next((v for v in scope.get('variants', []) if v.get('name') == selected_llm), None)
        if not variant:
            Colors.print_colored(f"ERROR: LLM variant '{selected_llm}' not found for {selected_framework}/{selected_scope}", Colors.RED)
            sys.exit(1)

        return variant.get('download_url')

    def download_package(self, framework, scope, llm, download_url):
        target_dir = Path(self.initai_dir) / f"{framework}-{scope}-{llm}"
        print()
        self.write_verbose_message(f"Downloading {framework} ({scope}) package for {llm}...", Colors.YELLOW)

        target_dir.mkdir(parents=True, exist_ok=True)

        try:
            full_download_url = f"{self.base_url}{download_url}"
            zip_file = target_dir / "package.zip"

            self.write_verbose_message(f"  Downloading from {full_download_url}...", Colors.CYAN)
            urllib.request.urlretrieve(full_download_url, zip_file)

            self.write_verbose_message("  Extracting package...", Colors.CYAN)
            with zipfile.ZipFile(zip_file, 'r') as zip_ref:
                zip_ref.extractall(target_dir)

            # Remove the zip file
            zip_file.unlink()

            Colors.print_colored(f"Package downloaded and extracted to: {target_dir}", Colors.GREEN)
            return target_dir
        except Exception as e:
            Colors.print_colored(f"ERROR: Failed to download package: {e}", Colors.RED)
            raise

    def save_configuration(self, framework, scope, llm, target_dir, launch_claude=None):
        download_url = f"/init/shared/{framework}/{scope}"
        if llm != "universal":
            download_url += f"/{llm}"

        config = {
            "base_url": self.base_url,
            "framework": framework,
            "scope": scope,
            "llm": llm,
            "description": f"{framework} {scope} development for {llm}",
            "download_url": download_url,
            "target_dir": str(target_dir),
            "last_updated": datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"),
            "script_version": self.current_version
        }

        # Add launch_claude preference if provided
        if launch_claude is not None:
            config["launch_claude"] = launch_claude

        with open(self.config_file, 'w') as f:
            json.dump(config, f, indent=2)
        Colors.print_colored(f"Configuration saved to {self.config_file}", Colors.GREEN)

    def generate_llm_instructions(self, preferred_llm, framework, scope, target_dir):
        llm_file = ""
        content = ""

        timestamp = datetime.now().strftime("%Y-%m-%d")

        if preferred_llm == "claude":
            llm_file = "CLAUDE.md"
            content = f"""# Claude Instructions for {framework} ({scope})

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
- Framework: {framework}
- Scope: {scope}
- LLM specialization: {preferred_llm}
- Reference files: {target_dir} (READ ONLY - do not modify or generate files here)

## Instructions
Read the framework guidelines from {target_dir} at session start, but work in the main project directory:

- **Read** framework configuration from {target_dir} (reference only)
- **Apply** coding standards and patterns to your main project files
- **Use** provided templates as reference for new files in main directory
- **Load PROJECT.md** to understand current project state
- **Work in the main project directory** - NOT in the {target_dir} folder

## File Structure
- CLAUDE.md - Initialization instructions (static - don't modify)
- PROJECT.md - Your working context (dynamic - update regularly)
- {target_dir}/ - **READ-ONLY** framework reference files and templates
- Your actual project files - **Work here** (main directory and subdirectories)

## Key Guidelines
- Always use bullet format for responses
- Prioritize developer productivity
- Follow the framework's best practices from {target_dir} reference
- Maintain consistency across the project
- **Save all project decisions and context to PROJECT.md**
- **IMPORTANT: Generate project files in main directory, NOT in {target_dir}**

---
Generated by initai.dev on {timestamp}"""

        elif preferred_llm == "gemini":
            llm_file = "GEMINI.md"
            content = f"""# Gemini Instructions for {framework} ({scope})

## Communication Style
- Use bullet points for all responses
- Provide detailed explanations when needed
- Focus on research and analysis

## Project Setup
- Framework: {framework}
- Scope: {scope}
- LLM specialization: {preferred_llm}
- Reference files: {target_dir} (READ ONLY - do not modify or generate files here)

## Instructions
Read the framework guidelines from {target_dir} at session start, but work in the main project directory:

- **Read** framework configuration from {target_dir} (reference only)
- **Apply** coding standards and patterns to your main project files
- **Use** provided templates as reference for new files in main directory
- **Work in the main project directory** - NOT in the {target_dir} folder

## Key Guidelines
- Always use bullet format for responses
- Leverage analytical capabilities for complex problems
- Follow the framework's best practices from {target_dir} reference
- Provide comprehensive documentation
- **IMPORTANT: Generate project files in main directory, NOT in {target_dir}**

---
Generated by initai.dev on {timestamp}"""

        elif preferred_llm == "universal":
            llm_file = "LLM_INSTRUCTIONS.md"
            content = f"""# LLM Instructions for {framework} ({scope})

## Communication Style
- Use bullet points for all responses
- Adapt to the specific LLM being used
- Focus on clear, actionable guidance

## Project Setup
- Framework: {framework}
- Scope: {scope}
- LLM specialization: {preferred_llm}
- Initialization files: {target_dir}

## Instructions
Please read and follow the initialization files in {target_dir} on every session start:

- Load the framework configuration
- Apply the coding standards and patterns
- Use the provided templates and conventions

## Key Guidelines
- Always use bullet format for responses
- Work with any LLM provider
- Follow the framework's best practices
- Maintain consistency across the project

---
Generated by initai.dev on {timestamp}"""

        if content:
            # Check if LLM instruction file already exists
            llm_path = Path(llm_file)
            if llm_path.exists():
                print()
                overwrite = input(f"{llm_file} already exists. Overwrite? (y/n): ").strip()
                if overwrite.lower() not in ['y', 'yes']:
                    Colors.print_colored(f"Keeping existing {llm_file}", Colors.CYAN)
                    print()
                    Colors.print_colored("WARNING: Make sure your {llm_file} contains the instruction:", Colors.YELLOW)
                    Colors.print_colored(f'"Please read and follow the initialization files in {target_dir} on every session start"', Colors.BLUE)
                    print()
                    return

            try:
                with open(llm_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                Colors.print_colored(f"Created {llm_file} with project instructions", Colors.GREEN)
            except Exception as e:
                Colors.print_colored(f"WARNING: Could not create {llm_file}: {e}", Colors.YELLOW)

    def show_package_instructions(self, target_dir):
        init_file = target_dir / "init.md"
        if init_file.exists():
            print()
            Colors.print_colored("=== Package Instructions ===", Colors.BLUE)
            try:
                with open(init_file, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    for line in lines[:10]:  # Show first 10 lines
                        Colors.print_colored(line.rstrip(), Colors.WHITE)

                    if len(lines) > 10:
                        Colors.print_colored(f"... (see {init_file} for full instructions)", Colors.YELLOW)
            except Exception as e:
                Colors.print_colored(f"Could not read {init_file}: {e}", Colors.YELLOW)

            Colors.print_colored("=============================", Colors.BLUE)

    def clear_initai_folder(self):
        Colors.print_colored("Cleaning up initai folder...", Colors.YELLOW)

        initai_path = Path(self.initai_dir)
        if initai_path.exists():
            try:
                shutil.rmtree(initai_path)
                Colors.print_colored(f"Removed initai folder: {initai_path}", Colors.GREEN)
            except Exception as e:
                Colors.print_colored(f"WARNING: Could not remove initai folder: {e}", Colors.YELLOW)
        else:
            Colors.print_colored("No initai folder found to remove", Colors.CYAN)

        # Also remove LLM instruction files
        llm_files = ["CLAUDE.md", "GEMINI.md", "LLM_INSTRUCTIONS.md"]
        for file in llm_files:
            file_path = Path(file)
            if file_path.exists():
                try:
                    file_path.unlink()
                    Colors.print_colored(f"Removed LLM instruction file: {file}", Colors.GREEN)
                except Exception as e:
                    Colors.print_colored(f"WARNING: Could not remove {file}: {e}", Colors.YELLOW)

    def clear_all_local_files(self):
        Colors.print_colored("Cleaning up all local initai files...", Colors.YELLOW)

        # Remove initai folder and LLM files
        self.clear_initai_folder()

        # Remove local configuration
        config_path = Path(self.config_file)
        if config_path.exists():
            try:
                config_path.unlink()
                Colors.print_colored(f"Removed local configuration: {config_path}", Colors.GREEN)
            except Exception as e:
                Colors.print_colored(f"WARNING: Could not remove {self.config_file}: {e}", Colors.YELLOW)
        else:
            Colors.print_colored("No local configuration found to remove", Colors.CYAN)

        print()
        Colors.print_colored("Local cleanup complete!", Colors.GREEN)
        Colors.print_colored(f"Note: Global user preferences in {self.global_config_file} are preserved", Colors.BLUE)

    def get_current_configuration(self):
        config_path = Path(self.config_file)
        if config_path.exists():
            try:
                with open(config_path, 'r') as f:
                    return json.load(f)
            except Exception as e:
                Colors.print_colored(f"WARNING: Could not read config: {e}", Colors.YELLOW)
                return None
        return None

    def run(self):
        self.write_header()

        # Handle clear operations
        if self.clear:
            self.clear_initai_folder()
            return

        if self.clear_all:
            self.clear_all_local_files()
            return

        self.test_dependencies()

        # Always check for script updates
        if self.test_script_update():
            return  # Script was updated, exit current execution

        if not self.test_configuration():
            # New setup - ask for framework, scope, then LLM
            frameworks = self.get_available_packages()

            selected_framework = self.select_framework(frameworks)
            selected_scope = self.select_scope(frameworks, selected_framework)
            selected_llm = self.select_llm(frameworks, selected_framework, selected_scope)
            download_url = self.find_download_url(frameworks, selected_framework, selected_scope, selected_llm)

            print()
            Colors.print_colored(f"Selected: {selected_framework} ({selected_scope}) for {selected_llm}", Colors.BLUE)

            try:
                target_dir = self.download_package(selected_framework, selected_scope, selected_llm, download_url)

                # Generate LLM instructions first (before launching Claude)
                self.generate_llm_instructions(selected_llm, selected_framework, selected_scope, target_dir)
                self.show_package_instructions(target_dir)

                # Ask if user wants to launch Claude (only if Claude was selected)
                launch_claude_preference = None
                if selected_llm == "claude":
                    print()
                    launch_claude = input("Launch Claude? (y/n): ").strip()
                    if launch_claude.lower() in ['y', 'yes']:
                        launch_claude_preference = True
                        try:
                            if shutil.which("claude-code"):
                                Colors.print_colored("Starting Claude Code...", Colors.CYAN)
                                subprocess.run(["claude-code"])
                            elif shutil.which("claude"):
                                Colors.print_colored("Starting Claude CLI...", Colors.CYAN)
                                subprocess.run(["claude"])
                            else:
                                Colors.print_colored("Claude CLI not found. Please install Claude Code CLI:", Colors.YELLOW)
                                Colors.print_colored("https://claude.ai/code", Colors.WHITE)
                        except Exception as e:
                            Colors.print_colored(f"Failed to launch Claude CLI: {e}", Colors.YELLOW)
                            Colors.print_colored("Please visit: https://claude.ai/code", Colors.WHITE)
                    else:
                        launch_claude_preference = False

                self.save_configuration(selected_framework, selected_scope, selected_llm, target_dir, launch_claude_preference)

                print()
                Colors.print_colored("Setup complete!", Colors.GREEN)
                Colors.print_colored(f"Framework files: ./{target_dir}/", Colors.YELLOW)
                Colors.print_colored("LLM instructions: ./CLAUDE.md (or ./GEMINI.md)", Colors.YELLOW)
                Colors.print_colored("Tell your LLM: 'Load the initialization files and follow the project instructions'", Colors.BLUE)
            except Exception as e:
                Colors.print_colored(f"ERROR: Setup failed: {e}", Colors.RED)
                sys.exit(1)
        else:
            # Existing configuration - show package instructions
            config = self.get_current_configuration()
            if config:
                Colors.print_colored(f"Current configuration: {config.get('framework')} ({config.get('scope')}) for {config.get('llm')}", Colors.CYAN)
                Colors.print_colored(f"Target directory: {config.get('target_dir')}", Colors.YELLOW)

                # Show package instructions on every run
                target_dir = Path(config.get('target_dir', ''))
                if target_dir.exists():
                    self.show_package_instructions(target_dir)

                Colors.print_colored("Use --force to reconfigure", Colors.BLUE)


def main():
    parser = argparse.ArgumentParser(description="initai.dev Python installer")
    parser.add_argument("--base-url", default="https://initai.dev", help="Custom base URL")
    parser.add_argument("--force", action="store_true", help="Force reconfiguration")
    parser.add_argument("--update", action="store_true", help="Force check for script updates")
    parser.add_argument("--clear", action="store_true", help="Remove initai folder and downloaded packages")
    parser.add_argument("--clear-all", action="store_true", help="Remove initai folder AND local .initai.json config")
    parser.add_argument("--verbose", action="store_true", help="Show detailed progress messages")
    parser.add_argument("--ignore-ssl-issues", action="store_true", help="Skip SSL certificate verification")
    parser.add_argument("--help-full", action="store_true", help="Show help and exit")

    args = parser.parse_args()

    if args.help_full:
        parser.print_help()
        sys.exit(0)

    try:
        initai = InitAI(
            base_url=args.base_url,
            force=args.force,
            verbose=args.verbose,
            ignore_ssl_issues=args.ignore_ssl_issues,
            update=args.update,
            clear=args.clear,
            clear_all=args.clear_all
        )

        if args.help_full:
            initai.show_help()
            return

        initai.run()
    except KeyboardInterrupt:
        print()
        Colors.print_colored("Operation cancelled by user", Colors.YELLOW)
        sys.exit(1)
    except Exception as e:
        Colors.print_colored(f"ERROR: {e}", Colors.RED)
        sys.exit(1)


if __name__ == "__main__":
    main()