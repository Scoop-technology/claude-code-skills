#!/bin/bash

# Claude Code Skills & Commands Installer (Linux/Mac)
#
# Usage:
#   ./install.sh                            # Global install (symlinks to ~/.claude/)
#   ./install.sh --project                  # Per-project install (copies to ./.claude/)
#   ./install.sh --project /path/to/repo    # Per-project install into a specific dir
#   ./install.sh --project --symlink        # Per-project install using symlinks (solo dev, not for git-sharing)
#   ./install.sh --project --gitignore      # Per-project install + add .claude/skills|commands to .gitignore
#
# Global install is shared across every project and updates live via `git pull`.
# Per-project install puts skills & commands inside the project's `.claude/` folder.
# Default per-project mode copies files — safe to commit, no symlink permission issues,
# and teammates get the skills just by cloning the project. Pass --gitignore to keep
# them local-only instead.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Parse args ---
MODE="global"
TARGET_DIR=""
USE_SYMLINK=false
ADD_GITIGNORE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project|--local)
            MODE="project"
            shift
            ;;
        --symlink)
            USE_SYMLINK=true
            shift
            ;;
        --gitignore)
            ADD_GITIGNORE=true
            shift
            ;;
        --global)
            MODE="global"
            shift
            ;;
        -h|--help)
            sed -n '3,16p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# --- Resolve install target ---
if [ "$MODE" = "project" ]; then
    if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$(pwd)"
    fi
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
    SKILLS_DIR="$TARGET_DIR/.claude/skills"
    COMMANDS_DIR="$TARGET_DIR/.claude/commands"
    LOCATION_LABEL="project ($TARGET_DIR)"
else
    SKILLS_DIR="$HOME/.claude/skills"
    COMMANDS_DIR="$HOME/.claude/commands"
    LOCATION_LABEL="global (~/.claude)"
    USE_SYMLINK=true  # Global install always uses symlinks (for git pull updates)
fi

echo "📦 Claude Code Skills & Commands Installer"
echo "   From:    $REPO_DIR"
echo "   To:      $LOCATION_LABEL"
echo "   Method:  $([ "$USE_SYMLINK" = true ] && echo "symlink" || echo "copy")"
echo ""

if [ "$MODE" = "project" ] && [ "$TARGET_DIR" = "$REPO_DIR" ]; then
    echo "⚠️  Refusing to install into the skills repo itself."
    echo "   Run this from inside your project, or pass the project path:"
    echo "     $0 --project /path/to/your/project"
    exit 1
fi

mkdir -p "$SKILLS_DIR"
mkdir -p "$COMMANDS_DIR"

install_item() {
    # install_item <source> <target>
    local source="$1"
    local target="$2"

    # Remove existing target (symlink, file, or directory) so we can replace it
    if [ -L "$target" ]; then
        rm "$target"
    elif [ -e "$target" ]; then
        if [ "$USE_SYMLINK" = true ]; then
            echo "⚠️  Exists and is not a symlink — skipping: $target" >&2
            return 1
        fi
        # Copy mode — safe to overwrite
        rm -rf "$target"
    fi

    if [ "$USE_SYMLINK" = true ]; then
        ln -s "$source" "$target"
    else
        cp -R "$source" "$target"
    fi
}

# --- Install skills ---
installed_skills=0
if [ -d "$REPO_DIR/skills" ]; then
    for skill_path in "$REPO_DIR"/skills/*/SKILL.md; do
        [ -e "$skill_path" ] || { echo "⚠️  No skills found in skills/"; break; }
        skill=$(basename "$(dirname "$skill_path")")
        [[ "$skill" == .* ]] && continue

        if install_item "$REPO_DIR/skills/$skill" "$SKILLS_DIR/$skill"; then
            echo "✅ Installed skill: $skill"
            installed_skills=$((installed_skills + 1))
        fi
    done
fi

# --- Install commands ---
installed_commands=0
if [ -d "$REPO_DIR/commands" ]; then
    for command_file in "$REPO_DIR"/commands/*.md; do
        [ -e "$command_file" ] || { echo "⚠️  No commands found in commands/"; break; }
        command=$(basename "$command_file")

        if install_item "$REPO_DIR/commands/$command" "$COMMANDS_DIR/$command"; then
            echo "✅ Installed command: ${command%.md}"
            installed_commands=$((installed_commands + 1))
        fi
    done
fi

echo ""
echo "📝 Installation complete:"
echo "   - $installed_skills skill(s) installed to $SKILLS_DIR"
echo "   - $installed_commands command(s) installed to $COMMANDS_DIR"
echo ""

if [ "$MODE" = "project" ]; then
    # Optionally add to .gitignore
    if [ "$ADD_GITIGNORE" = true ]; then
        gitignore="$TARGET_DIR/.gitignore"
        marker="# Claude Code skills and commands (local-only install)"
        if [ -f "$gitignore" ] && grep -qF "$marker" "$gitignore"; then
            echo "ℹ️  .gitignore already has entries for .claude/skills and .claude/commands"
        else
            {
                echo ""
                echo "$marker"
                echo ".claude/skills/"
                echo ".claude/commands/"
            } >> "$gitignore"
            echo "✅ Added .claude/skills/ and .claude/commands/ to .gitignore"
        fi
    fi

    echo ""
    echo "Next steps:"
    echo "  - Skills and commands are available inside: $TARGET_DIR"
    if [ "$ADD_GITIGNORE" = true ]; then
        echo "  - Skills and commands are gitignored — every dev runs this install themselves"
    else
        echo "  - Decide whether to commit or ignore the installed files:"
        echo "      * Share with teammates:  git add .claude/skills .claude/commands && git commit"
        echo "      * Keep local-only:       re-run with --gitignore, or add .claude/skills/ and .claude/commands/ to .gitignore"
    fi
    echo "  - For agile-board: python $REPO_DIR/skills/agile-board/scripts/setup.py"
    if [ "$USE_SYMLINK" = false ]; then
        echo "  - To update: re-run this script after 'git pull' in $REPO_DIR"
    else
        echo "  - To update: git pull in $REPO_DIR (symlinks track automatically)"
    fi
else
    echo "Next steps:"
    echo "  - Skills and commands are now available globally for all projects"
    echo "  - For agile-board: python $REPO_DIR/skills/agile-board/scripts/setup.py  (run inside each project)"
    echo "  - To update: git pull in $REPO_DIR  (symlinks track automatically)"
fi
