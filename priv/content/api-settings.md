# API Settings

Configure API endpoints and authentication for various LLM providers.

## Provider Configuration

### OpenAI
```json
{
  "provider": "openai",
  "api_key": "your-api-key",
  "base_url": "https://api.openai.com/v1",
  "organization": "your-org-id"
}
```

### Anthropic
```json
{
  "provider": "anthropic",
  "api_key": "your-api-key",
  "base_url": "https://api.anthropic.com"
}
```

### Azure OpenAI
```json
{
  "provider": "azure",
  "api_key": "your-api-key",
  "base_url": "https://your-resource.openai.azure.com",
  "api_version": "2023-07-01-preview",
  "deployment_name": "your-deployment"
}
```

## Rate Limiting

Configure rate limits to avoid hitting API quotas:

```json
{
  "rate_limit": {
    "requests_per_minute": 60,
    "tokens_per_minute": 40000,
    "concurrent_requests": 5
  }
}
```

## Error Handling

Set up retry and fallback strategies:

```json
{
  "error_handling": {
    "max_retries": 3,
    "backoff_factor": 2,
    "fallback_model": "gpt-3.5-turbo",
    "timeout_seconds": 30
  }
}
```

## Environment Variables

Use environment variables for sensitive data:
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `AZURE_OPENAI_KEY`
- `AZURE_OPENAI_ENDPOINT`