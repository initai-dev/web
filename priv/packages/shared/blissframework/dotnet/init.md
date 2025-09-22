# Bliss Framework - .NET Universal

Universal .NET development framework optimized for productivity with any LLM.

## Project Structure

```
├── Controllers/          # API controllers and MVC controllers
├── Services/            # Business logic and application services
├── Models/              # Data models and DTOs
├── Data/               # Entity Framework contexts and configurations
├── Extensions/         # Extension methods and utilities
├── Middleware/         # Custom middleware components
└── Configuration/      # App configuration and settings
```

## Key Features

- **Dependency Injection** - Built-in DI container configuration
- **Entity Framework** - Database-first and code-first approaches
- **Minimal APIs** - Modern, lightweight API endpoints
- **Configuration Management** - Environment-based settings
- **Logging & Monitoring** - Structured logging with Serilog
- **Authentication & Authorization** - JWT and Identity integration

## Getting Started

1. **Setup Dependencies**
   ```bash
   dotnet add package Microsoft.EntityFrameworkCore
   dotnet add package Serilog.AspNetCore
   dotnet add package AutoMapper
   ```

2. **Configure Services**
   ```csharp
   builder.Services.AddDbContext<AppDbContext>();
   builder.Services.AddAutoMapper(typeof(Program));
   builder.Services.AddScoped<IUserService, UserService>();
   ```

3. **Create Your First Controller**
   ```csharp
   [ApiController]
   [Route("api/[controller]")]
   public class UsersController : ControllerBase
   {
       // Implementation
   }
   ```

## Best Practices

- Use dependency injection for all services
- Implement proper error handling and logging
- Follow RESTful API conventions
- Use DTOs for data transfer
- Implement proper validation
- Write unit tests for business logic

## Templates Available

- **Controller Template** - Standard API controller structure
- **Service Template** - Business logic service pattern
- **Model Template** - Entity and DTO definitions