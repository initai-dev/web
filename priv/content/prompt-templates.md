# Prompt Templates

Create reusable prompt templates for consistent LLM interactions.

## Basic Template Structure

A prompt template consists of:
1. **System Message**: Sets the AI's role and behavior
2. **User Message Template**: The actual prompt with variables
3. **Variables**: Placeholders that can be filled in

## Example Templates

### Code Review Template

**System Message:**
```
You are an expert code reviewer. Provide constructive feedback on code quality, security, and best practices.
```

**User Message:**
```
Please review the following {{language}} code:

{{code}}

Focus on:
- Code quality and readability
- Security vulnerabilities
- Performance improvements
- Best practices
```

### Documentation Generator

**System Message:**
```
You are a technical writer who creates clear, comprehensive documentation.
```

**User Message:**
```
Generate documentation for the following {{type}}:

{{content}}

Include:
- Overview
- Usage examples
- Parameter descriptions
- Return values
```

## Template Variables

Common variables include:
- `{{language}}`: Programming language
- `{{code}}`: Code snippet
- `{{context}}`: Additional context
- `{{requirements}}`: Specific requirements