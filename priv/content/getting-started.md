# How initai.dev Works

## 🎯 The Problem We Solve

When working with LLMs (Claude, Gemini, ChatGPT), every project starts from scratch. The model doesn't know:
- Your coding standards
- Your preferred architecture
- Your naming conventions
- Your team's best practices

Result? Inconsistent code, repeated instructions, wasted time.

## 💡 Our Solution

**initai.dev** is a system for instant LLM initialization with your configuration. One command configures your AI model to generate code exactly according to your standards.

## 🚀 How it Works

### 1. Quick Installation

```bash
# Linux/macOS
curl -sSL https://initai.dev/install.sh | bash

# Windows
iwr -useb https://initai.dev/install.ps1 | iex
```

### 2. What Happens

1. **Download configuration** - Script downloads predefined frameworks
2. **Choose your setup** - Claude or Gemini? Bliss framework (for rapid development)?
3. **Local storage** - Configuration saved to `~/.initai/` or your project
4. **Initialization prompt** - Get a special prompt for your LLM

### 3. Usage with LLM

```bash
# Copy initialization prompt
cat ~/.initai/claude-bliss/init-script.txt

# Paste as first message to Claude/Gemini
# Model now knows all your preferences!
```

## 📦 What Frameworks Contain

Each framework defines:

- **Principles** - Philosophy and development approach
- **Architecture** - Preferred patterns (MVC, Clean Architecture, etc.)
- **Conventions** - Naming, file structure
- **Templates** - Ready-made project structures
- **Solutions** - Proven approaches for common problems

## 🎨 Bliss Framework

Our main framework focused on **developer happiness**:

- ✅ **Consistency** - Same code across projects
- ✅ **Speed** - Optimized for rapid iterations
- ✅ **Simplicity** - Minimal boilerplate
- ✅ **Pragmatism** - Real solutions, not academic concepts

## 🔄 Workflow

### First Use
1. Install initai
2. Choose LLM and framework
3. Initialize the model
4. Start working - model knows your standards

### Daily Work
1. Open new LLM session
2. Paste init prompt from `~/.initai/`
3. Model immediately knows how to work
4. Generates consistent code according to your rules

## 🏢 For Teams

- **Shared configuration** - Everyone uses same standards
- **Versioning** - Frameworks can be updated and versioned
- **Onboarding** - New members immediately write code to standards
- **Review** - Easier code review thanks to consistency

## 🛠️ Technical Details

### File Structure

```
~/.initai/
├── .initai.json          # Your configuration
├── claude-bliss/         # Framework files
│   ├── init-script.txt   # Initialization prompt
│   ├── principles.txt    # Framework principles
│   └── ...              # Additional configuration
```

### API Endpoints

- `/manifest.json` - List of available frameworks
- `/[llm]/[framework]/[file]` - Individual configuration files
- `/install.sh|ps1|py` - Installation scripts

## 🚦 Get Started Now

1. **[Claude Installation](/claude/installation)** - Set up Claude with Bliss framework
2. **[Gemini Installation](/gemini/installation)** - Set up Gemini with Bliss framework
3. **[Bliss Framework](/claude/blissframework)** - Details about our framework

## ❓ FAQ

**Is it free?**
Yes, all frameworks are open source and free.

**Do I need to use all rules?**
No, you can pick only the parts you need.

**Can I create custom frameworks?**
Yes, the system is designed for extension.

**Does it work with ChatGPT?**
Principles work universally, but optimized for Claude and Gemini.