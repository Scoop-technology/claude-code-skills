---
name: agile-board
description: "Board-specific implementation for creating and managing epics, stories, and tickets. Supports markdown files in the project repo (default), GitHub Issues, ZenHub, Jira, and Linear. Use when: creating issues, moving them between statuses, adding to sprints, setting estimates, or linking stories to epics. For story templates and estimation guidance use the project-management skill. On first use in a project, run setup if .claude/agile-board-config.json is missing."
---

# Agile Board Integration

Board-specific implementation for markdown-in-repo, GitHub Issues, ZenHub, Jira, and Linear.

## Overview

**This skill provides the "WHERE"**: board-specific file layouts, CLIs, APIs, and MCP tools for creating and managing epics, stories, and tickets.

**For the "WHAT" and "HOW"**: use the `project-management` skill for story templates, acceptance criteria, estimation, and sprint workflows.

**Key capabilities**:
- Create and update epics, stories, and tickets on any supported board
- Set estimates in the board's dedicated field
- Link stories to parent epics
- Move items between statuses / pipelines / columns
- Manage labels and assignees

## Supported Board Types

| Type | Where it lives | Needs | When to pick it |
|------|----------------|-------|-----------------|
| `markdown` *(default)* | `docs/Backlog/` in the project repo | Nothing beyond a text editor | Small team, backlog lives with code, no SaaS needed |
| `github-issues` | Native GitHub Issues | `gh` CLI authenticated | Project is on GitHub, want issues visible and linkable to PRs |
| `zenhub` | ZenHub (on top of GitHub) | ZenHub API token, MCP server | Team already on ZenHub, wants pipelines and sprints |
| `jira` | Jira Cloud / Server | Jira MCP or REST auth | Enterprise, existing Jira instance |
| `linear` | Linear | Linear API key | Team on Linear |

Default: **markdown**. Switch by re-running the setup script.

## Critical Rules

### 1. Issue Creation Best Practices
- **Use native issues** for the chosen board (ZenHub → GitHub issues, not ZenHub-native; Jira → Jira issues; Linear → Linear issues; markdown → files in `docs/Backlog/`; github-issues → GitHub Issues).
- **Estimate in the dedicated field** — use the board's API/label/field for estimates, never hide them in the title.
- **Never** put estimates in the title.

### 2. Acceptance Criteria Format
Always checkboxes, for trackability:

```markdown
## Acceptance Criteria
- [ ] Customer can sign in with email and password
- [ ] Session expires after 24 hours
- [ ] Error messages display for invalid credentials
```

Never use non-checkbox formats.

### 3. Australian English
All titles, descriptions, comments, and labels use Australian English: organisation, colour, initialise, behaviour, authorisation, optimise, customise, prioritise, recognise. Exceptions: third-party product names and quoted upstream text (e.g., "Labels" in the GitHub UI).

