# Agile Board Skill

Board-agnostic agile-board integration. Default is **markdown files in the project repo**; other supported types are **GitHub Issues**, **ZenHub**, **Jira**, and **Linear**.

## Files

- **SKILL.md** — main skill instructions (loaded when triggered)
- **config.json.example** — example configuration (copy to the project's `.claude/` directory)
- **scripts/setup.py** — interactive setup wizard

### References (loaded as needed)

- **references/markdown.md** — default: markdown files in `docs/Backlog/` (one file per epic, stories as sections within)
- **references/github-issues.md** — GitHub Issues via the `gh` CLI
- **references/zenhub.md** — ZenHub MCP tools, field mappings, workflows
- **references/jira.md** — Jira REST API patterns (placeholder for now)
- **references/linear.md** — Linear GraphQL queries (placeholder for now)
- **references/ticket-workflow.md** — lifecycle updates (commit, PR creation, review, merge)

## When This Skill Triggers

Claude loads this skill when you:
- Create epics or stories (`"create a story for..."`)
- Manage sprints (`"add this to the current sprint..."`)
- Update status (`"move this issue to in progress..."`)
- Set estimates (`"set story points for..."`)
- Link stories to epics (`"link this story to epic 4..."`)

## First Time Setup

**IMPORTANT**: on first use in a new project, run the setup wizard:

```bash
python ~/.claude/skills/agile-board/scripts/setup.py
```

This creates `.claude/agile-board-config.json` in the project directory. For the default **markdown** board you can just press Enter through the prompts — no API token, no workspace setup.

For other boards, the wizard collects:
- GitHub Issues: repo (auto-detected), whether to create standard labels
- ZenHub: API token, workspace, default pipeline, default labels
- Jira: URL, project key
- Linear: team ID, workspace ID

The config is project-specific and should be gitignored.

## Configuration Location

Configs live in **project directories**, not in the skill directory:

```
~/.claude/skills/agile-board/                # global skill (shared)
/project-a/.claude/agile-board-config.json   # project A uses markdown
/project-b/.claude/agile-board-config.json   # project B uses ZenHub
```

Add to each project's `.gitignore`:

```
.claude/agile-board-config.json
```

## Switching Projects

The skill automatically detects the current project and uses that project's config.

## Reconfiguring

To change board settings for a project:

```bash
rm .claude/agile-board-config.json
python ~/.claude/skills/agile-board/scripts/setup.py
```

## Board Types Supported

- **markdown** *(default)* — epics and stories as Markdown files in `docs/Backlog/`
- **github-issues** — native GitHub Issues via `gh`
- **ZenHub** — full support via MCP server
- **Jira** — placeholder (REST patterns to follow)
- **Linear** — placeholder (GraphQL patterns to follow)
