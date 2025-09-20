# Claude Installation

Complete guide to installing and setting up Claude for your development workflow.

## Quick Installation

The easiest way is to use our automatic installation script:

### Linux / macOS
```bash
curl -sSL https://initai.dev/install.sh | bash
```

### Windows PowerShell
```powershell
iwr -useb https://initai.dev/install.ps1 | iex
```

### Python (cross-platform)
```bash
curl -sSL https://initai.dev/install.py | python3
```

## Manual Installation

If you prefer manual control over the process:

### 1. Stažení CLI
```bash
# Linux/macOS
wget https://releases.initai.dev/claude-cli/latest/claude-linux-amd64
chmod +x claude-linux-amd64
sudo mv claude-linux-amd64 /usr/local/bin/claude

# Windows
# Stáhněte claude-windows-amd64.exe z releases
```

### 2. Konfigurace API klíče
```bash
claude configure --api-key YOUR_ANTHROPIC_API_KEY
```

### 3. Verifikace instalace
```bash
claude --version
claude test-connection
```

## Requirements

- **Operating System**: Linux, macOS, Windows 10+
- **RAM**: Minimum 4GB (recommended 8GB+)
- **Disk**: 500MB free space
- **API key**: Valid Anthropic API key

## Next Steps

After successful installation you can:

1. **[Nastavit Bliss Framework](/claude/blissframework)** - Pro maximální produktivitu
2. **Prozkoumět příklady** - Praktické ukázky použití
3. **Nakonfigurovat IDE integrace** - VS Code, IntelliJ, atd.

## Troubleshooting

### Common Issues

**Permission denied při instalaci**
```bash
sudo chmod +x /usr/local/bin/claude
```

**API klíč není platný**
- Ověřte klíč na [Anthropic Console](https://console.anthropic.com)
- Zkontrolujte, že máte dostatečný kredit

**Network timeouts**
```bash
# Použijte proxy pokud je potřeba
claude configure --proxy http://proxy.company.com:8080
```