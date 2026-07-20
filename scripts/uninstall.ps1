param()

$ErrorActionPreference = "Stop"

# 한글 깨짐 방지를 위한 인코딩 설정
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
    $CodexDir = Join-Path $HOME ".codex"

    Write-Info "vibe-frame-kit 제거를 시작합니다."
    Write-Info "대상 위치: $CodexDir"

    if (-not (Test-Path $CodexDir)) {
        Write-Success "~/.codex 폴더가 존재하지 않아 제거할 항목이 없습니다."
        exit 0
    }

    # 삭제할 대상 목록
    $ItemsToRemove = @(
        "AGENTS.md",
        "agents",
        "skills",
        "config",
        "prompts",
        "templates",
        "docs"
    )

    foreach ($ItemName in $ItemsToRemove) {
        $TargetPath = Join-Path $CodexDir $ItemName
        if (Test-Path $TargetPath) {
            Remove-Item -Path $TargetPath -Recurse -Force
            Write-Success "$ItemName 항목을 제거했습니다."
        }
    }

    # ~/.codex 폴더가 비어있으면 폴더 자체도 삭제
    $RemainingItems = Get-ChildItem -Path $CodexDir
    if ($null -eq $RemainingItems) {
        Remove-Item -Path $CodexDir -Force
        Write-Success "비어 있는 ~/.codex 폴더를 제거했습니다."
    } else {
        Write-Info "~/.codex 폴더에 백업 또는 다른 파일이 남아있어 폴더를 유지합니다."
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
