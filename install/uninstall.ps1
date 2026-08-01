param(
    [Parameter(Mandatory=$false)]
    [string[]]$Tool
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
    $ManagedSkillNames = @(
        "ai-agent-workflow-builder", "api-service-builder", "backlog-planning",
        "context-map-builder", "debugging-coach", "domain-model-builder",
        "function-breakdown", "mvp-planning", "project-structure-builder",
        "readme-report-writer", "refactoring-coach", "requirements-definition",
        "security-checker", "test-planning-coach", "walkthrough"
    )

    # Scan which tools have vibe-frame-kit installed
    $InstalledTools = @()
    if (Test-Path (Join-Path $HOME ".gemini\config\AGENTS.md")) { $InstalledTools += "gemini" }
    if (Test-Path (Join-Path $HOME ".claude\CLAUDE.md")) { $InstalledTools += "claude" }
    if (Test-Path (Join-Path $HOME ".codex\AGENTS.md")) { $InstalledTools += "codex" }

    $SelectedTools = @()
    if ($null -eq $Tool -or $Tool.Count -eq 0) {
        if ($InstalledTools.Count -eq 0) {
            Write-Success "vibe-frame-kit is not installed in any environment. Nothing to remove."
            exit 0
        }
        elseif ($InstalledTools.Count -eq 1) {
            $SingleTool = $InstalledTools[0]
            $Confirm = ""
            while ($Confirm -ne "Y" -and $Confirm -ne "N") {
                $Confirm = (Read-Host "vibe-frame-kit is installed in [$SingleTool]. Do you want to uninstall it? (Y/N)").ToUpper()
            }
            if ($Confirm -eq "Y") {
                $SelectedTools = @($SingleTool)
            } else {
                Write-Info "Uninstallation aborted."
                exit 0
            }
        }
        else {
            # Multiple tools are installed, show checklist
            $Options = [System.Collections.Generic.List[hashtable]]::new()
            foreach ($T in $InstalledTools) {
                $Name = switch ($T) {
                    "gemini" { "Gemini (Antigravity)" }
                    "claude" { "Claude (Desktop / Code CLI)" }
                    "codex" { "Codex (Cursor, etc.)" }
                }
                $Options.Add(@{ Name = $Name; Value = $T; Selected = $false })
            }

            while ($true) {
                Show-MultiSelectMenu -Title "Select AI development tool environment(s) to uninstall" -Options $Options
                $SelectedTools = $Options | Where-Object { $_.Selected } | ForEach-Object { $_.Value }
                if ($SelectedTools.Count -gt 0) {
                    break
                } else {
                    Write-Host "[ERROR] You must select at least one tool." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
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

    foreach ($CurrentTool in $SelectedTools) {
        $InstallBaseDir = ""
        $SkillInstallDir = ""
        $RulesFile = ""
        switch ($CurrentTool) {
            "gemini" {
                $InstallBaseDir = Join-Path $HOME ".gemini\config"
                $SkillInstallDir = Join-Path $InstallBaseDir "skills"
                $RulesFile = "AGENTS.md"
            }
            "claude" {
                $InstallBaseDir = Join-Path $HOME ".claude"
                $SkillInstallDir = Join-Path $InstallBaseDir "skills"
                $RulesFile = "CLAUDE.md"
            }
            "codex" {
                $InstallBaseDir = Join-Path $HOME ".codex"
                $SkillInstallDir = Join-Path $HOME ".agents\skills"
                $RulesFile = "AGENTS.md"
            }
        }

        Write-Info "Uninstalling vibe-frame-kit for $CurrentTool."
        Write-Info "Target location: $InstallBaseDir"

        if (-not (Test-Path $InstallBaseDir)) {
            Write-Success "Target folder does not exist. Nothing to remove."
            continue
        }

        # Items to remove
        $TargetItems = @(
            $RulesFile,
            # 이전 버전에서 설치한 통합 전 RULES.md도 함께 정리합니다.
            "RULES.md",
            "agents",
            "config",
            "prompts",
            "templates",
            "docs",
            "study"
        )

        foreach ($ItemName in $TargetItems) {
            $TargetPath = Join-Path $InstallBaseDir $ItemName
            if (Test-Path $TargetPath) {
                try {
                    Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
                    Write-Success "Removed $ItemName."
                }
                catch {
                    Write-Host "[WARNING] Failed to remove $ItemName. Skipping." -ForegroundColor Yellow
                }
            }
        }

        $SkillRoots = @($SkillInstallDir)
        if ($CurrentTool -eq "codex") {
            # 이전 버전의 Codex 설치 경로도 관리된 스킬만 정리합니다.
            $SkillRoots += (Join-Path $InstallBaseDir "skills")
        }
        foreach ($SkillRoot in ($SkillRoots | Select-Object -Unique)) {
            foreach ($SkillName in $ManagedSkillNames) {
                $SkillPath = Join-Path $SkillRoot $SkillName
                if (Test-Path $SkillPath) {
                    try {
                        Remove-Item -Path $SkillPath -Recurse -Force -ErrorAction Stop
                        Write-Success "Removed skill $SkillName from $SkillRoot."
                    }
                    catch {
                        Write-Host "[WARNING] Failed to remove skill $SkillName from $SkillRoot. Skipping." -ForegroundColor Yellow
                    }
                }
            }
        }

        # Clean up empty directory if no non-backup files remain
        $RemainingItems = Get-ChildItem -Path $InstallBaseDir -Force -ErrorAction SilentlyContinue
        if ($null -eq $RemainingItems -or $RemainingItems.Count -eq 0) {
            Remove-Item -Path $InstallBaseDir -Force
            Write-Success "Removed empty folder: $InstallBaseDir"
        } else {
            Write-Info "Other user files exist. Kept directory: $InstallBaseDir"
        }

        Write-Host ""
        Write-Success "vibe-frame-kit ($CurrentTool version) uninstallation complete."
    }
}
catch {
    Write-Host ""
    Write-Fail "Error occurred during uninstallation."
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}
