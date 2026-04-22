---
name: github-issues-board
description: Agile-board implementation that uses native GitHub Issues for epics and stories. Uses the gh CLI — no MCP server or token configuration needed beyond `gh auth login`.
---

# GitHub Issues Agile Board

The **github-issues** board type uses native GitHub Issues as the backlog. No separate service, no MCP server — it uses the `gh` CLI, which the user authenticates once with `gh auth login`.

Use this when:
- The project already lives on GitHub
- You want issues visible to external contributors and linked to PRs/commits automatically
- You don't need ZenHub's pipelines, Jira's workflows, or Linear's polish
- You're outgrowing the markdown board but not ready for a dedicated SaaS tool

## Prerequisites

```bash
gh auth status        # must be authenticated
gh repo view          # must be inside a GitHub repo (or set `repo` in config)
```

## Configuration

`.claude/agile-board-config.json`:

```json
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

- `repo` is optional — auto-detected via `gh repo view --json nameWithOwner` if absent.
- Status is tracked via labels (simpler than GitHub Projects, works on every repo). If you use GitHub Projects instead, record the project number under `project_number` and use `gh project item-edit` to move items.

## Issue Hierarchy

**Epic**: a GitHub issue labelled `type:epic`.
**Story**: a GitHub issue labelled `type:story`, with an explicit reference to its parent epic in the body:

```markdown
Parent epic: #42
```

Use GitHub's native sub-issue / parent-issue feature where available. Where not, the `Parent epic: #NN` line is the linkage.

## Operations

All operations shell out to `gh`.

### Create an epic

```bash
gh issue create \
  --repo "$REPO" \
  --title "User authentication" \
  --label "type:epic,status:backlog" \
  --body-file epic-body.md
```

Record the returned issue number as the epic's canonical ID (e.g., epic #42).

### Create a story under an epic

```bash
gh issue create \
  --repo "$REPO" \
  --title "Registration endpoint" \
  --label "type:story,status:backlog,backend" \
  --body "Parent epic: #42

**Description**
Implement \`POST /auth/register\` ...

**Acceptance Criteria**
- [ ] Endpoint validates email format
- [ ] Password ≥ 12 chars
- [ ] Returns 201 on success
- [ ] Returns 409 if email exists
"
```

### Move a story through statuses

Swap the `status:*` label:

```bash
gh issue edit "$NUM" --repo "$REPO" \
  --remove-label "status:backlog" \
  --add-label "status:in-progress"
```

Common transitions:
- Start work → `status:backlog` → `status:in-progress`
- Open a PR → `status:in-progress` → `status:review`
- Merge PR → `status:review` → `status:done` (and close the issue)
- Block → any → `status:blocked`

Closing the issue on merge happens automatically if the PR body contains `Closes #NN` (or `Fixes #NN`, `Resolves #NN`).

### Set an estimate

GitHub Issues doesn't have a native estimate field. Either:
- Use labels like `estimate:3`, `estimate:5` (simple, visible, filterable), or
- Use a GitHub Projects custom field if you're using Projects (`gh project item-edit --field-id ...`).

Stick with one approach per repo.

### Link an epic to its stories

From inside the epic body, list child issues:

```markdown
## Stories

- [ ] #43 Registration endpoint
- [ ] #44 Sign-in endpoint
- [ ] #45 Session expiry
```

GitHub auto-renders these as a task list and tracks completion.

### Link a commit or PR to a story

Use the standard GitHub conventions:

```
feat(auth): add signin endpoint

Implements #44.
```

Or in a PR title/body:

```
Closes #43, #44
```

`Closes` / `Fixes` / `Resolves` will auto-close the issue when the PR merges. Use plain references (`#44`) if you want to link without closing.

## Label Setup

On first use, create the conventional labels. The setup script offers to do this:

```bash
gh label create "type:epic" --color "3E4B9E" --description "Epic (parent)" --repo "$REPO"
gh label create "type:story" --color "1D76DB" --description "Story (child of an epic)" --repo "$REPO"
gh label create "status:backlog" --color "C5DEF5"
gh label create "status:in-progress" --color "FBCA04"
gh label create "status:review" --color "0E8A16"
gh label create "status:done" --color "6F42C1"
gh label create "status:blocked" --color "B60205"
```

Adjust colours and names to match any existing label scheme.

## Conventions

- **Acceptance criteria**: always checkboxes (`- [ ]`) in the issue body.
- **Never modify AC text** after a story is in progress — only tick/untick boxes.
- **Australian English** in titles, bodies, and comments (organisation, colour, initialise, behaviour, authorisation, recognise, optimise, customise, prioritise). Exception: quoting upstream GitHub UI text like "Labels", "Assignees".
- Keep issue bodies tight. Long design rationale belongs in `docs/Design/`, linked by file path.
- Store the epic's sub-issue checklist in the epic body (not in a separate comment) so it survives edits cleanly.

## Migration To / From

**From markdown board**: each `EPIC-NNN-*.md` becomes one epic issue; each H3 story becomes a story issue. Script-friendly — walk the files, shell out to `gh issue create`.

**To ZenHub**: ZenHub sits on top of GitHub Issues, so the issues are already there — just connect ZenHub to the repo and label-pipe mapping.

**To Jira / Linear**: export via `gh issue list --json ...` and import through the target tool's bulk import.
