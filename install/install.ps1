param(
    [Parameter(Mandatory=$false)]
    [string[]]$Tool,

    [Parameter(Mandatory=$false)]
    [switch]$Interactive
)

# ==========================================================
# 1. Helper functions (Functions must be defined first)
# ==========================================================

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Safe-BackupDirectory {
    param(
        [string]$SourceDir,
        [string]$BackupDir
    )
    if (-not (Test-Path $SourceDir)) { return }
    
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    
    $Items = Get-ChildItem -Path $SourceDir -Recurse
    foreach ($Item in $Items) {
        $RelativePath = $Item.FullName.Substring($SourceDir.Length + 1)
        if ([string]::IsNullOrEmpty($RelativePath)) { continue }
        $DestinationPath = Join-Path $BackupDir $RelativePath
        
        if ($Item.PSIsContainer) {
            if (-not (Test-Path $DestinationPath)) {
                New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
            }
        }
        else {
            try {
                Copy-Item -Path $Item.FullName -Destination $DestinationPath -Force -ErrorAction Stop
            }
            catch {
                # Skip on backup failure
            }
        }
    }
}

function Safe-CopyAndReplaceDirectory {
    param(
        [string]$SourceDir,
        [string]$TargetDir,
        [hashtable]$Mappings,
        [string[]]$ExcludedTopLevelDirectories = @()
    )
    
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    
    $Items = Get-ChildItem -Path $SourceDir -Recurse
    foreach ($Item in $Items) {
        $RelativePath = $Item.FullName.Substring($SourceDir.Length + 1)
        if ([string]::IsNullOrEmpty($RelativePath)) { continue }
        $TopLevelDirectory = ($RelativePath -split '[\\/]')[0]
        if ($ExcludedTopLevelDirectories -contains $TopLevelDirectory) { continue }
        
        # Handle rename cases
        $DestinationRelativePath = $RelativePath
        if ($RelativePath -eq "AGENTS.md") {
            $DestinationRelativePath = $Mappings["{{RULES_FILE}}"]
        }
        elseif ($RelativePath -eq "config\common.config.sample.toml") {
            $DestinationRelativePath = "config\" + $Mappings["{{CONFIG_FILE}}"]
        }
        
        $DestinationPath = Join-Path $TargetDir $DestinationRelativePath
        
        if ($Item.PSIsContainer) {
            if (-not (Test-Path $DestinationPath)) {
                New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
            }
        }
        else {
            try {
                $Extension = $Item.Extension.ToLower()
                # Substitute variables for text files
                if ($Extension -eq ".md" -or $Extension -eq ".toml" -or $Extension -eq ".txt") {
                    $Content = Get-Content -Path $Item.FullName -Raw -Encoding UTF8
                    foreach ($Key in $Mappings.Keys) {
                        $Content = $Content.Replace($Key, $Mappings[$Key])
                    }
                    if ([string]::IsNullOrWhiteSpace($Mappings["{{GIT_REMOTE_URL}}"]) -and $Extension -eq ".toml") {
                        $Content = $Content.Replace("auto_commit_push = true", "auto_commit_push = false")
                    }
                    $ParentDir = Split-Path -Parent $DestinationPath
                    if (-not (Test-Path $ParentDir)) {
                        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
                    }
                    Set-Content -Path $DestinationPath -Value $Content -Encoding UTF8
                }
                else {
                    # Binary or other files
                    $ParentDir = Split-Path -Parent $DestinationPath
                    if (-not (Test-Path $ParentDir)) {
                        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
                    }
                    Copy-Item -Path $Item.FullName -Destination $DestinationPath -Force -ErrorAction Stop
                }
            }
            catch {
                Write-Host "[WARNING] File skip (in use or access denied): $RelativePath" -ForegroundColor Yellow
            }
        }
    }
}

function Deploy-IgnoreFiles {
    param([string]$RepoRoot)
    
    $AgentIgnoreContent = @(
        "# vibe-frame-kit ignore rules (AI Agent indexing)",
        "*.backup.*",
        "backup.*",
        "venv/",
        ".venv/",
        "node_modules/",
        ".git/",
        "common/",
        "install/",
        "walkthrough/",
        "study/"
    ) -join "`r`n"

    $GitIgnoreContent = @(
        "# vibe-frame-kit ignore rules (Git version control)",
        "*.backup.*",
        "backup.*",
        "venv/",
        ".venv/",
        "node_modules/",
        ".env",
        ".env.local",
        ".env.*.local"
    ) -join "`r`n"
    
    $AgentFiles = @(".cursorignore", ".geminiignore")
    foreach ($File in $AgentFiles) {
        $FilePath = Join-Path $RepoRoot $File
        if (-not (Test-Path $FilePath)) {
            Set-Content -Path $FilePath -Value $AgentIgnoreContent -Encoding UTF8
            Write-Success "Created $File at repository root to prevent token waste."
        }
    }

    $GitIgnorePath = Join-Path $RepoRoot ".gitignore"
    if (-not (Test-Path $GitIgnorePath)) {
        Set-Content -Path $GitIgnorePath -Value $GitIgnoreContent -Encoding UTF8
        Write-Success "Created .gitignore at repository root to secure credentials."
    }
}

