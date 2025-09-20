# Model Configuration

This section covers how to configure different LLM models for your applications.

## Supported Models

### OpenAI Models
- **GPT-4**: Most capable model, best for complex reasoning
- **GPT-3.5 Turbo**: Fast and efficient for most tasks
- **GPT-4 Turbo**: Latest model with improved capabilities

### Anthropic Models
- **Claude 3 Opus**: Most powerful model for complex tasks
- **Claude 3 Sonnet**: Balanced performance and speed
- **Claude 3 Haiku**: Fast responses for simpler tasks

## Configuration Parameters

### Temperature
Controls randomness in responses:
- `0.0`: Deterministic output
- `0.5`: Balanced creativity
- `1.0`: Maximum creativity

### Max Tokens
Maximum length of the response (typically 1000-4000 tokens).

### Top P
Controls diversity via nucleus sampling (recommended: 0.1-0.9).

## Example Configuration

```json
{
  "model": "gpt-4",
  "temperature": 0.7,
  "max_tokens": 2000,
  "top_p": 0.9
}
```