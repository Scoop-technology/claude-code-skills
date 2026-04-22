---
name: markdown-board
description: Default agile-board implementation. Stores epics and stories as Markdown files inside the project's docs folder. No external service needed.
---

# Markdown Agile Board

The **markdown** board type is the default. It stores epics and stories as Markdown files inside the project repository — no external service, no API token, no MCP server.

Use this when:
- You want the backlog to live with the code (reviewable in PRs, versioned in git)
- A single person or small team is doing the work
- You don't (yet) need sprint planning, burndown charts, or multi-team visibility
- You want the option to export to a SaaS board later

## Storage Layout

```
{project-root}/
  docs/
    Backlog/
      backlog.md              # index of epics with status
      EPIC-001-{slug}.md      # one file per epic, stories as sections within
      EPIC-002-{slug}.md
      ...
```

**One file per epic.** Stories are H3 sections inside the epic's file. There is no separate file per story. Sprint management is not scaffolded here yet — add it when you decide how you want to run sprints.

### backlog.md (index)

```markdown
# Backlog

| ID | Title | Status | Stories | Labels |
|----|-------|--------|---------|--------|
| [EPIC-001](EPIC-001-user-auth.md) | User authentication | In Progress | 4 | backend, auth |
| [EPIC-002](EPIC-002-search-api.md) | Search API | Backlog | 6 | backend, api |
| [EPIC-003](EPIC-003-admin-ui.md) | Admin UI | Backlog | 3 | frontend |
```

Regenerate this file whenever an epic is added, renamed, or its status changes.

### EPIC-NNN-{slug}.md

```markdown
# EPIC-001: User authentication

**Status**: In Progress
**Created**: 2026-04-22
**Labels**: backend, auth
**Parent guardrails**: docs/Design/01-business-guardrails-{project}.md
**Parent requirements**: docs/Design/04-requirements-{project}.md

## Overview

Allow customers to sign in with email and password, and stay signed in across sessions.

## Success Criteria

- [ ] Customers can register, sign in, and sign out
- [ ] Sessions expire after 24 hours of inactivity
- [ ] Passwords are hashed with Argon2

## Stories

### STORY-001-1: Registration endpoint

**Status**: Done
**Estimate**: 3
**Assignee**: —
**Labels**: backend

**Description**
Implement `POST /auth/register` that accepts email and password and creates a new user.

**Acceptance Criteria**
- [x] Endpoint validates email format
- [x] Password must be ≥ 12 characters
- [x] Returns 201 with user ID on success
- [x] Returns 409 if email already registered

**Notes**
- 2026-04-22: Decided to use Argon2id over bcrypt (faster, newer standard).

---

### STORY-001-2: Sign-in endpoint

**Status**: In Progress
**Estimate**: 2
**Assignee**: —
**Labels**: backend

**Description**
Implement `POST /auth/signin` that authenticates a user and returns a session token.

**Acceptance Criteria**
- [ ] Valid credentials return a signed JWT
- [ ] Invalid credentials return 401 with a generic message
- [ ] Sign-in attempts are rate-limited to 5 per minute per IP

---

### STORY-001-3: Session expiry

...
```

## ID Convention

- **Epics**: `EPIC-NNN` where `NNN` is a zero-padded sequence (001, 002, ...).
- **Stories**: `STORY-{epic-num}-{n}` where `n` is the story number within the epic (1, 2, 3, ...).
- IDs are allocated in insertion order and never reused.

## Status Values

**Epic status**: `Backlog` | `In Progress` | `Done` | `Cancelled`

**Story status**: `Backlog` | `In Progress` | `Review` | `Done` | `Blocked` | `Cancelled`

Use exactly these values so `backlog.md` and status summaries can be regenerated automatically.

## Operations

Use normal file-editing tools — no API calls.

### Create an epic

1. Pick the next `EPIC-NNN` by scanning existing filenames in `docs/Backlog/`.
2. Write `docs/Backlog/EPIC-NNN-{slug}.md` using the template above.
3. Append a row to `backlog.md`.

### Create a story

1. Open the parent epic's file.
2. Pick the next `STORY-{epic}-{n}` by counting existing `### STORY-…` headings.
3. Insert a new H3 section using the template.
4. Update the **Stories** count in `backlog.md`.

### Move a story through statuses

1. Edit the `**Status**:` line inside the story's section.
2. If it moves to **Done**, tick any remaining acceptance criteria and (optionally) append a completion note with the date and commit SHA.

### Link a commit or PR to a story

Reference the story ID in the commit message or PR title/description, e.g.:

```
feat(auth): add signin endpoint (STORY-001-2)
```

Or in a PR body:

```
Implements STORY-001-2 and STORY-001-3.
```

There is no automated linking — humans and reviewers rely on the ID.

### Move to a SaaS board later

The markdown structure maps cleanly onto ZenHub, Jira, Linear, or GitHub Issues:

- Each epic file → one epic issue + child story issues
- H3 story headings → story titles
- Status values → board columns / transitions
- Labels → board labels
- Estimate → story points

Switching board types later means re-running the setup script and optionally writing a one-off migration script.

## Configuration

Minimal — `.claude/agile-board-config.json`:

```json
{
  "board_type": "markdown",
  "backlog_dir": "docs/Backlog",
  "default_labels": []
}
```

`backlog_dir` defaults to `docs/Backlog` if omitted.

## Conventions

- **Acceptance criteria**: always checkboxes (`- [ ]`), never bullet lists — they're meant to be ticked.
- **Never modify AC text** after a story is in progress — only tick/untick boxes. If the AC was wrong, add a new AC and strike through the old one: `- [~] ~~old AC~~ (revised in STORY-…)`.
- **Australian English** in all prose, identifiers, and comments (organisation, colour, initialise, behaviour, authorisation, recognise, optimise, customise, prioritise).
- Keep story bodies tight. Long design rationale belongs in the matching `docs/Design/` document, linked by file path.

## When This Doesn't Scale

The markdown board works well up to roughly:
- 50 open stories, or
- 3–5 active contributors, or
- A single sprint / single workstream

Past that, you'll probably want sprint tracking, cross-team dashboards, or reporting — switch to `github-issues` (lightweight upgrade) or a SaaS board (ZenHub, Jira, Linear).
