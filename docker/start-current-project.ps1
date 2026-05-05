$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$composeFile = Join-Path $scriptDir 'docker-compose.prod.yml'
$envFile = Join-Path $scriptDir '.env'
$dockerDesktop = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'

if (-not (Test-Path $envFile)) {
  throw "缺少环境文件: $envFile"
}

if (-not (Test-Path $dockerDesktop)) {
  throw "未找到 Docker Desktop: $dockerDesktop"
}

Start-Process -FilePath $dockerDesktop -WindowStyle Hidden | Out-Null

$ready = $false
for ($i = 0; $i -lt 60; $i++) {
  try {
    docker info | Out-Null
    $ready = $true
    break
  } catch {
    Start-Sleep -Seconds 2
  }
}

if (-not $ready) {
  throw 'Docker 守护进程未在预期时间内启动'
}

$containerIds = docker ps -aq
if ($containerIds) {
  docker rm -f $containerIds
}

docker compose -f $composeFile up --build -d --remove-orphans
docker compose -f $composeFile ps
