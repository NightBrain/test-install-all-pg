# =============================================================
# Windows Development Tools Installer (Latest Versions)
# =============================================================
# รายการโปรแกรมที่ติดตั้ง:
#   - Git                  (latest)
#   - PHP 8.x              (latest stable)
#   - Composer             (latest)
#   - Laravel Installer    (latest via Composer)
#   - Node.js              (latest LTS)
#   - Bun                  (latest)
#   - Docker Desktop       (latest)
#   - DBeaver Community    (latest)
#   - Antigravity          (latest via npm)
# =============================================================
# วิธีใช้งาน: เปิด PowerShell ในฐานะ Administrator แล้วรัน:
#   Set-ExecutionPolicy Bypass -Scope Process -Force
#   .\install.ps1
# =============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Write-Header  { param([string]$T); Write-Host "`n============================================================" -ForegroundColor Cyan; Write-Host " $T" -ForegroundColor Cyan; Write-Host "============================================================" -ForegroundColor Cyan }
function Write-Step    { param([string]$T); Write-Host "[*] $T" -ForegroundColor Yellow }
function Write-Success { param([string]$T); Write-Host "[✓] $T" -ForegroundColor Green }
function Write-Fail    { param([string]$T); Write-Host "[✗] $T" -ForegroundColor Red }
function Write-Info    { param([string]$T); Write-Host "    $T" -ForegroundColor Gray }

function Download-File {
    param([string]$Url, [string]$Destination, [string]$Name)
    Write-Step "กำลังดาวน์โหลด $Name ..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
    Write-Success "ดาวน์โหลด $Name สำเร็จ"
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Get-GithubLatest {
    param([string]$Repo)
    $api = "https://api.github.com/repos/$Repo/releases/latest"
    $rel = Invoke-RestMethod -Uri $api -UseBasicParsing
    return $rel.tag_name -replace '^v',''
}

$TempDir = "$env:TEMP\DevInstaller"
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Header "Windows Development Tools Installer (Latest)"

# ============================================================
# 1. Git (latest)
# ============================================================
Write-Header "1. ติดตั้ง Git (latest)"
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Info "Git ติดตั้งแล้ว: $(git --version)"
} else {
    Write-Step "กำลังดึงเวอร์ชันล่าสุดของ Git..."
    $GitVersion = Get-GithubLatest "git-for-windows/git"
    $GitVersion = $GitVersion -replace '\.windows\.\d+',''
    $GitInstaller = "$TempDir\Git-$GitVersion-64-bit.exe"
    $GitUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-$GitVersion-64-bit.exe"
    Download-File -Url $GitUrl -Destination $GitInstaller -Name "Git"
    Start-Process -FilePath $GitInstaller -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=icons,ext\reg\shellhere,assoc,assoc_sh" -Wait
    Refresh-Path
    Write-Success "ติดตั้ง Git สำเร็จ"
}

# ============================================================
# 2. PHP 8 (latest stable NTS)
# ============================================================
Write-Header "2. ติดตั้ง PHP 8 (latest stable)"
$PhpDir = "C:\php"
if (Test-Path "$PhpDir\php.exe") {
    Write-Info "PHP ติดตั้งแล้ว: $(& "$PhpDir\php.exe" --version | Select-Object -First 1)"
} else {
    Write-Step "กำลังดึงเวอร์ชันล่าสุดของ PHP..."
    # ดึงหน้า releases เพื่อหาเวอร์ชันล่าสุด
    $PhpPage = Invoke-WebRequest -Uri "https://windows.php.net/download/" -UseBasicParsing
    $PhpMatch = [regex]::Match($PhpPage.Content, 'php-(8\.\d+\.\d+)-nts-Win32-vs17-x64\.zip')
    $PhpVersion = $PhpMatch.Groups[1].Value
    $PhpZip = "$TempDir\php-latest.zip"
    $PhpUrl  = "https://windows.php.net/downloads/releases/php-$PhpVersion-nts-Win32-vs17-x64.zip"
    Download-File -Url $PhpUrl -Destination $PhpZip -Name "PHP $PhpVersion"
    if (Test-Path $PhpDir) { Remove-Item $PhpDir -Recurse -Force }
    New-Item -ItemType Directory -Path $PhpDir | Out-Null
    Expand-Archive -Path $PhpZip -DestinationPath $PhpDir -Force
    if (Test-Path "$PhpDir\php.ini-development") {
        Copy-Item "$PhpDir\php.ini-development" "$PhpDir\php.ini"
        $phpini = Get-Content "$PhpDir\php.ini"
        $phpini = $phpini -replace ";extension=curl",      "extension=curl"
        $phpini = $phpini -replace ";extension=fileinfo",  "extension=fileinfo"
        $phpini = $phpini -replace ";extension=mbstring",  "extension=mbstring"
        $phpini = $phpini -replace ";extension=openssl",   "extension=openssl"
        $phpini = $phpini -replace ";extension=pdo_mysql", "extension=pdo_mysql"
        $phpini = $phpini -replace ";extension=pdo_pgsql", "extension=pdo_pgsql"
        $phpini = $phpini -replace ";extension=zip",       "extension=zip"
        $phpini = $phpini -replace ";extension=gd",        "extension=gd"
        $phpini = $phpini -replace ";extension=intl",      "extension=intl"
        $phpini | Set-Content "$PhpDir\php.ini"
    }
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    if ($machinePath -notlike "*$PhpDir*") {
        [System.Environment]::SetEnvironmentVariable("Path","$machinePath;$PhpDir","Machine")
    }
    Refresh-Path
    Write-Success "ติดตั้ง PHP $PhpVersion สำเร็จ"
}