function Show-MultiSelectMenu {
    param(
        [string]$Title,
        [System.Collections.Generic.List[hashtable]]$Options
    )
    $SelectedIndex = 0
    $Done = $false

    $OriginalCursorVisible = $true
    try {
        $OriginalCursorVisible = [Console]::CursorVisible
        [Console]::CursorVisible = $false
    } catch {}

    while (-not $Done) {
        Clear-Host
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " $Title" -ForegroundColor Yellow
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host "Select options using Up/Down arrows and Spacebar." -ForegroundColor Yellow
        Write-Host "Press Enter to confirm selection." -ForegroundColor Gray
        Write-Host ""

        for ($i = 0; $i -lt $Options.Count; $i++) {
            $Check = if ($Options[$i].Selected) { "[X]" } else { "[ ]" }
            $Indicator = if ($i -eq $SelectedIndex) { ">" } else { " " }
            
            $ForegroundColor = "Cyan"
            if ($Options[$i].Selected) { $ForegroundColor = "Green" }
            if ($i -eq $SelectedIndex) { $ForegroundColor = "White" }

            Write-Host "  $Indicator $Check $($Options[$i].Name)" -ForegroundColor $ForegroundColor
        }
        Write-Host ""

        $KeyInfo = [Console]::ReadKey($true)
        switch ($KeyInfo.Key) {
            "UpArrow" {
                $SelectedIndex = ($SelectedIndex - 1 + $Options.Count) % $Options.Count
            }
            "DownArrow" {
                $SelectedIndex = ($SelectedIndex + 1) % $Options.Count
            }
            "Spacebar" {
                $Options[$SelectedIndex].Selected = -not $Options[$SelectedIndex].Selected
            }
            "Enter" {
                $Done = $true
            }
        }
    }

    try {
        [Console]::CursorVisible = $OriginalCursorVisible
    } catch {}
}


# ==========================================================
# 2. Global settings
# ==========================================================

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ==========================================================
# 3. Main execution logic
# ==========================================================

