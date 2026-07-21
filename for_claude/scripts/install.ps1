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

function Safe-CopyDirectory {
    param(
        [string]$SourceDir,
        [string]$TargetDir
    )
    
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    
    $Items = Get-ChildItem -Path $SourceDir -Recurse
    foreach ($Item in $Items) {
        $RelativePath = $Item.FullName.Substring($SourceDir.Length + 1)
        if ([string]::IsNullOrEmpty($RelativePath)) { continue }
        $DestinationPath = Join-Path $TargetDir $RelativePath
        
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
                Write-Host "[WARNING] 파일 복사 건너뜀 (사용 중이거나 권한 부족): $RelativePath" -ForegroundColor Yellow
            }
        }
    }
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
                # Ignore backup failure
            }
        }
    }
}

try {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
    $ClaudeDir = Join-Path $HOME ".claude"
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    Write-Info "vibe-frame-kit (Claude 버전) 설치를 시작합니다."
    Write-Info "저장소 위치: $RepoRoot"
    Write-Info "설치 위치: $ClaudeDir"

    if (-not (Test-Path $ClaudeDir)) {
        New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
        Write-Success "~/.claude 폴더를 생성했습니다."
    }
    else {
        Write-Success "~/.claude 폴더를 확인했습니다."
    }

    $SourceAgentsFile = Join-Path $RepoRoot "CLAUDE.md"
    $TargetAgentsFile = Join-Path $ClaudeDir "CLAUDE.md"

    if (-not (Test-Path $SourceAgentsFile)) {
        throw "원본 CLAUDE.md 파일을 찾을 수 없습니다: $SourceAgentsFile"
    }

    if (Test-Path $TargetAgentsFile) {
        $BackupPath = Join-Path $ClaudeDir "CLAUDE.md.backup.$Timestamp"
        try {
            Copy-Item -Path $TargetAgentsFile -Destination $BackupPath -Force -ErrorAction Stop
            Write-Success "기존 ~/.claude/CLAUDE.md 파일을 백업했습니다: $BackupPath"
        }
        catch {
            Write-Host "[WARNING] CLAUDE.md 파일 백업 실패. 계속 진행합니다." -ForegroundColor Yellow
        }
    }

    try {
        Copy-Item -Path $SourceAgentsFile -Destination $TargetAgentsFile -Force -ErrorAction Stop
        Write-Success "CLAUDE.md 파일을 설치했습니다."
    }
    catch {
        Write-Host "[WARNING] CLAUDE.md 파일 설치 실패 (사용 중이거나 권한 부족). 건너뜁니다." -ForegroundColor Yellow
    }

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
        $TargetDir = Join-Path $ClaudeDir $DirectoryName

        if (-not (Test-Path $SourceDir)) {
            throw "원본 폴더를 찾을 수 없습니다: $SourceDir"
        }

        if (Test-Path $TargetDir) {
            $BackupDir = Join-Path $ClaudeDir "$DirectoryName.backup.$Timestamp"
            Safe-BackupDirectory -SourceDir $TargetDir -BackupDir $BackupDir
            Write-Success "기존 ~/.claude/$DirectoryName 폴더를 백업했습니다."
        }

        Safe-CopyDirectory -SourceDir $SourceDir -TargetDir $TargetDir
        Write-Success "$DirectoryName 폴더를 설치했습니다."
    }

    Write-Host ""
    Write-Success "vibe-frame-kit (Claude 버전) 설치가 완료되었습니다."
    Write-Host "설치된 항목:" -ForegroundColor Green
    Write-Host "- ~/.claude/CLAUDE.md"
    Write-Host "- ~/.claude/agents/"
    Write-Host "- ~/.claude/skills/"
    Write-Host "- ~/.claude/config/"
    Write-Host "- ~/.claude/prompts/"
    Write-Host "- ~/.claude/templates/"
    Write-Host "- ~/.claude/docs/"
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
    Write-Host "- ~/.claude 폴더에 파일을 쓸 권한이 있는지 확인하세요."
    exit 1
}

