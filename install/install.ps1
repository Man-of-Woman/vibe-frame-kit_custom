param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("gemini", "claude", "codex")]
    [string]$Tool,

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
        if ($RelativePath -eq "RULES.md") {
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
    # Interactive input if tool not specified
    if ([string]::IsNullOrEmpty($Tool)) {
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " Starting unified vibe-frame-kit installation." -ForegroundColor Yellow
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host "Select AI development tool environment to install:" -ForegroundColor Yellow
        Write-Host "1) Gemini (Antigravity)" -ForegroundColor Cyan
        Write-Host "2) Claude (Desktop / Code CLI)" -ForegroundColor Cyan
        Write-Host "3) Codex (Cursor, etc.)" -ForegroundColor Cyan
        $Choice = Read-Host "Select (1-3)"
        switch ($Choice) {
            "1" { $Tool = "gemini" }
            "2" { $Tool = "claude" }
            "3" { $Tool = "codex" }
            default {
                Write-Host "[ERROR] Invalid choice. Aborting installation." -ForegroundColor Red
                exit 1
            }
        }
    }

    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    # Define tool configurations
    $Mappings = @{}
    $InstallBaseDir = ""
    switch ($Tool) {
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

    if ([string]::IsNullOrWhiteSpace($GitUrl)) {
        do {
            $GitUrl = Read-Host "Enter your project Git remote URL (required, e.g. https://github.com/your-org/your-repo.git)"
            if (-not (Test-GitUrlFormat $GitUrl)) {
                Write-Fail "A valid Git remote URL is required. Supported formats: https://..., git@..., ssh://..."
                $GitUrl = ""
            }
        } while ([string]::IsNullOrWhiteSpace($GitUrl))
    }
    elseif (-not (Test-GitUrlFormat $GitUrl)) {
        throw "Invalid Git remote URL format. Supported formats: https://..., git@..., ssh://..."
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
        $BackupRulesPath = Join-Path $InstallBaseDir "$($Mappings['{{RULES_FILE}}']).backup.$Timestamp"
        Copy-Item -Path $TargetRulesFile -Destination $BackupRulesPath -Force
        Write-Success "Backed up existing rules file to $BackupRulesPath"
    }

    # Consolidate and copy
    Safe-CopyAndReplaceDirectory -SourceDir $SourceCommonDir -TargetDir $InstallBaseDir -Mappings $Mappings
    Deploy-IgnoreFiles -RepoRoot $RepoRoot
    Write-Success "Framework files deployed and template variables substituted."

    Write-Host ""
    Write-Success "vibe-frame-kit ($($Mappings['{{AGENT_NAME}}']) version) installation complete."
    Write-Host "Installed items:" -ForegroundColor Green
    Write-Host "- $($Mappings['{{INSTALL_PATH}}'])/$($Mappings['{{RULES_FILE}}'])"
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
    Write-Host " 1. Sample TOML file location:" -ForegroundColor Cyan
    Write-Host "    $($Mappings['{{INSTALL_PATH}}'])/config/$($Mappings['{{CONFIG_FILE}}'])" -ForegroundColor White
    Write-Host " 2. How to activate:" -ForegroundColor Cyan
    Write-Host "    - Copy the sample file above to your 'Project Root Folder'." -ForegroundColor White
    Write-Host "    - Rename the file to 'config.toml' to apply settings to the Agent." -ForegroundColor White
    Write-Host "      (e.g., $($Mappings['{{CONFIG_FILE}}']) -> config.toml)" -ForegroundColor Gray
    Write-Host " 3. Git remote URL injected into sample config:" -ForegroundColor Cyan
    Write-Host "    $GitUrl" -ForegroundColor White
    Write-Host "=============================================" -ForegroundColor Yellow
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
