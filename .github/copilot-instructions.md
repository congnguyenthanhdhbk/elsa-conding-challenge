# Copilot Instructions for elsa-conding-challenge

## Project Overview
This is the **elsa-conding-challenge** repository - currently in initial setup phase.

## Development Setup
<!-- TODO: Add setup instructions once project structure is established -->
- Clone the repository
- Install dependencies (to be documented)
- Run initial setup commands (to be documented)

## Architecture & Structure
This project follows **Domain-Driven Design (DDD)** principles:

### DDD Layers
- **Domain Layer** (`domain/`) - Core business logic, entities, value objects, domain events
  - Keep domain models pure - no infrastructure dependencies
  - Use aggregates to maintain consistency boundaries
  - Define domain services for operations that don't naturally belong to entities
  
- **Application Layer** (`application/`) - Use cases, application services, DTOs
  - Orchestrate domain operations
  - Handle transaction boundaries
  - Map between domain models and DTOs

- **Infrastructure Layer** (`infrastructure/`) - External concerns (DB, APIs, messaging)
  - Implement repository interfaces defined in domain
  - Database adapters, external API clients
  - Framework-specific implementations

- **Presentation Layer** (`presentation/` or `api/`) - Controllers, REST endpoints, GraphQL resolvers
  - Thin layer - delegate to application services
  - Handle HTTP concerns only

### Key DDD Practices
- Ubiquitous language: Use domain terminology consistently across code and conversations
- Bounded contexts: Clearly separate different business domains
- Aggregates: Ensure data consistency within aggregate boundaries only
- Repository pattern: Abstract data persistence behind interfaces
- Domain events: Use for cross-aggregate communication

## Development Workflow
<!-- TODO: Document build, test, and deployment processes -->
### Build Commands
```bash
# To be added
```

### Testing
```bash
# To be added
```

### Running Locally
```bash
# To be added
```

## Code Conventions
<!-- TODO: Add project-specific patterns and conventions as they emerge -->
- Coding standards to be established
- Naming conventions to be defined
- Code organization patterns to be documented

## Key Integration Points
<!-- TODO: Document external dependencies and APIs -->
- External services to be listed
- API contracts to be documented

## Important Notes
- This file should be updated as the project structure develops
- Add specific examples from the codebase when patterns emerge
- Document non-obvious workflows and architectural decisions
- Keep instructions concise and actionable

---
*Last updated: November 16, 2025*
*This file will be populated with specific guidance as the codebase evolves*
