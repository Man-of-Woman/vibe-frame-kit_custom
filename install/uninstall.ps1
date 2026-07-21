param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("gemini", "claude", "codex")]
    [string]$Tool
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
    # Interactive input if tool not specified
    if ([string]::IsNullOrEmpty($Tool)) {
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " Starting unified vibe-frame-kit uninstallation." -ForegroundColor Yellow
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host "Select AI development tool environment to uninstall:" -ForegroundColor Yellow
        Write-Host "1) Gemini (Antigravity)" -ForegroundColor Cyan
        Write-Host "2) Claude (Desktop / Code CLI)" -ForegroundColor Cyan
        Write-Host "3) Codex (Cursor, etc.)" -ForegroundColor Cyan
        $Choice = Read-Host "Select (1-3)"
        switch ($Choice) {
            "1" { $Tool = "gemini" }
            "2" { $Tool = "claude" }
            "3" { $Tool = "codex" }
            default {
                Write-Host "[ERROR] Invalid choice. Aborting uninstallation." -ForegroundColor Red
                exit 1
            }
        }
    }

    $InstallBaseDir = ""
    $RulesFile = ""
    switch ($Tool) {
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

    Write-Info "Uninstalling vibe-frame-kit for $Tool."
    Write-Info "Target location: $InstallBaseDir"

    if (-not (Test-Path $InstallBaseDir)) {
        Write-Success "Target folder does not exist. Nothing to remove."
        exit 0
    }

    # Items to remove
    $TargetItems = @(
        $RulesFile,
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
    Write-Success "vibe-frame-kit ($Tool version) uninstallation complete."
}
catch {
    Write-Host ""
    Write-Fail "Error occurred during uninstallation."
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}
