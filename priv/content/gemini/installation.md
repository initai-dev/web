# Gemini Installation

Complete guide to installing and setting up Google Gemini for your development workflow.

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
wget https://releases.initai.dev/gemini-cli/latest/gemini-linux-amd64
chmod +x gemini-linux-amd64
sudo mv gemini-linux-amd64 /usr/local/bin/gemini

# Windows
# Stáhněte gemini-windows-amd64.exe z releases
```

### 2. Konfigurace API klíče
```bash
gemini configure --api-key YOUR_GOOGLE_API_KEY
```

### 3. Verifikace instalace
```bash
gemini --version
gemini test-connection
```

## Requirements

- **Operating System**: Linux, macOS, Windows 10+
- **RAM**: Minimum 4GB (recommended 8GB+ for multimodal features)
- **Disk**: 1GB free space (including vision models cache)
- **API key**: Valid Google AI API key

## Gemini Specific Settings

### Vision capabilities
```bash
# Aktivace image/video processing
gemini configure --enable-vision

# Stažení vision models
gemini models download vision-pro
```

### Multimodal features
```bash
# Konfigurace multimodal capabilities
gemini configure --multimodal

# Nastavení supported formátů
gemini formats configure --images --video --documents
```

## Next Steps

After successful installation you can:

1. **[Nastavit Bliss Framework](/gemini/blissframework)** - Pro streamlined development
2. **Prozkoumět multimodal features** - Vision, audio, document processing
3. **Nakonfigurovat code generation** - Optimalizováno pro development

## Troubleshooting

### Common Issues

**Vision models se nepodařilo stáhnout**
```bash
# Ruční stažení models
gemini models download --force --model vision-pro
```

**Multimodal features nefungují**
- Ověřte že máte dostatečný Google AI quota
- Zkontrolujte network připojení
- Restartujte gemini daemon: `gemini daemon restart`

**Performance issues s velkými soubory**
```bash
# Optimalizace pro velké soubory
gemini configure --batch-size 5 --memory-limit 8GB
```