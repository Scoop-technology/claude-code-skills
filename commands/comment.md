---
name: comment
description: Add a comment to the current story ticket on the agile board. Identifies the story from the current branch name and posts the comment via the board API.
argument-hint: "[comment text]"
disable-model-invocation: true
---

# Comment Command

Add a comment to the current story ticket on the board.

## Instructions

When this command is invoked:

1. **Identify the story**:
   - Extract story number from current branch name (e.g., `feature/epic-1-story-2.3-dark-mode` → story 2.3)
   - If not on a feature branch, ask for the story ID/number

2. **Get the comment**:
   - Ask user what comment to add
   - Format with markdown if appropriate
   - **IMPORTANT: No AI attribution** - Do not add "Co-Authored-By: Claude" or similar to comments

3. **Post to board**:
   - Load the **agile-board** skill to post the comment using your board's API
   - Supports markdown (default), GitHub Issues, ZenHub, Jira, and Linear — see the agile-board skill for board-specific implementation

## Use Cases

- Progress updates: "Implemented user model, working on authentication next"
- Blockers: "Blocked by API rate limiting issue in ticket #123"
- Questions: "@alice Can you clarify the acceptance criteria for mobile?"
- Design decisions: "Using JWT tokens instead of sessions per @bob's recommendation"
- Test results: "All unit tests passing, integration tests pending"