# ============================================================
# 3. Composer (latest)
# ============================================================
Write-Header "3. ติดตั้ง Composer (latest)"
$ComposerDir = "C:\composer"
if (-not (Test-Path $ComposerDir)) { New-Item -ItemType Directory -Path $ComposerDir | Out-Null }
if (Get-Command composer -ErrorAction SilentlyContinue) {
    Write-Info "Composer ติดตั้งแล้ว: $(composer --version | Select-Object -First 1)"
} else {
    Write-Step "กำลังดาวน์โหลด Composer installer..."
    $SetupFile = "$TempDir\composer-setup.php"
    Invoke-WebRequest -Uri "https://getcomposer.org/installer" -OutFile $SetupFile -UseBasicParsing
    $phpExe = if (Test-Path "C:\php\php.exe") { "C:\php\php.exe" } else { "php" }
    & $phpExe $SetupFile --install-dir="$ComposerDir" --filename="composer.phar"
    Remove-Item $SetupFile -Force

    "@echo off`nphp `"$ComposerDir\composer.phar`" %*" | Set-Content "$ComposerDir\composer.bat" -Encoding ASCII

    $machinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    if ($machinePath -notlike "*$ComposerDir*") {
        [System.Environment]::SetEnvironmentVariable("Path","$machinePath;$ComposerDir","Machine")
    }
    Refresh-Path
    Write-Success "ติดตั้ง Composer สำเร็จ"
}

# ============================================================
# 4. Laravel Installer (latest via composer global)
# ============================================================
Write-Header "4. ติดตั้ง Laravel Installer (latest)"
Write-Step "กำลังติดตั้ง Laravel Installer..."
$phpExe      = if (Test-Path "C:\php\php.exe") { "C:\php\php.exe" } else { "php" }
$composerPhar = if (Test-Path "C:\composer\composer.phar") { "C:\composer\composer.phar" } else { $null }

if ($composerPhar) {
    & $phpExe $composerPhar global require laravel/installer 2>&1 | Write-Host
} else {
    & composer global require laravel/installer 2>&1 | Write-Host
}
$composerBin = "$env:APPDATA\Composer\vendor\bin"
$machinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine")
if ($machinePath -notlike "*$composerBin*") {
    [System.Environment]::SetEnvironmentVariable("Path","$machinePath;$composerBin","Machine")
}
Refresh-Path
Write-Success "ติดตั้ง Laravel Installer สำเร็จ"

# ============================================================
# 5. Node.js LTS (latest)
# ============================================================
Write-Header "5. ติดตั้ง Node.js LTS (latest)"
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Info "Node.js ติดตั้งแล้ว: $(node --version)"
} else {
    Write-Step "กำลังดึงเวอร์ชัน LTS ล่าสุดของ Node.js..."
    $NodeInfo = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing
    $NodeLTS  = $NodeInfo | Where-Object { $_.lts } | Select-Object -First 1
    $NodeVersion = $NodeLTS.version -replace '^v',''
    $NodeInstaller = "$TempDir\node-latest-x64.msi"
    $NodeUrl = "https://nodejs.org/dist/v$NodeVersion/node-v$NodeVersion-x64.msi"
    Download-File -Url $NodeUrl -Destination $NodeInstaller -Name "Node.js $NodeVersion"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$NodeInstaller`" /quiet /norestart" -Wait
    Refresh-Path
    Write-Success "ติดตั้ง Node.js $NodeVersion สำเร็จ"
}

