# Tenant System

Multi-tenant package management architecture for organizing and distributing LLM initialization frameworks.

## Overview

The InitAI.dev platform uses a **tenant-based architecture** that allows for organized distribution of frameworks while supporting future expansion to private, organization-specific package collections.

## Current Architecture

### Shared Tenant
Currently, the system operates with a single **"shared"** tenant that hosts all public frameworks:

```
/init/shared/
├── blissframework/
│   ├── backend/
│   │   ├── universal/
│   │   ├── claude/
│   │   └── gemini/
│   └── frontend/
│       ├── universal/
│       ├── claude/
│       └── gemini/
```

### API Structure

All API endpoints follow the tenant-first pattern:

```bash
# Base pattern
GET /init/{tenant}/list
GET /init/{tenant}/{framework}/{scope}
GET /init/{tenant}/{framework}/{scope}/{llm}

# Current endpoints (shared tenant)
GET /init/shared/list                              # Available frameworks
GET /init/shared/blissframework/backend            # Universal backend package
GET /init/shared/blissframework/backend/claude     # Claude-optimized backend
GET /init/shared/blissframework/frontend/gemini    # Gemini-optimized frontend
```

## API Response Format

### Framework Listing
```json
{
  "tenant": "shared",
  "frameworks": [
    {
      "name": "blissframework",
      "description": "Enhanced development productivity framework",
      "scopes": [
        {
          "name": "backend",
          "description": "Server-side development, APIs, databases",
          "variants": [
            {
              "name": "universal",
              "description": "Works with any LLM",
              "download_url": "/init/shared/blissframework/backend"
            },
            {
              "name": "claude",
              "description": "Optimized for Claude AI",
              "download_url": "/init/shared/blissframework/backend/claude"
            },
            {
              "name": "gemini",
              "description": "Optimized for Gemini AI",
              "download_url": "/init/shared/blissframework/backend/gemini"
            }
          ]
        },
        {
          "name": "frontend",
          "description": "Client-side development, UI/UX",
          "variants": [
            {
              "name": "universal",
              "description": "Works with any LLM",
              "download_url": "/init/shared/blissframework/frontend"
            },
            {
              "name": "claude",
              "description": "Optimized for Claude AI",
              "download_url": "/init/shared/blissframework/frontend/claude"
            },
            {
              "name": "gemini",
              "description": "Optimized for Gemini AI",
              "download_url": "/init/shared/blissframework/frontend/gemini"
            }
          ]
        }
      ]
    }
  ]
}
```

## Future: Organization Tenants

### Planned Architecture
The system is designed to support organization-specific tenants:

```
/init/{organization}/
├── private-framework-1/
├── private-framework-2/
└── customized-bliss/
```

### Use Cases
- **Enterprise Frameworks** - Companies can host internal, proprietary frameworks
- **Team-Specific Configurations** - Customized versions of public frameworks
- **Industry Standards** - Industry-specific framework collections
- **Regional Compliance** - Frameworks tailored for specific regulatory requirements

### Access Control
Future organization tenants will include:
- **Authentication** - API key or OAuth-based access
- **Permission Management** - Fine-grained access controls
- **Audit Logging** - Track package downloads and usage
- **Version Control** - Separate versioning for organization packages

## Technical Implementation

### File System Organization
```
priv/packages/
├── shared/                    # Public tenant
│   └── blissframework/
└── organizations/             # Future: Private tenants
    ├── company-a/
    ├── company-b/
    └── industry-consortium/
```

### Route Handling
The Phoenix router handles tenant-based routing:

```elixir
# Current implementation
get "/init/:tenant/list", InitController, :list_frameworks
get "/init/:tenant/:framework/:scope", InitController, :download_package
get "/init/:tenant/:framework/:scope/:llm", InitController, :download_package

# Tenant validation ensures only "shared" is currently accessible
```

### Dynamic Package Discovery
The system automatically discovers available packages within each tenant:

1. **Scan directories** - Detect framework and scope combinations
2. **Load manifests** - Read package metadata from `manifest.json` files
3. **Build hierarchy** - Create the three-tier structure dynamically
4. **Cache results** - Optimize repeated API calls

## Installation Script Integration

### Tenant Selection
Currently, installation scripts default to the shared tenant:

```bash
# Bash script
TENANT="shared"
API_BASE="https://initai.dev/init/$TENANT"

# PowerShell script
$Tenant = "shared"
$ApiBase = "https://initai.dev/init/$Tenant"
```

### Future Enhancement
When organization tenants are available, scripts will include tenant selection:

```bash
# Interactive tenant selection
echo "Select tenant:"
echo "  1) shared - Public frameworks"
echo "  2) organization - Private frameworks"
read -p "Choice: " tenant_choice
```

## Benefits

### Current Benefits
- **Clean API Structure** - Consistent, predictable endpoints
- **Namespace Isolation** - Prevents package name conflicts
- **Future Scalability** - Architecture ready for expansion

### Future Benefits
- **Enterprise Adoption** - Private framework hosting
- **Customization** - Organization-specific modifications
- **Compliance** - Industry-specific requirements
- **Access Control** - Secure, controlled distribution

## Migration Path

When organization tenants become available:

1. **Backward Compatibility** - Shared tenant remains default
2. **Gradual Migration** - Organizations can opt-in to private tenants
3. **API Consistency** - Same endpoints, different tenant values
4. **Tool Updates** - Installation scripts will support tenant selection

The tenant system provides a robust foundation for both current public distribution and future enterprise expansion while maintaining simplicity for individual developers.