try {
    # Interactive checklist for tool selection if not specified
    $SelectedTools = @()
    if ($null -eq $Tool -or $Tool.Count -eq 0) {
        $Options = [System.Collections.Generic.List[hashtable]]::new()
        $Options.Add(@{ Name = "Gemini (Antigravity)"; Value = "gemini"; Selected = $false })
        $Options.Add(@{ Name = "Claude (Desktop / Code CLI)"; Value = "claude"; Selected = $false })
        $Options.Add(@{ Name = "Codex (Cursor, etc.)"; Value = "codex"; Selected = $false })
        $Options.Add(@{ Name = "Muse (Muse Spark / Muse Code CLI)"; Value = "muse"; Selected = $false })
        $Options.Add(@{ Name = "OpenCode"; Value = "opencode"; Selected = $false })

        while ($true) {
            Show-MultiSelectMenu -Title "Select AI development tool environment(s) to install" -Options $Options
            $SelectedTools = $Options | Where-Object { $_.Selected } | ForEach-Object { $_.Value }
            if ($SelectedTools.Count -gt 0) {
                break
            } else {
                Write-Host "[ERROR] You must select at least one tool." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } else {
        # Split any comma separated strings in the array and clean them
        $ParsedTools = @()
        foreach ($T in $Tool) {
            if (-not [string]::IsNullOrWhiteSpace($T)) {
                $ParsedTools += $T -split ',' | ForEach-Object { $_.Trim().ToLower() }
            }
        }
        
        # Validate tools
        foreach ($T in $ParsedTools) {
            if ($T -notin @("gemini", "claude", "codex", "muse", "opencode")) {
                throw "Invalid tool: $T. Valid tools are: gemini, claude, codex, muse, opencode"
            }
            $SelectedTools += $T
        }
    }

    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    # Deploy ignore files at repository root once
    Deploy-IgnoreFiles -RepoRoot $RepoRoot

    foreach ($CurrentTool in $SelectedTools) {
        # Define tool configurations
        $Mappings = @{}
        $InstallBaseDir = ""
        $SkillInstallDir = ""
        switch ($CurrentTool) {
            "gemini" {
                $InstallBaseDir = Join-Path $HOME ".gemini\config"
                $SkillInstallDir = Join-Path $InstallBaseDir "skills"
                $Mappings["{{AGENT_NAME}}"] = "Gemini"
                $Mappings["{{INSTALL_PATH}}"] = "~/.gemini/config"
                $Mappings["{{CONFIG_FILE}}"] = "gemini.config.sample.toml"
                $Mappings["{{RULES_FILE}}"] = "AGENTS.md"
            }
            "claude" {
                $InstallBaseDir = Join-Path $HOME ".claude"
                $SkillInstallDir = Join-Path $InstallBaseDir "skills"
                $Mappings["{{AGENT_NAME}}"] = "Claude"
                $Mappings["{{INSTALL_PATH}}"] = "~/.claude"
                $Mappings["{{CONFIG_FILE}}"] = "claude.config.sample.toml"
                $Mappings["{{RULES_FILE}}"] = "CLAUDE.md"
            }
            "codex" {
                $InstallBaseDir = Join-Path $HOME ".codex"
                $SkillInstallDir = Join-Path $HOME ".agents\skills"
                $Mappings["{{AGENT_NAME}}"] = "Codex"
                $Mappings["{{INSTALL_PATH}}"] = "~/.codex"
                $Mappings["{{CONFIG_FILE}}"] = "codex.config.sample.toml"
                $Mappings["{{RULES_FILE}}"] = "AGENTS.md"
            }
            "muse" {
                $InstallBaseDir = Join-Path $HOME ".config/muse"
                $SkillInstallDir = Join-Path $InstallBaseDir "skills"
                $Mappings["{{AGENT_NAME}}"] = "Muse"
                $Mappings["{{INSTALL_PATH}}"] = "~/.config/muse"
                $Mappings["{{CONFIG_FILE}}"] = "muse.config.sample.toml"
                $Mappings["{{RULES_FILE}}"] = "AGENTS.md"
            }
            "opencode" {
                $InstallBaseDir = Join-Path $HOME ".config/opencode"
                $SkillInstallDir = Join-Path $InstallBaseDir "skills"
                $Mappings["{{AGENT_NAME}}"] = "OpenCode"
                $Mappings["{{INSTALL_PATH}}"] = "~/.config/opencode"
                $Mappings["{{CONFIG_FILE}}"] = "opencode.config.sample.toml"
                $Mappings["{{RULES_FILE}}"] = "AGENTS.md"
            }
        }

        # Git remote URL은 설치 시 지정하지 않는다. 필요하면 프로젝트의 config.toml에서 직접 설정한다.
        $Mappings["{{GIT_REMOTE_URL}}"] = ""

        Write-Info "Installing vibe-frame-kit for $($Mappings['{{AGENT_NAME}}'])."
        Write-Info "Repository location: $RepoRoot"
        Write-Info "Target path: $InstallBaseDir"

        if (-not (Test-Path $InstallBaseDir)) {
            New-Item -ItemType Directory -Path $InstallBaseDir -Force | Out-Null
            Write-Success "Created target directory."
        }

        $SourceCommonDir = Join-Path $RepoRoot "common"
        if (-not (Test-Path $SourceCommonDir)) {
            throw "Common source folder not found: $SourceCommonDir"
        }

        $SourceWalkthroughSkill = Join-Path $SourceCommonDir "skills\walkthrough\SKILL.md"
        if (-not (Test-Path -LiteralPath $SourceWalkthroughSkill -PathType Leaf)) {
            throw "Required walkthrough skill not found: $SourceWalkthroughSkill"
        }

        # Backup existing directories
        $DirectoriesToCopy = @("agents", "config", "prompts", "templates", "docs", "study")
        foreach ($DirName in $DirectoriesToCopy) {
            $TargetDir = Join-Path $InstallBaseDir $DirName
            if (Test-Path $TargetDir) {
                $BackupDir = Join-Path $InstallBaseDir "$DirName.backup.$Timestamp"
                Safe-BackupDirectory -SourceDir $TargetDir -BackupDir $BackupDir
                Write-Success "Backed up existing $DirName to $BackupDir"
            }
        }

        if (Test-Path $SkillInstallDir) {
            $SkillBackupDir = "$SkillInstallDir.backup.$Timestamp"
            Safe-BackupDirectory -SourceDir $SkillInstallDir -BackupDir $SkillBackupDir
            Write-Success "Backed up existing skills to $SkillBackupDir"
        }

        # Backup existing rules file
        $TargetRulesFile = Join-Path $InstallBaseDir $Mappings["{{RULES_FILE}}"]
        if (Test-Path $TargetRulesFile) {
            try {
                $BackupRulesPath = Join-Path $InstallBaseDir "$($Mappings['{{RULES_FILE}}']).backup.$Timestamp"
                Copy-Item -Path $TargetRulesFile -Destination $BackupRulesPath -Force -ErrorAction Stop
                Write-Success "Backed up existing rules file to $BackupRulesPath"
            }
            catch {
                Write-Host "[WARNING] Failed to backup rules file: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        # Back up and remove the legacy RULES.md file. Its rules are now merged into the main rules file.
        $TargetRulesMdFile = Join-Path $InstallBaseDir "RULES.md"
        if (Test-Path $TargetRulesMdFile) {
            try {
                $BackupRulesMdPath = Join-Path $InstallBaseDir "RULES.md.backup.$Timestamp"
                Copy-Item -Path $TargetRulesMdFile -Destination $BackupRulesMdPath -Force -ErrorAction Stop
                Remove-Item -LiteralPath $TargetRulesMdFile -Force -ErrorAction Stop
                Write-Success "Migrated legacy RULES.md file to $BackupRulesMdPath"
            }
            catch {
                Write-Host "[WARNING] Failed to migrate legacy RULES.md file: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        # Consolidate and copy
        Safe-CopyAndReplaceDirectory -SourceDir $SourceCommonDir -TargetDir $InstallBaseDir -Mappings $Mappings -ExcludedTopLevelDirectories @("skills")
        Safe-CopyAndReplaceDirectory -SourceDir (Join-Path $SourceCommonDir "skills") -TargetDir $SkillInstallDir -Mappings $Mappings
        Write-Success "Framework files deployed and template variables substituted."

        $InstalledWalkthroughSkill = Join-Path $SkillInstallDir "walkthrough\SKILL.md"
        if (-not (Test-Path -LiteralPath $InstalledWalkthroughSkill -PathType Leaf)) {
            throw "Walkthrough skill installation verification failed: $InstalledWalkthroughSkill"
        }
        Write-Success "Verified walkthrough skill installation: $InstalledWalkthroughSkill"

        # Muse (Muse Code CLI): ensure settings.json exists with schema_version = 1 (never overwrite existing MCP settings)
        if ($CurrentTool -eq "muse") {
            $MuseSettingsPath = Join-Path $InstallBaseDir "settings.json"
            if (-not (Test-Path $MuseSettingsPath)) {
                Set-Content -Path $MuseSettingsPath -Value '{ "schema_version": 1 }' -Encoding UTF8
                Write-Success "Created Muse settings.json with schema_version 1."
            }
            else {
                Write-Info "Muse settings.json already exists. Kept as-is (requires schema_version 1)."
            }
        }

        Write-Host ""
        Write-Success "vibe-frame-kit ($($Mappings['{{AGENT_NAME}}']) version) installation complete."
        Write-Host "Installed items:" -ForegroundColor Green
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/$($Mappings['{{RULES_FILE}}'])"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/agents/"
        Write-Host "- $SkillInstallDir"
        Write-Host "  - $InstalledWalkthroughSkill"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/config/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/prompts/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/templates/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/docs/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/study/"

        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " [Action Required: Setup Configuration]" -ForegroundColor Yellow
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " 1. Sample TOML file location:" -ForegroundColor Cyan
        Write-Host "    $($Mappings['{{INSTALL_PATH}}'])/config/$($Mappings['{{CONFIG_FILE}}'])" -ForegroundColor White
        Write-Host " 2. How to activate:" -ForegroundColor Cyan
        Write-Host "    - Copy the sample file above to your 'Project Root Folder'." -ForegroundColor White
        Write-Host "    - Rename the file to 'config.toml' to apply settings to the Agent." -ForegroundColor White
        Write-Host "      (e.g., $($Mappings['{{CONFIG_FILE}}']) -> config.toml)" -ForegroundColor Gray
        Write-Host "    - Fill in remote_repository_url and set auto_commit_push in your project config.toml manually." -ForegroundColor White
        Write-Host "=============================================" -ForegroundColor Yellow
    }
}
catch {
    Write-Host ""
    Write-Fail "Error occurred during installation."
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Quick check:" -ForegroundColor Yellow
    Write-Host "- Check if script was run from the root of vibe-frame-kit."
    Write-Host "- For execution policy issues, run:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\install.ps1"
    Write-Host "- Check write permissions on target directory."
    exit 1
}
