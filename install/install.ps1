param(
    [Parameter(Mandatory=$false)]
    [string[]]$Tool,

    [Parameter(Mandatory=$false)]
    [string]$GitUrl,
    
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

function Test-GitUrlFormat {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    return $Value -match '^(https://|git@|ssh://).+'
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
        [hashtable]$Mappings
    )
    
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    
    $Items = Get-ChildItem -Path $SourceDir -Recurse
    foreach ($Item in $Items) {
        $RelativePath = $Item.FullName.Substring($SourceDir.Length + 1)
        if ([string]::IsNullOrEmpty($RelativePath)) { continue }
        
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
            if ($T -notin @("gemini", "claude", "codex")) {
                throw "Invalid tool: $T. Valid tools are: gemini, claude, codex"
            }
            $SelectedTools += $T
        }
    }

    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    if ([string]::IsNullOrWhiteSpace($GitUrl)) {
        $GitUrl = Read-Host "Enter your project Git remote URL (Optional, press Enter to skip)"
        if (-not [string]::IsNullOrWhiteSpace($GitUrl) -and -not (Test-GitUrlFormat $GitUrl)) {
            do {
                Write-Fail "Invalid Git URL format. Enter a valid URL or press Enter to skip."
                $GitUrl = Read-Host "Enter your project Git remote URL (Optional)"
            } while (-not [string]::IsNullOrWhiteSpace($GitUrl) -and -not (Test-GitUrlFormat $GitUrl))
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($GitUrl) -and -not (Test-GitUrlFormat $GitUrl)) {
        throw "Invalid Git remote URL format. Supported formats: https://..., git@..., ssh://..."
    }

    # Project folder setup logic
    $SpecifyFolder = ""
    while ($SpecifyFolder -ne "Y" -and $SpecifyFolder -ne "N") {
        $SpecifyFolder = (Read-Host "Do you want to specify a project folder to automatically deploy config.toml? (Y/N)").ToUpper()
    }

    $ProjFolder = ""
    $ProjName = ""
    $DeployConfigDirectly = $false

    if ($SpecifyFolder -eq "Y") {
        while ([string]::IsNullOrWhiteSpace($ProjFolder)) {
            $ProjFolder = Read-Host "Enter the project folder path (e.g. C:\workspace\my-project)"
        }
        
        # Resolve path to absolute
        $ProjFolder = [System.IO.Path]::GetFullPath($ProjFolder)

        if (-not (Test-Path $ProjFolder)) {
            New-Item -ItemType Directory -Path $ProjFolder -Force | Out-Null
            Write-Success "Created project folder: $ProjFolder"
        }

        $DefaultProjName = Split-Path $ProjFolder -Leaf
        $ProjName = Read-Host "Enter the project name [Default: $DefaultProjName]"
        if ([string]::IsNullOrWhiteSpace($ProjName)) {
            $ProjName = $DefaultProjName
        }
        $DeployConfigDirectly = $true
        
        # Git remote URL과 프로젝트 폴더 동기화
        if (-not [string]::IsNullOrWhiteSpace($GitUrl)) {
            Write-Info "Synchronizing project folder with Git remote URL: $GitUrl"
            if (Test-Path (Join-Path $ProjFolder ".git")) {
                Write-Info "Existing Git repository found. Updating remote URL."
                git -C $ProjFolder remote set-url origin $GitUrl 2>$null
                if ($LASTEXITCODE -ne 0) {
                    git -C $ProjFolder remote add origin $GitUrl 2>$null
                }
                Write-Info "Fetching from remote..."
                git -C $ProjFolder fetch --all
            } else {
                $IsEmpty = (Get-ChildItem -Path $ProjFolder -Force | Measure-Object).Count -eq 0
                if ($IsEmpty) {
                    Write-Info "Folder is empty. Performing Git clone..."
                    git clone $GitUrl $ProjFolder
                    if ($LASTEXITCODE -ne 0) {
                        Write-Fail "Git clone failed. Proceeding with configuration deployment anyway."
                    } else {
                        Write-Success "Successfully cloned repository."
                    }
                } else {
                    Write-Info "Folder is not empty. Initializing Git repository locally..."
                    git -C $ProjFolder init
                    git -C $ProjFolder remote add origin $GitUrl 2>$null
                    git -C $ProjFolder fetch origin
                    Write-Success "Initialized Git and added remote."
                }
            }
        }
    }

    # Deploy ignore files at repository root once
    Deploy-IgnoreFiles -RepoRoot $RepoRoot

    foreach ($CurrentTool in $SelectedTools) {
        # Define tool configurations
        $Mappings = @{}
        $InstallBaseDir = ""
        switch ($CurrentTool) {
            "gemini" {
                $InstallBaseDir = Join-Path $HOME ".gemini\config"
                $Mappings["{{AGENT_NAME}}"] = "Gemini"
                $Mappings["{{INSTALL_PATH}}"] = "~/.gemini/config"
                $Mappings["{{CONFIG_FILE}}"] = "gemini.config.sample.toml"
                $Mappings["{{RULES_FILE}}"] = "AGENTS.md"
            }
            "claude" {
                $InstallBaseDir = Join-Path $HOME ".claude"
                $Mappings["{{AGENT_NAME}}"] = "Claude"
                $Mappings["{{INSTALL_PATH}}"] = "~/.claude"
                $Mappings["{{CONFIG_FILE}}"] = "claude.config.sample.toml"
                $Mappings["{{RULES_FILE}}"] = "CLAUDE.md"
            }
            "codex" {
                $InstallBaseDir = Join-Path $HOME ".codex"
                $Mappings["{{AGENT_NAME}}"] = "Codex"
                $Mappings["{{INSTALL_PATH}}"] = "~/.codex"
                $Mappings["{{CONFIG_FILE}}"] = "codex.config.sample.toml"
                $Mappings["{{RULES_FILE}}"] = "AGENTS.md"
            }
        }

        $Mappings["{{GIT_REMOTE_URL}}"] = $GitUrl

        Write-Info "Installing vibe-frame-kit for $($Mappings['{{AGENT_NAME}}'])."
        Write-Info "Repository location: $RepoRoot"
        Write-Info "Target path: $InstallBaseDir"
        Write-Info "Project Git remote URL: $GitUrl"

        if (-not (Test-Path $InstallBaseDir)) {
            New-Item -ItemType Directory -Path $InstallBaseDir -Force | Out-Null
            Write-Success "Created target directory."
        }

        $SourceCommonDir = Join-Path $RepoRoot "common"
        if (-not (Test-Path $SourceCommonDir)) {
            throw "Common source folder not found: $SourceCommonDir"
        }

        # Backup existing directories
        $DirectoriesToCopy = @("agents", "skills", "config", "prompts", "templates", "docs", "study")
        foreach ($DirName in $DirectoriesToCopy) {
            $TargetDir = Join-Path $InstallBaseDir $DirName
            if (Test-Path $TargetDir) {
                $BackupDir = Join-Path $InstallBaseDir "$DirName.backup.$Timestamp"
                Safe-BackupDirectory -SourceDir $TargetDir -BackupDir $BackupDir
                Write-Success "Backed up existing $DirName to $BackupDir"
            }
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

        # Backup existing RULES.md file
        $TargetRulesMdFile = Join-Path $InstallBaseDir "RULES.md"
        if (Test-Path $TargetRulesMdFile) {
            try {
                $BackupRulesMdPath = Join-Path $InstallBaseDir "RULES.md.backup.$Timestamp"
                Copy-Item -Path $TargetRulesMdFile -Destination $BackupRulesMdPath -Force -ErrorAction Stop
                Write-Success "Backed up existing RULES.md file to $BackupRulesMdPath"
            }
            catch {
                Write-Host "[WARNING] Failed to backup RULES.md file: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        # Consolidate and copy
        Safe-CopyAndReplaceDirectory -SourceDir $SourceCommonDir -TargetDir $InstallBaseDir -Mappings $Mappings
        Write-Success "Framework files deployed and template variables substituted."

        # Generate config.toml in project folder if requested
        if ($DeployConfigDirectly) {
            $SampleConfigFile = Join-Path $SourceCommonDir "config\common.config.sample.toml"
            $TargetConfigPath = Join-Path $ProjFolder "config.toml"
            if (Test-Path $SampleConfigFile) {
                $ConfigContent = Get-Content -Path $SampleConfigFile -Raw -Encoding UTF8
                
                # Substitutions
                $ConfigContent = $ConfigContent.Replace('name = "my-ai-service-project"', "name = `"$ProjName`"")
                $ConfigContent = $ConfigContent.Replace("{{AGENT_NAME}}", $Mappings["{{AGENT_NAME}}"])
                $ConfigContent = $ConfigContent.Replace("{{INSTALL_PATH}}", $Mappings["{{INSTALL_PATH}}"])
                $ConfigContent = $ConfigContent.Replace("{{CONFIG_FILE}}", "config.toml")
                $ConfigContent = $ConfigContent.Replace("{{RULES_FILE}}", $Mappings["{{RULES_FILE}}"])
                $ConfigContent = $ConfigContent.Replace("{{GIT_REMOTE_URL}}", $GitUrl)
                if ([string]::IsNullOrWhiteSpace($GitUrl)) {
                    $ConfigContent = $ConfigContent.Replace("auto_commit_push = true", "auto_commit_push = false")
                }

                Set-Content -Path $TargetConfigPath -Value $ConfigContent -Encoding UTF8
                Write-Success "Automatically created config.toml in project folder: $TargetConfigPath"
            } else {
                Write-Fail "Sample config file not found, failed to auto-create config.toml."
            }
        }

        Write-Host ""
        Write-Success "vibe-frame-kit ($($Mappings['{{AGENT_NAME}}']) version) installation complete."
        Write-Host "Installed items:" -ForegroundColor Green
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/$($Mappings['{{RULES_FILE}}'])"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/RULES.md"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/agents/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/skills/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/config/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/prompts/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/templates/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/docs/"
        Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/study/"

        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " [Action Required: Setup Configuration]" -ForegroundColor Yellow
        Write-Host "=============================================" -ForegroundColor Yellow
        if ($DeployConfigDirectly) {
            Write-Host " 1. Configuration file successfully created:" -ForegroundColor Cyan
            Write-Host "    $ProjFolder\config.toml" -ForegroundColor White
            Write-Host " 2. Status:" -ForegroundColor Cyan
            Write-Host "    No further action needed! The Agent will now read settings from this file." -ForegroundColor White
        } else {
            Write-Host " 1. Sample TOML file location:" -ForegroundColor Cyan
            Write-Host "    $($Mappings['{{INSTALL_PATH}}'])/config/$($Mappings['{{CONFIG_FILE}}'])" -ForegroundColor White
            Write-Host " 2. How to activate:" -ForegroundColor Cyan
            Write-Host "    - Copy the sample file above to your 'Project Root Folder'." -ForegroundColor White
            Write-Host "    - Rename the file to 'config.toml' to apply settings to the Agent." -ForegroundColor White
            Write-Host "      (e.g., $($Mappings['{{CONFIG_FILE}}']) -> config.toml)" -ForegroundColor Gray
        }
        Write-Host " 3. Git remote URL injected:" -ForegroundColor Cyan
        Write-Host "    $GitUrl" -ForegroundColor White
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
