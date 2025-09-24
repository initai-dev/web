#!/usr/bin/env python3
"""
InitAI.dev - Python Bootstrap Installer
Downloads and sets up the main InitAI script with PATH management
"""

import argparse
import os
import platform
import subprocess
import sys
from pathlib import Path
import urllib.request
import urllib.error


class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GRAY = '\033[90m'
    WHITE = '\033[97m'
    RESET = '\033[0m'

    @staticmethod
    def print_colored(message, color):
        print(f"{color}{message}{Colors.RESET}")


def write_header():
    Colors.print_colored("initai.dev Bootstrap Installer", Colors.CYAN)
    Colors.print_colored("Setting up LLM Framework Manager...", Colors.GRAY)
    print()


def write_verbose_message(message, color=None, verbose=False):
    if verbose:
        if color:
            Colors.print_colored(message, color)
        else:
            print(message)


def get_app_data_path():
    """Get platform-specific app data path"""
    if platform.system() == "Windows":
        return os.path.join(os.environ.get("LOCALAPPDATA", ""), "initai")
    else:
        return os.path.expanduser("~/.local/share/initai")


def test_path_contains(path_to_check):
    """Check if PATH contains the given directory"""
    current_path = os.environ.get("PATH", "")
    if not current_path:
        return False

    path_entries = current_path.split(os.pathsep)
    return any(entry.strip() == path_to_check.strip() for entry in path_entries)


def add_to_user_path(path_to_add, verbose=False):
    """Add directory to user PATH"""
    if test_path_contains(path_to_add):
        write_verbose_message(f"PATH already contains: {path_to_add}", Colors.GREEN, verbose)
        return True

    try:
        if platform.system() == "Windows":
            # Windows: Update user environment variable
            import winreg
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment", 0, winreg.KEY_ALL_ACCESS)
            try:
                current_path, _ = winreg.QueryValueEx(key, "PATH")
            except FileNotFoundError:
                current_path = ""

            new_path = f"{current_path};{path_to_add}" if current_path else path_to_add
            winreg.SetValueEx(key, "PATH", 0, winreg.REG_EXPAND_SZ, new_path)
            winreg.CloseKey(key)
        else:
            # Unix-like: Add to .bashrc or .zshrc
            shell_rc = None
            if os.environ.get("SHELL", "").endswith("zsh"):
                shell_rc = os.path.expanduser("~/.zshrc")
            else:
                shell_rc = os.path.expanduser("~/.bashrc")

            export_line = f'export PATH="$PATH:{path_to_add}"'

            if os.path.exists(shell_rc):
                with open(shell_rc, 'r') as f:
                    content = f.read()
                if export_line not in content:
                    with open(shell_rc, 'a') as f:
                        f.write(f"\n# Added by initai.dev\n{export_line}\n")
            else:
                with open(shell_rc, 'w') as f:
                    f.write(f"# Added by initai.dev\n{export_line}\n")

        Colors.print_colored(f"[OK] Added to PATH: {path_to_add}", Colors.GREEN)
        Colors.print_colored("  PATH changes will take effect in new terminal sessions", Colors.GRAY)
        return True

    except Exception as e:
        Colors.print_colored(f"ERROR: Failed to add to PATH: {e}", Colors.RED)
        return False


def install_initai_script(base_url, app_data_path, verbose=False):
    """Download and install the main initai script"""
    try:
        # Create app data directory if it doesn't exist
        app_data_path.mkdir(parents=True, exist_ok=True)
        Colors.print_colored(f"[OK] Created directory: {app_data_path}", Colors.GREEN)

        # Download main script
        main_script_url = f"{base_url}/initai.py"
        main_script_path = app_data_path / "initai.py"

        Colors.print_colored("Downloading initai.dev script...", Colors.BLUE)
        write_verbose_message(f"From: {main_script_url}", Colors.GRAY, verbose)
        write_verbose_message(f"To: {main_script_path}", Colors.GRAY, verbose)

        urllib.request.urlretrieve(main_script_url, main_script_path)

        # Make executable on Unix-like systems
        if platform.system() != "Windows":
            os.chmod(main_script_path, 0o755)

        Colors.print_colored("[OK] Downloaded initai.dev script", Colors.GREEN)
        return True

    except Exception as e:
        Colors.print_colored(f"ERROR: Failed to download initai.dev script: {e}", Colors.RED)
        return False


