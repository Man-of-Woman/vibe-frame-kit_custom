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
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
    $CodexDir = Join-Path $HOME ".codex"
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    Write-Info "vibe-frame-kit 설치를 시작합니다."
    Write-Info "저장소 위치: $RepoRoot"
    Write-Info "설치 위치: $CodexDir"

    if (-not (Test-Path $CodexDir)) {
        New-Item -ItemType Directory -Path $CodexDir | Out-Null
        Write-Success "~/.codex 폴더를 생성했습니다."
    }
    else {
        Write-Success "~/.codex 폴더를 확인했습니다."
    }

    $SourceAgentsFile = Join-Path $RepoRoot "AGENTS.md"
    $TargetAgentsFile = Join-Path $CodexDir "AGENTS.md"

    if (-not (Test-Path $SourceAgentsFile)) {
        throw "원본 AGENTS.md 파일을 찾을 수 없습니다: $SourceAgentsFile"
    }

    if (Test-Path $TargetAgentsFile) {
        $BackupPath = Join-Path $CodexDir "AGENTS.md.backup.$Timestamp"
        Copy-Item -Path $TargetAgentsFile -Destination $BackupPath -Force
        Write-Success "기존 ~/.codex/AGENTS.md 파일을 백업했습니다: $BackupPath"
    }

    Copy-Item -Path $SourceAgentsFile -Destination $TargetAgentsFile -Force
    Write-Success "AGENTS.md 파일을 설치했습니다."

    $DirectoriesToCopy = @(
        "agents",
        "skills",
        "config",
        "prompts",
        "templates",
        "docs"
    )

    foreach ($DirectoryName in $DirectoriesToCopy) {
        $SourceDir = Join-Path $RepoRoot $DirectoryName
        $TargetDir = Join-Path $CodexDir $DirectoryName

        if (-not (Test-Path $SourceDir)) {
            throw "원본 폴더를 찾을 수 없습니다: $SourceDir"
        }

        if (Test-Path $TargetDir) {
            $BackupDir = Join-Path $CodexDir "$DirectoryName.backup.$Timestamp"
            Copy-Item -Path $TargetDir -Destination $BackupDir -Recurse -Force
            Write-Success "기존 ~/.codex/$DirectoryName 폴더를 백업했습니다: $BackupDir"
        }

        if (-not (Test-Path $TargetDir)) {
            New-Item -ItemType Directory -Path $TargetDir | Out-Null
        }

        Copy-Item -Path (Join-Path $SourceDir "*") -Destination $TargetDir -Recurse -Force
        Write-Success "$DirectoryName 폴더를 설치했습니다."
    }

    Write-Host ""
    Write-Success "vibe-frame-kit 설치가 완료되었습니다."
    Write-Host "설치된 항목:" -ForegroundColor Green
    Write-Host "- ~/.codex/AGENTS.md"
    Write-Host "- ~/.codex/agents/"
    Write-Host "- ~/.codex/skills/"
    Write-Host "- ~/.codex/config/"
    Write-Host "- ~/.codex/prompts/"
    Write-Host "- ~/.codex/templates/"
    Write-Host "- ~/.codex/docs/"
}
catch {
    Write-Host ""
    Write-Fail "설치 중 문제가 발생했습니다."
    Write-Host "원인: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "확인해볼 내용:" -ForegroundColor Yellow
    Write-Host "- 이 스크립트를 vibe-frame-kit 저장소 안에서 실행했는지 확인하세요."
    Write-Host "- PowerShell 실행 권한 문제라면 다음 명령을 참고하세요:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1"
    Write-Host "- ~/.codex 폴더에 파일을 쓸 권한이 있는지 확인하세요."
    exit 1
}
