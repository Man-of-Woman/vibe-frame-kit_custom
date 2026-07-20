param()

$ErrorActionPreference = "Stop"

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

try {
    $AntigravityDir = Join-Path $HOME ".gemini\config"
    Write-Info "vibe-frame-kit (Antigravity 버전) 제거를 시작합니다."
    Write-Info "대상 위치: $AntigravityDir"

    if (-not (Test-Path $AntigravityDir)) {
        Write-Success "제거 대상 폴더가 존재하지 않습니다."
        exit 0
    }

    $TargetFilesAndDirs = @(
        "AGENTS.md",
        "agents",
        "skills",
        "config",
        "prompts",
        "templates",
        "docs"
    )

    foreach ($ItemName in $TargetFilesAndDirs) {
        $TargetPath = Join-Path $AntigravityDir $ItemName
        if (Test-Path $TargetPath) {
            try {
                Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
                Write-Success "$ItemName 을(를) 제거했습니다."
            }
            catch {
                Write-Host "[WARNING] $ItemName 제거 실패 (사용 중이거나 권한 부족). 건너뜁니다." -ForegroundColor Yellow
            }
        }
    }

    # 만약 폴더가 비어 있다면 폴더 자체도 삭제
    $RemainingItems = Get-ChildItem -Path $AntigravityDir -Force -ErrorAction SilentlyContinue
    if ($null -eq $RemainingItems -or $RemainingItems.Count -eq 0) {
        Remove-Item -Path $AntigravityDir -Force
        Write-Success "~/.gemini/config 폴더가 비어 있어 폴더 자체를 제거했습니다."
    }

    Write-Host ""
    Write-Success "vibe-frame-kit 제거가 완료되었습니다."
}
catch {
    Write-Host ""
    Write-Fail "제거 중 문제가 발생했습니다."
    Write-Host "원인: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}
