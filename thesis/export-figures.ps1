[CmdletBinding()]
param(
  [string]$MarkdownPath,
  [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($MarkdownPath)) {
  $MarkdownPath = Join-Path $scriptRoot '图表素材.md'
}
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
  $OutputDirectory = Join-Path $scriptRoot '导出图表_svg'
}

$chromeCandidates = @((
  'C:\Program Files\Google\Chrome\Application\chrome.exe',
  'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
  (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe'),
  (Join-Path $env:PROGRAMFILES 'Microsoft\Edge\Application\msedge.exe')
) | Where-Object { $_ -and (Test-Path $_) })

if (-not $chromeCandidates -or $chromeCandidates.Count -eq 0) {
  throw '未找到可用的本地 Chrome/Edge 浏览器，无法驱动 Mermaid CLI 导出 SVG。'
}

$browserExecutable = $chromeCandidates[0]

function Normalize-Title {
  param([string]$Title)

  $value = $Title.Trim()
  $value = $value -replace '\s+', '_'
  $value = $value -replace '[<>:"/\\|?*]', ''
  return $value
}

function Get-MermaidFigureBlocks {
  param([string]$Path)

  $raw = Get-Content -Raw -Encoding utf8 $Path
  $lines = ($raw -replace "`r`n", "`n") -split "`n"

  $figures = New-Object System.Collections.Generic.List[object]
  $currentTitle = $null
  $currentFigure = $null
  $capture = $false
  $buffer = New-Object System.Collections.Generic.List[string]

  foreach ($line in $lines) {
    if ($line -match '^##\s+(图\d+-\d+\s+.+)$') {
      $currentTitle = $matches[1].Trim()
      continue
    }

    if ($line -match '^```mermaid\s*$') {
      $capture = $true
      $buffer.Clear()
      continue
    }

    if ($capture -and $line -match '^```\s*$') {
      $capture = $false
      if ($currentTitle) {
        $figures.Add([pscustomobject]@{
          Title = $currentTitle
          Mermaid = ($buffer -join "`r`n")
        })
        $currentTitle = $null
      }
      continue
    }

    if ($capture) {
      $buffer.Add($line)
    }
  }

  return $figures
}

if (-not (Test-Path $MarkdownPath)) {
  throw "Markdown 文件不存在: $MarkdownPath"
}

$allFigures = Get-MermaidFigureBlocks -Path $MarkdownPath
$expectedTitles = @(
  '图2-1 系统用例图',
  '图3-1 系统总体功能模块结构图',
  '图3-2 系统总体架构图',
  '图3-3 用户认证与用户中心模块时序图',
  '图3-4 照片库模块活动图',
  '图3-5 相册模块流程图',
  '图3-6 共享协作模块时序图',
  '图3-7 检索与地图模块流程图',
  '图3-8 数据库E-R图',
  '图3-9 数据表关系图'
)

$selectedFigures = foreach ($title in $expectedTitles) {
  $match = $allFigures | Where-Object { $_.Title -eq $title } | Select-Object -First 1
  if (-not $match) {
    throw "未在图表素材中找到目标图表: $title"
  }
  $match
}

if (-not (Get-Command npx.cmd -ErrorAction SilentlyContinue)) {
  throw '未找到 npx.cmd，无法调用 Mermaid CLI。'
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
Get-ChildItem -Path $OutputDirectory -Filter '*.svg' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $OutputDirectory '图表文件清单.txt') -Force -ErrorAction SilentlyContinue
$tempDirectory = Join-Path $OutputDirectory '.tmp'
New-Item -ItemType Directory -Force -Path $tempDirectory | Out-Null
$puppeteerConfigPath = Join-Path $tempDirectory 'puppeteer.json'

try {
  $puppeteerConfig = [ordered]@{
    executablePath = $browserExecutable
    args = @('--no-sandbox', '--disable-setuid-sandbox')
  } | ConvertTo-Json -Compress
  Set-Content -Path $puppeteerConfigPath -Value $puppeteerConfig -Encoding ascii

  $index = 1
  $manifestLines = New-Object System.Collections.Generic.List[string]
  $manifestLines.Add('图表文件清单')
  $manifestLines.Add('')

  foreach ($figure in $selectedFigures) {
    $prefix = '{0:d2}' -f $index
    $fileBaseName = '{0}_{1}' -f $prefix, (Normalize-Title -Title $figure.Title)
    $tempPath = Join-Path $tempDirectory ($fileBaseName + '.mmd')
    $outputPath = Join-Path $OutputDirectory ($fileBaseName + '.svg')

    Set-Content -Path $tempPath -Value $figure.Mermaid -Encoding utf8

    $arguments = @(
      '-y',
      '-p',
      '@mermaid-js/mermaid-cli',
      'mmdc',
      '-i',
      $tempPath,
      '-o',
      $outputPath,
      '--puppeteerConfigFile',
      $puppeteerConfigPath,
      '-b',
      'white'
    )

    & npx.cmd @arguments
    if ($LASTEXITCODE -ne 0) {
      throw "Mermaid CLI 导出失败: $($figure.Title)"
    }

    if (-not (Test-Path $outputPath)) {
      throw "未生成输出文件: $outputPath"
    }

    $manifestLines.Add(('{0} -> {1}' -f (Split-Path -Leaf $outputPath), $figure.Title))
    $index++
  }

  $manifestPath = Join-Path $OutputDirectory '图表文件清单.txt'
  Set-Content -Path $manifestPath -Value $manifestLines -Encoding utf8
}
finally {
  if (Test-Path $tempDirectory) {
    Remove-Item -Recurse -Force $tempDirectory
  }
}

Write-Output ("FIGURES_EXPORTED: {0}" -f $OutputDirectory)

