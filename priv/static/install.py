#!/usr/bin/env python3
# initai.dev - LLM Initialization Script (Python)
# Usage: curl -sSL https://initai.dev/install.py | python3

import os
import urllib.request
import sys
from pathlib import Path

def download_file(url, filepath):
    try:
        urllib.request.urlretrieve(url, filepath)
        return True
    except Exception as e:
        print(f"  ✗ Failed to download: {e}")
        return False

def main():
    print("🚀 Initializing LLM environment...")

    # Create initai directory
    initai_dir = Path.home() / ".initai"
    initai_dir.mkdir(exist_ok=True)

    print("📦 Downloading configuration templates...")

    configs = [
        ("Claude Bliss Framework",
         "https://initai.dev/claude/bliss/init-script.txt",
         "claude-bliss.txt"),
        ("Gemini Bliss Framework",
         "https://initai.dev/gemini/bliss/init-script.txt",
         "gemini-bliss.txt")
    ]

    for name, url, filename in configs:
        print(f"  → {name}")
        filepath = initai_dir / filename
        download_file(url, filepath)

    print()
    print("✅ Installation complete!")
    print()
    print("🎯 Available configurations:")
    for _, _, filename in configs:
        print(f"   {initai_dir / filename}")
    print()
    print("📖 Visit https://initai.dev for documentation and usage examples.")

if __name__ == "__main__":
    main()