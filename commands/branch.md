---
name: branch
description: Create a git branch following GitFlow naming conventions. Use when starting new work that requires a feature, bugfix, hotfix, or release branch.
argument-hint: "[type/description]"
disable-model-invocation: true
---

# Branch Command

Create a git branch following naming conventions.

## Quick Steps

1. Determine base branch (usually `develop`)
2. Pull latest: `git pull`
3. Create branch: `git checkout -b type/epic-X-story-Y-description`

## Branch Format

```
type/epic-X-story-Y.Z-brief-description
```

**Types**: `feature/`, `bugfix/`, `hotfix/`, `refactor/`, `docs/`, `test/`

**Examples**:
- `feature/epic-12-story-45.1-user-authentication`
- `bugfix/story-67-fix-login-error`

## Notes

- Feature/bugfix → target `develop`
- Hotfix → target `main`
- Use lowercase kebab-case

See **git-workflow** skill for complete branch naming conventions.
