$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$composeFile = Join-Path $scriptDir 'docker-compose.prod.yml'
$envFile = Join-Path $scriptDir '.env'
$dockerDesktop = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'

if (-not (Test-Path $envFile)) {
  throw "Missing env file: $envFile"
}

if (-not (Test-Path $dockerDesktop)) {
  throw "Docker Desktop not found: $dockerDesktop"
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
  throw 'Docker daemon did not become ready in time'
}

$containerIds = docker ps -aq
if ($containerIds) {
  docker rm -f $containerIds
}

docker compose -f $composeFile up --build -d --remove-orphans
docker compose -f $composeFile ps
