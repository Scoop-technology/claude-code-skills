#!/bin/bash

# Get the directory where this script is located (the repo root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
COMMANDS_DIR="$HOME/.claude/commands"

echo "📦 Claude Code Skills & Commands Installer"
echo "Installing from: $REPO_DIR"
echo ""

# Create directories if they don't exist
mkdir -p "$SKILLS_DIR"
mkdir -p "$COMMANDS_DIR"

# Install skills
installed_skills=0
if [ -d "$REPO_DIR/skills" ]; then
    for skill_path in "$REPO_DIR"/skills/*/SKILL.md; do
        # Check if any SKILL.md files were found
        if [ ! -e "$skill_path" ]; then
            echo "⚠️  No skills found in skills/ directory"
            break
        fi

        # Get the skill directory name
        skill=$(basename "$(dirname "$skill_path")")

        # Skip hidden directories
        if [[ "$skill" == .* ]]; then
            continue
        fi

        skill_source="$REPO_DIR/skills/$skill"
        skill_target="$SKILLS_DIR/$skill"

        # Remove existing symlink if present
        if [ -L "$skill_target" ]; then
            rm "$skill_target"
        elif [ -d "$skill_target" ]; then
            echo "⚠️  Warning: $skill_target already exists and is not a symlink"
            echo "   Please remove it manually if you want to replace it"
            continue
        fi

        # Create symlink
        ln -s "$skill_source" "$skill_target"
        echo "✅ Installed skill: $skill"
        ((installed_skills++))
    done
fi

# Install commands
installed_commands=0
if [ -d "$REPO_DIR/commands" ]; then
    for command_file in "$REPO_DIR"/commands/*.md; do
        # Check if any .md files were found
        if [ ! -e "$command_file" ]; then
            echo "⚠️  No commands found in commands/ directory"
            break
        fi

        # Get the command filename
        command=$(basename "$command_file")

        command_source="$REPO_DIR/commands/$command"
        command_target="$COMMANDS_DIR/$command"

        # Remove existing symlink if present
        if [ -L "$command_target" ]; then
            rm "$command_target"
        elif [ -f "$command_target" ]; then
            echo "⚠️  Warning: $command_target already exists and is not a symlink"
            echo "   Please remove it manually if you want to replace it"
            continue
        fi

        # Create symlink
        ln -s "$command_source" "$command_target"
        echo "✅ Installed command: ${command%.md}"
        ((installed_commands++))
    done
fi

echo ""
echo "📝 Installation complete:"
echo "   - $installed_skills skill(s) installed to ~/.claude/skills/"
echo "   - $installed_commands command(s) installed to ~/.claude/commands/"
echo ""
echo "Next steps:"
echo "  - Skills and commands are now available globally for all projects"
echo "  - For agile-board: Run 'python $REPO_DIR/skills/agile-board/scripts/setup.py' in your project"
echo "  - To update: git pull in $REPO_DIR"