def prompt_add_to_path(app_data_path):
    """Prompt user to add initai to PATH"""
    if test_path_contains(str(app_data_path)):
        Colors.print_colored("[OK] initai.dev is already in your PATH", Colors.GREEN)
        return "already_in_path"

    print()
    Colors.print_colored("Add initai.dev to your PATH for global access?", Colors.BLUE)
    Colors.print_colored("This will add the following directory to your PATH:", Colors.GRAY)
    Colors.print_colored(f"  {app_data_path}", Colors.YELLOW)
    print()
    Colors.print_colored("Benefits:", Colors.GRAY)
    Colors.print_colored("  * Run 'initai' from any directory", Colors.GRAY)
    Colors.print_colored("  * Access initai.dev tools globally", Colors.GRAY)
    Colors.print_colored("  * Consistent development environment", Colors.GRAY)
    print()

    response = input("Add to PATH? (Y/n): ").strip()
    if response == "" or response.lower() == "y":
        if add_to_user_path(str(app_data_path)):
            return "added_to_path"
        else:
            return "failed_to_add"
    else:
        Colors.print_colored("Skipped adding to PATH", Colors.GRAY)
        main_script_path = app_data_path / "initai.py"
        Colors.print_colored(f"You can run initai.dev with: python {main_script_path}", Colors.YELLOW)
        return "skipped"


def test_initai_installed(app_data_path):
    """Check if initai is already installed"""
    main_script_path = app_data_path / "initai.py"
    return main_script_path.exists()


def main():
    parser = argparse.ArgumentParser(description="InitAI.dev Bootstrap Installer")
    parser.add_argument("--base-url", default="https://initai.dev", help="Custom base URL")
    parser.add_argument("--force", action="store_true", help="Force reinstallation")
    parser.add_argument("--verbose", action="store_true", help="Show verbose output")

    args, remaining_args = parser.parse_known_args()

    write_header()

    app_data_path = Path(get_app_data_path())
    main_script_path = app_data_path / "initai.py"

    # Check if already installed and not forced
    if test_initai_installed(app_data_path) and not args.force:
        Colors.print_colored(f"initai.dev is already installed at: {main_script_path}", Colors.YELLOW)

        # Still check/offer PATH setup
        if not test_path_contains(str(app_data_path)):
            path_result = prompt_add_to_path(app_data_path)
            if path_result == "added_to_path":
                Colors.print_colored("(Restart your terminal for PATH changes to take effect)", Colors.GRAY)
        else:
            Colors.print_colored("[OK] initai.dev is in your PATH", Colors.GREEN)

        print()
        Colors.print_colored("Running initai.dev...", Colors.BLUE)

        # Execute the main script with any remaining arguments
        try:
            cmd = [sys.executable, str(main_script_path), "--base-url", args.base_url] + remaining_args
            subprocess.run(cmd)
        except Exception as e:
            Colors.print_colored(f"ERROR: Failed to run initai.dev: {e}", Colors.RED)
            sys.exit(1)
        return

    # Install the main script
    if not install_initai_script(args.base_url, app_data_path, args.verbose):
        sys.exit(1)

    # Prompt for PATH setup
    path_result = prompt_add_to_path(app_data_path)

    print()
    Colors.print_colored("[OK] initai.dev installation complete!", Colors.GREEN)

    if path_result == "already_in_path":
        Colors.print_colored("You can now run 'initai' from any directory", Colors.CYAN)
    elif path_result == "added_to_path":
        Colors.print_colored("You can now run 'initai' from any directory", Colors.CYAN)
        Colors.print_colored("(Restart your terminal for PATH changes to take effect)", Colors.GRAY)
    elif path_result == "skipped":
        Colors.print_colored(f"To run initai.dev, use: python {main_script_path}", Colors.YELLOW)
    elif path_result == "failed_to_add":
        Colors.print_colored(f"To run initai.dev, use: python {main_script_path}", Colors.YELLOW)
        Colors.print_colored(f"PATH setup failed - you can add manually: {app_data_path}", Colors.GRAY)

    print()
    Colors.print_colored("Starting initai.dev for initial setup...", Colors.BLUE)

    # Run the main script for initial configuration
    try:
        cmd = [sys.executable, str(main_script_path), "--base-url", args.base_url]
        subprocess.run(cmd)
    except Exception as e:
        Colors.print_colored(f"ERROR: Failed to run initial setup: {e}", Colors.RED)
        sys.exit(1)


if __name__ == "__main__":
    main()