### 4. Labels and Links
- Add labels at creation time (ZenHub and some other boards don't allow updates after).
- Link to the parent epic at creation (easier than linking later).
- Never skip epic linking for stories — it breaks hierarchy tracking.

### 5. First-Time Setup Required
- Check whether `.claude/agile-board-config.json` exists before using this skill.
- If it's missing, run `python3 ~/.claude/skills/agile-board/scripts/setup.py`. For the markdown default, no token is needed — just accept the defaults.
- Never proceed without a valid board configuration.

## First Time Setup (Per Project)

Run the setup wizard inside the project directory:

```bash
python3 ~/.claude/skills/agile-board/scripts/setup.py
```

**What it asks**:
1. Board type — defaults to `markdown` if you just press Enter
2. For `markdown`: the backlog directory (default `docs/Backlog`) and optional default labels
3. For `github-issues`: auto-detects the repo via `gh`, offers to create the conventional labels
4. For `zenhub`/`jira`/`linear`: API token, workspace/project, default pipeline/status

**What it configures**:
1. `.claude/agile-board-config.json` — project-local board settings
2. `~/.claude.json` — MCP server configuration (only for boards that use MCP)
3. `~/.claude/settings.json` — permission wildcards to auto-approve MCP calls
4. `.gitignore` — excludes the config file from version control

**Config lives in the project, not the skill**:
- Correct: `/home/user/project-a/.claude/agile-board-config.json`
- Wrong: `~/.claude/skills/agile-board/config.json`

**Non-interactive mode** (for automation):

```bash
# markdown (default)
python3 ~/.claude/skills/agile-board/scripts/setup.py --board-type markdown --force

# github-issues
python3 ~/.claude/skills/agile-board/scripts/setup.py \
  --board-type github-issues \
  --repo "owner/name" \
  --create-labels \
  --force

# zenhub
python3 ~/.claude/skills/agile-board/scripts/setup.py \
  --board-type zenhub \
  --api-token zh_xxx \
  --workspace-id "Z2lkOi8..." \
  --repository-id "R_kgDO..." \
  --organization-id "Z2lkOi8..." \
  --default-pipeline-id "Z2lkOi8..." \
  --default-pipeline-name "Product Backlog" \
  --default-labels "backend,python" \
  --force
```

## Quick Start

After setup:
- Create epics and stories
- Set estimates
- Link stories to parent epics
- Move items between statuses
- Add labels and assignees
- Manage sprints (boards that support it)

## Model Selection

**Recommended model**: Haiku (fast and cost-effective).

**Why Haiku**:
- Operations are mostly file edits, CLI calls, or MCP tool invocations with defined parameters
- Simple CRUD — creating, reading, updating items
- Status transitions follow clear patterns
- No complex reasoning required
- High frequency — cost and latency matter

## Board-Specific References

The SKILL loads the relevant reference file based on the configured `board_type`:

- `references/markdown.md` — file layout, ID convention, and operations for the default markdown board
- `references/github-issues.md` — `gh` CLI patterns and label conventions
- `references/zenhub.md` — ZenHub MCP tools, field mappings, pipeline IDs
- `references/jira.md` — Jira REST API patterns, custom fields
- `references/linear.md` — Linear GraphQL queries, status IDs

## Common Operations

### Creating an Issue

**Pre-creation** (use the `project-management` skill):
1. Draft the story using story templates
2. Write acceptance criteria
3. Estimate using T-shirt sizing or story points

**Board creation** (use this skill):
1. Create the item on the configured board
2. Set the item type (epic/story)
3. Set the estimate in the dedicated field
4. Link to the parent epic
5. Add labels (cannot be changed later on some boards)
6. Move to the starting status / pipeline

**Board-specific details**: see your board's reference file in `references/`.

### Issue Hierarchy

```
Epic (Level 3)
  └── Story / Feature (Level 4)
      └── Sub-task (Level 5)
```

Every story links to its parent epic.

### Board-Specific Rules

Different boards have different limitations:

**markdown** (default):
- Stories live as H3 sections inside an epic's file
- Status is a `**Status**:` line
- No cross-repo moves without a migration script

**github-issues**:
- Status tracked via `status:*` labels (or a GitHub Project's status field)
- Parent epic referenced in the story body (`Parent epic: #42`)
- Auto-close stories on PR merge via `Closes #NN`

**ZenHub**:
- Use GitHub issues (not ZenHub-native)
- Set estimates via `setIssueEstimate`
- Cannot update labels after creation

**Jira** (planned):
- Estimates in the story points custom field
- Labels can be updated after creation

**Linear** (planned):
- Estimates in points or time
- Labels can be updated after creation

## Story Content & Sprint Workflows

For story structure, templates, sprint planning, and velocity tracking, see the `project-management` skill.

Board-specific implementation:
- Use the board's file layout / CLI / MCP tools to create items with the story content
- Move items between statuses using board-specific operations
- See `references/` for board-specific sprint operations where supported

## Configuration

`.claude/agile-board-config.json` examples:

```json
// markdown
{
  "board_type": "markdown",
  "backlog_dir": "docs/Backlog",
  "default_labels": []
}
```

```json
// github-issues
{
  "board_type": "github-issues",
  "repo": "owner/name",
  "epic_label": "type:epic",
  "story_label": "type:story",
  "status_labels": {
    "backlog": "status:backlog",
    "in_progress": "status:in-progress",
    "review": "status:review",
    "done": "status:done",
    "blocked": "status:blocked"
  },
  "default_labels": []
}
```

```json
// zenhub
{
  "board_type": "zenhub",
  "workspace_id": "...",
  "repository_id": "...",
  "organization_id": "...",
  "default_labels": ["backend", "python"],
  "default_pipeline_id": "...",
  "default_pipeline_name": "Product Backlog"
}
```

**Switching boards**: delete `.claude/agile-board-config.json` and re-run the setup script.

**Multi-project usage**: each project has its own config, so one project can use markdown and another can use ZenHub.

## Troubleshooting

### "config file not found"

Run the setup script inside the project directory:

```bash
cd /path/to/your/project
python ~/.claude/skills/agile-board/scripts/setup.py
```

### "Cannot update labels"

Most SaaS boards don't support updating labels after creation. Add labels at creation time.

### "Parent epic not found"

Cause: epic ID is incorrect, or the epic doesn't exist.

Fix:
1. List available epics (markdown: scan `docs/Backlog/`; github-issues: `gh issue list --label type:epic`; zenhub/jira/linear: query the board)
2. Verify the ID format matches your board type
3. Ensure the epic exists before linking

### "Estimate not showing"

Cause: estimate set in the wrong field (e.g., description instead of the dedicated field).

Fix: use the board's specific estimate mechanism — see `references/`.

### "Wrong board config loaded"

Cause: working in a different project than expected.

Fix: check the current directory — config is loaded from the current project's `.claude/` directory.

## Related Skills

- **project-management** — story templates, estimation guide, sprint workflows
- **developer-analysis** — pre-implementation analysis, POC scripts, design proposals
- **git-workflow** — branch naming, commit conventions, PR creation
- **requirements-design** — produces the five numbered design docs (Business Guardrails, Press Release, Solution Design, Detailed Requirements, Architecture) that epics and stories implement

## References

### Workflow Documentation
- `references/ticket-workflow.md` — how items update through the development lifecycle (commit, PR creation, PR review, merge)

### Board-Specific Implementation
- `references/markdown.md` — markdown board (default)
- `references/github-issues.md` — GitHub Issues
- `references/zenhub.md` — ZenHub MCP tools, field mappings, pipeline IDs
- `references/jira.md` — Jira REST API patterns, custom fields
- `references/linear.md` — Linear GraphQL queries, status IDs

Choose the board type during setup, and the skill loads the appropriate reference.
