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
    # Scan which tools have vibe-frame-kit installed
    $InstalledTools = @()
    if (Test-Path (Join-Path $HOME ".gemini\config\RULES.md")) { $InstalledTools += "gemini" }
    if (Test-Path (Join-Path $HOME ".claude\RULES.md")) { $InstalledTools += "claude" }
    if (Test-Path (Join-Path $HOME ".codex\RULES.md")) { $InstalledTools += "codex" }

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
            $Options = @()
            foreach ($T in $InstalledTools) {
                $Name = switch ($T) {
                    "gemini" { "Gemini (Antigravity)" }
                    "claude" { "Claude (Desktop / Code CLI)" }
                    "codex" { "Codex (Cursor, etc.)" }
                }
                $Options += @{ Name = $Name; Value = $T; Selected = $false }
            }

            while ($true) {
                Clear-Host
                Write-Host "=============================================" -ForegroundColor Yellow
                Write-Host " Starting unified vibe-frame-kit uninstallation." -ForegroundColor Yellow
                Write-Host "=============================================" -ForegroundColor Yellow
                Write-Host "Select AI development tool environment(s) to uninstall:" -ForegroundColor Yellow
                Write-Host " (Toggle items by typing numbers, e.g. 1 or 1,2. Press Enter to confirm)" -ForegroundColor Gray
                Write-Host ""
                
                for ($i = 0; $i -lt $Options.Count; $i++) {
                    $Check = if ($Options[$i].Selected) { "[X]" } else { "[ ]" }
                    $Color = if ($Options[$i].Selected) { "Green" } else { "Cyan" }
                    Write-Host "  $Check $($i+1)) $($Options[$i].Name)" -ForegroundColor $Color
                }
                Write-Host ""
                
                $Input = Read-Host "Select (1-$($Options.Count), or press Enter to confirm)"
                if ([string]::IsNullOrWhiteSpace($Input)) {
                    $SelectedTools = $Options | Where-Object { $_.Selected } | ForEach-Object { $_.Value }
                    if ($SelectedTools.Count -gt 0) {
                        break
                    } else {
                        Write-Host "[ERROR] You must select at least one tool." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                        continue
                    }
                }

                $Indices = $Input -split ',' | ForEach-Object { $_.Trim() }
                foreach ($IdxStr in $Indices) {
                    if ($IdxStr -match "^[1-$($Options.Count)]$") {
                        $Idx = [int]$IdxStr - 1
                        $Options[$Idx].Selected = -not $Options[$Idx].Selected
                    } else {
                        Write-Host "[ERROR] Invalid input: $IdxStr. Use numbers 1-$($Options.Count)." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
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
        $RulesFile = ""
        switch ($CurrentTool) {
            "gemini" {
                $InstallBaseDir = Join-Path $HOME ".gemini\config"
                $RulesFile = "AGENTS.md"
            }
            "claude" {
                $InstallBaseDir = Join-Path $HOME ".claude"
                $RulesFile = "CLAUDE.md"
            }
            "codex" {
                $InstallBaseDir = Join-Path $HOME ".codex"
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
            "RULES.md",
            "agents",
            "skills",
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
