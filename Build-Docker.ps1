if (-not $(Get-Module -ListAvailable -Name PSToml)) {
  Install-Module PSToml
}

function Get-NextTag($svcName, $svcDir, $type) {
  $codeVersion = (Get-Content "./$svcDir/Cargo.toml" | ConvertFrom-Toml).package.version.Trim()
  $dockerTag = (docker images "wilt/$svcName" --format json | ConvertFrom-Json | Sort-Object -Property CreatedAt -Descending)[0].Tag
  $dockerVersion = ($dockerTag -Split '-')[0]

  if ($codeVersion -ne (($dockerVersion -Split '\.')[0..2] -join '.')) {
    $newVersion = "0"
  } else {
    $imgVersion = ($dockerVersion -Split '\.')[3]
    $newVersion = ($null -eq $imgVersion -or "" -eq $imgVersion) ? "0" : "$([int]$imgVersion + 1)"
  }

  return ($null -eq $type) ? "$codeVersion.$newVersion" : "$codeVersion.$newVersion-$type"
}

docker build -t wilt/scripty-stt:$(Get-NextTag scripty-stt stt-service cuda) -f .\scripty-stt-cuda.dockerfile .

# Assume we need to rerun sqlx
docker run --name db-temp -p "5432:5432" -e POSTGRES_USER=scripty -e POSTGRES_PASSWORD=scripty -d --rm postgres
docker build -t wilt/scripty:$(Get-NextTag scripty scripty) --network host -f .\scripty.dockerfile .
docker stop db-temp

# docker compose up -d
