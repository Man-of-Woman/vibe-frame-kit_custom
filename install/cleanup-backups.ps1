param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("gemini", "claude", "codex")]
    [string[]]$Tool
)

$ErrorActionPreference = "Stop"

function Get-BackupRoots {
    param([string[]]$SelectedTools)

    $roots = [System.Collections.Generic.List[string]]::new()
    $tools = if ($SelectedTools -and $SelectedTools.Count -gt 0) { $SelectedTools } else { @("gemini", "claude", "codex") }

    foreach ($currentTool in $tools) {
        switch ($currentTool) {
            "gemini" {
                $roots.Add((Join-Path $HOME ".gemini\config"))
            }
            "claude" {
                $roots.Add((Join-Path $HOME ".claude"))
            }
            "codex" {
                $roots.Add((Join-Path $HOME ".codex"))
                $roots.Add((Join-Path $HOME ".agents"))
            }
        }
    }

    return $roots | Select-Object -Unique
}

function Test-BackupName {
    param([string]$Name)
    return $Name -match '(^backup\..+|\.backup\..+)$'
}

function Get-ItemSize {
    param([System.IO.FileSystemInfo]$Item)
    if (-not $Item.PSIsContainer) { return $Item.Length }
    return (Get-ChildItem -LiteralPath $Item.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
}

$backupItems = [System.Collections.Generic.List[System.IO.FileSystemInfo]]::new()
foreach ($root in (Get-BackupRoots -SelectedTools $Tool)) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
    foreach ($item in (Get-ChildItem -LiteralPath $root -Force)) {
        if (Test-BackupName -Name $item.Name) {
            $backupItems.Add($item)
        }
    }
}

if ($backupItems.Count -eq 0) {
    Write-Host "백업 파일 또는 폴더를 찾지 못했습니다."
    exit 0
}

Write-Host "발견된 백업 파일/폴더: $($backupItems.Count)개" -ForegroundColor Yellow
Write-Host ""
for ($index = 0; $index -lt $backupItems.Count; $index++) {
    $item = $backupItems[$index]
    $kind = if ($item.PSIsContainer) { "폴더" } else { "파일" }
    $size = [math]::Round(((Get-ItemSize -Item $item) / 1KB), 2)
    Write-Host ("[{0}] {1} | {2} | {3} KB" -f ($index + 1), $kind, $item.FullName, $size)
}

Write-Host ""
Write-Host "위 목록의 백업만 삭제합니다. 취소하려면 아무 값이나 입력하세요." -ForegroundColor Yellow
$confirmation = Read-Host "삭제하려면 DELETE를 정확히 입력하세요"
if ($confirmation -cne "DELETE") {
    Write-Host "삭제를 취소했습니다."
    exit 0
}

$deleted = 0
foreach ($item in $backupItems) {
    # 승인 이후에도 이름 패턴과 대상 유형을 다시 검증합니다.
    if (-not (Test-BackupName -Name $item.Name)) { continue }
    Remove-Item -LiteralPath $item.FullName -Recurse -Force
    $deleted++
    Write-Host "삭제됨: $($item.FullName)" -ForegroundColor Green
}

Write-Host "총 $deleted개 백업 항목을 삭제했습니다." -ForegroundColor Green
