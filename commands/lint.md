---
name: lint
description: Run linting and code quality checks for the current project. Use before committing to catch style issues, errors, and code smells.
---

# Lint Command

Run linting and code quality checks.

## Quick Commands

**Python**: `ruff check .`
**JavaScript/TypeScript**: `npm run lint` or `eslint .`
**C#**: `dotnet format --verify-no-changes`
**Flutter/Dart**: `flutter analyze`

## Auto-fix

**Python**: `ruff check --fix .`
**JavaScript**: `eslint --fix .`
**Prettier**: `prettier --write .`

## Notes

- Run before committing
- Fix errors before warnings
- Report results with severity levels

See **git-workflow** skill for complete linting configuration and CI/CD integration.
