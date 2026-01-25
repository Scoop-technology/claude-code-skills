# Claude Code Skills & Commands Installer (Windows)

# Get the directory where this script is located (the repo root)
$REPO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$SKILLS_DIR = "$env:USERPROFILE\.claude\skills"
$COMMANDS_DIR = "$env:USERPROFILE\.claude\commands"

Write-Host "📦 Claude Code Skills & Commands Installer" -ForegroundColor Cyan
Write-Host "Installing from: $REPO_DIR" -ForegroundColor Gray
Write-Host ""

# Create directories if they don't exist
if (-Not (Test-Path $SKILLS_DIR)) {
    New-Item -ItemType Directory -Path $SKILLS_DIR | Out-Null
}
if (-Not (Test-Path $COMMANDS_DIR)) {
    New-Item -ItemType Directory -Path $COMMANDS_DIR | Out-Null
}

# Install skills
$installedSkills = 0
$skillsPath = Join-Path $REPO_DIR "skills"
if (Test-Path $skillsPath) {
    $skillDirs = Get-ChildItem -Path $skillsPath -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName "SKILL.md")) -and ($_.Name -notmatch "^\.")
    }

    if ($skillDirs.Count -eq 0) {
        Write-Host "⚠️  No skills found in skills/ directory" -ForegroundColor Yellow
    } else {
        foreach ($skillDir in $skillDirs) {
            $skill = $skillDir.Name
            $sourcePath = $skillDir.FullName
            $targetPath = Join-Path $SKILLS_DIR $skill

            # Remove existing symlink if present
            if (Test-Path $targetPath) {
                $item = Get-Item $targetPath
                if ($item.LinkType -eq "SymbolicLink") {
                    Remove-Item $targetPath
                } else {
                    Write-Host "⚠️  Warning: $targetPath already exists and is not a symlink" -ForegroundColor Yellow
                    Write-Host "   Please remove it manually if you want to replace it" -ForegroundColor Yellow
                    continue
                }
            }

            # Create symlink (requires admin privileges on older Windows versions)
            try {
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -ErrorAction Stop | Out-Null
                Write-Host "✅ Installed skill: $skill" -ForegroundColor Green
                $installedSkills++
            } catch {
                Write-Host "❌ Failed to install skill $skill : $_" -ForegroundColor Red
                Write-Host "   You may need to run PowerShell as Administrator" -ForegroundColor Yellow
            }
        }
    }
}

# Install commands
$installedCommands = 0
$commandsPath = Join-Path $REPO_DIR "commands"
if (Test-Path $commandsPath) {
    $commandFiles = Get-ChildItem -Path $commandsPath -Filter "*.md"

    if ($commandFiles.Count -eq 0) {
        Write-Host "⚠️  No commands found in commands/ directory" -ForegroundColor Yellow
    } else {
        foreach ($commandFile in $commandFiles) {
            $command = $commandFile.Name
            $sourcePath = $commandFile.FullName
            $targetPath = Join-Path $COMMANDS_DIR $command

            # Remove existing symlink if present
            if (Test-Path $targetPath) {
                $item = Get-Item $targetPath
                if ($item.LinkType -eq "SymbolicLink") {
                    Remove-Item $targetPath
                } else {
                    Write-Host "⚠️  Warning: $targetPath already exists and is not a symlink" -ForegroundColor Yellow
                    Write-Host "   Please remove it manually if you want to replace it" -ForegroundColor Yellow
                    continue
                }
            }

            # Create symlink (requires admin privileges on older Windows versions)
            try {
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -ErrorAction Stop | Out-Null
                $commandName = [System.IO.Path]::GetFileNameWithoutExtension($command)
                Write-Host "✅ Installed command: $commandName" -ForegroundColor Green
                $installedCommands++
            } catch {
                Write-Host "❌ Failed to install command $command : $_" -ForegroundColor Red
                Write-Host "   You may need to run PowerShell as Administrator" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host ""
Write-Host "📝 Installation complete:" -ForegroundColor Cyan
Write-Host "   - $installedSkills skill(s) installed to $SKILLS_DIR"
Write-Host "   - $installedCommands command(s) installed to $COMMANDS_DIR"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - Skills and commands are now available globally for all projects"
Write-Host "  - For agile-board: Run 'python $REPO_DIR\skills\agile-board\scripts\setup.py' in your project"
Write-Host "  - To update: git pull in $REPO_DIR"
