# C# Coding Standards

Comprehensive coding standards for C# development within the Bliss Framework.

## Code Formatting

### Indentation and Spacing
- Use 4 spaces for indentation (no tabs)
- Single space after keywords (`if (`, `for (`, `while (`)
- No trailing whitespace
- Empty line between logical sections

### Braces and Brackets
```csharp
// Correct - Allman style
if (condition)
{
    DoSomething();
}

// Method declarations
public void MethodName()
{
    // Implementation
}
```

## Naming Conventions

### Classes and Methods
- **PascalCase** for classes, methods, properties, and public fields
- **camelCase** for local variables and private fields
- **SCREAMING_SNAKE_CASE** for constants

```csharp
public class UserService
{
    private readonly IUserRepository _userRepository;
    private const int MAX_RETRY_ATTEMPTS = 3;

    public async Task<User> GetUserByIdAsync(int userId)
    {
        var user = await _userRepository.FindByIdAsync(userId);
        return user;
    }
}
```

### Interfaces and Abstract Classes
- Prefix interfaces with `I` (e.g., `IUserService`)
- Use descriptive names that indicate purpose
- Abstract classes should not have prefixes

## File Organization

### Project Structure
```
src/
├── Domain/
│   ├── Entities/
│   ├── ValueObjects/
│   └── Interfaces/
├── Application/
│   ├── Services/
│   ├── DTOs/
│   └── Mappers/
├── Infrastructure/
│   ├── Data/
│   ├── External/
│   └── Configuration/
└── Presentation/
    ├── Controllers/
    ├── Models/
    └── Middleware/
```

### File Naming
- One class per file
- File name matches class name exactly
- Use descriptive, meaningful names
- Avoid abbreviations unless widely understood

## Code Quality

### Method Design
- Keep methods focused on single responsibility
- Limit method parameters (max 3-4 parameters)
- Use meaningful parameter names
- Return early to reduce nesting

```csharp
public bool IsValidEmail(string email)
{
    if (string.IsNullOrWhiteSpace(email))
        return false;

    if (!email.Contains("@"))
        return false;

    return EmailValidator.Validate(email);
}
```

### Error Handling
- Use exceptions for exceptional circumstances
- Create custom exception types when needed
- Always include meaningful error messages
- Log errors appropriately

### Comments and Documentation
- Use XML documentation for public APIs
- Comment complex business logic
- Avoid obvious comments
- Keep comments up-to-date with code changes

```csharp
/// <summary>
/// Calculates the compound interest for a given principal amount.
/// </summary>
/// <param name="principal">The initial amount of money</param>
/// <param name="rate">The annual interest rate (as a decimal)</param>
/// <param name="years">The number of years to compound</param>
/// <returns>The final amount after compound interest</returns>
public decimal CalculateCompoundInterest(decimal principal, decimal rate, int years)
{
    return principal * (decimal)Math.Pow((double)(1 + rate), years);
}
```

These standards ensure consistency across all C# projects and improve code maintainability and team collaboration.