# ============================================================
# 6. Bun (latest)
# ============================================================
Write-Header "6. ติดตั้ง Bun (latest)"
$BunDir = "$env:USERPROFILE\.bun\bin"
if (Get-Command bun -ErrorAction SilentlyContinue) {
    Write-Info "Bun ติดตั้งแล้ว: $(bun --version)"
} else {
    Write-Step "กำลังดึงเวอร์ชันล่าสุดของ Bun..."
    $BunRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/oven-sh/bun/releases/latest" -UseBasicParsing
    $BunAsset   = $BunRelease.assets | Where-Object { $_.name -eq "bun-windows-x64.zip" }
    $BunZip     = "$TempDir\bun-windows-x64.zip"
    Download-File -Url $BunAsset.browser_download_url -Destination $BunZip -Name "Bun"
    if (-not (Test-Path $BunDir)) { New-Item -ItemType Directory -Path $BunDir | Out-Null }
    $BunExtract = "$TempDir\bun-extract"
    Expand-Archive -Path $BunZip -DestinationPath $BunExtract -Force
    $BunExe = Get-ChildItem -Path $BunExtract -Filter "bun.exe" -Recurse | Select-Object -First 1
    if ($BunExe) { Copy-Item $BunExe.FullName "$BunDir\bun.exe" -Force }
    $userPath = [System.Environment]::GetEnvironmentVariable("Path","User")
    if ($userPath -notlike "*$BunDir*") {
        [System.Environment]::SetEnvironmentVariable("Path","$userPath;$BunDir","User")
    }
    Refresh-Path
    Write-Success "ติดตั้ง Bun สำเร็จ"
}

# ============================================================
# 7. Docker Desktop (latest)
# ============================================================
Write-Header "7. ติดตั้ง Docker Desktop (latest)"
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Info "Docker ติดตั้งแล้ว: $(docker --version)"
} else {
    $DockerInstaller = "$TempDir\DockerDesktopInstaller.exe"
    $DockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    Download-File -Url $DockerUrl -Destination $DockerInstaller -Name "Docker Desktop"
    Write-Step "กำลังติดตั้ง Docker Desktop (อาจใช้เวลานาน)..."
    Start-Process -FilePath $DockerInstaller -ArgumentList "install --quiet --accept-license" -Wait
    Refresh-Path
    Write-Success "ติดตั้ง Docker Desktop สำเร็จ"
}

# ============================================================
# 8. DBeaver Community (latest)
# ============================================================
Write-Header "8. ติดตั้ง DBeaver Community (latest)"
if (Test-Path "C:\Program Files\DBeaver\dbeaver.exe") {
    Write-Info "DBeaver ติดตั้งแล้ว"
} else {
    Write-Step "กำลังดึงเวอร์ชันล่าสุดของ DBeaver..."
    $DBeaverRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/dbeaver/dbeaver/releases/latest" -UseBasicParsing
    $DBeaverVersion = $DBeaverRelease.tag_name
    $DBeaverAsset   = $DBeaverRelease.assets | Where-Object { $_.name -match "x86_64-setup\.exe$" }
    $DBeaverInstaller = "$TempDir\dbeaver-setup.exe"
    Download-File -Url $DBeaverAsset.browser_download_url -Destination $DBeaverInstaller -Name "DBeaver $DBeaverVersion"
    Start-Process -FilePath $DBeaverInstaller -ArgumentList "/S" -Wait
    Write-Success "ติดตั้ง DBeaver $DBeaverVersion สำเร็จ"
}

# ============================================================
# 9. Antigravity (latest via npm)
# ============================================================
Write-Header "9. ติดตั้ง Antigravity (latest)"
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install -g @antigravity/cli 2>&1 | Write-Host
    Refresh-Path
    Write-Success "ติดตั้ง Antigravity สำเร็จ"
} else {
    Write-Fail "ไม่พบ npm กรุณาตรวจสอบ Node.js"
}

# ============================================================
# สรุปผล
# ============================================================
Write-Header "สรุปผลการติดตั้ง"
Refresh-Path

$tools = @(
    @{ Name = "Git";         Command = "git --version" },
    @{ Name = "PHP";         Command = "php --version" },
    @{ Name = "Composer";    Command = "composer --version" },
    @{ Name = "Laravel";     Command = "laravel --version" },
    @{ Name = "Node.js";     Command = "node --version" },
    @{ Name = "npm";         Command = "npm --version" },
    @{ Name = "Bun";         Command = "bun --version" },
    @{ Name = "Docker";      Command = "docker --version" },
    @{ Name = "Antigravity"; Command = "antigravity --version" }
)
foreach ($t in $tools) {
    try {
        $v = Invoke-Expression $t.Command 2>$null | Select-Object -First 1
        if ($v) { Write-Success "$($t.Name): $v" } else { Write-Fail "$($t.Name): ไม่พบ" }
    } catch { Write-Fail "$($t.Name): ไม่พบ" }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " การติดตั้งเสร็จสมบูรณ์!" -ForegroundColor Green
Write-Host " หมายเหตุ: กรุณา Restart เครื่องหลังติดตั้ง Docker Desktop" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

# ============================================================
# ล้างไฟล์ชั่วคราว + Restart
# ============================================================
Write-Step "กำลังลบไฟล์ดาวน์โหลดชั่วคราว..."
if (Test-Path $TempDir) {
    Remove-Item -Path $TempDir -Recurse -Force
    Write-Success "ลบไฟล์ชั่วคราวแล้ว"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " กด Enter เพื่อ Restart เครื่องทันที..." -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Read-Host
Restart-Computer -Force
