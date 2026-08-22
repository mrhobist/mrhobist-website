# Google Drive arsivleme - rclone ile.
#
# NE YAPAR: mevcut commit'in kaynak arsivini (zip) Drive'daki MrHobist/Website altina
# Proje/ klasorune yukler. Site statik oldugu icin bu zip yayindaki sitenin tamamidir -
# ayrica derleme ciktisi yoktur (Deskify'daki APK/ bolumunun karsiligi burada yok).
#
# NEDEN rclone: MCP connector'i BU IS ICIN UYGUN DEGIL - (1) MCP araclari yalnizca Claude
# oturumunda vardir, git hook'u onlari cagiramaz; (2) connector'a dosya base64 olarak
# gonderilir. rclone headless calisir, boyut siniri yoktur.
#
# KURULUM (bir kez):
#   1) rclone kurulu olmali (winget install Rclone.Rclone)
#   2) rclone config -> Google Drive remote'u (bu makinede: "gdrive")
#   3) Ortam degiskeni (kalici):
#      [Environment]::SetEnvironmentVariable("WEBSITE_DRIVE_REMOTE","gdrive","User")
#      [Environment]::SetEnvironmentVariable("WEBSITE_RCLONE","<rclone.exe tam yolu>","User")   # PATH'te degilse
#   Yapilandirilmamissa script SESSIZCE cikar (kod 0) - commit'i asla bozmaz.
#
# Kullanim:
#   powershell -ExecutionPolicy Bypass -File scripts\drive-sync.ps1
#
# Cikis kodu: 0 = basarili VEYA yapilandirilmamis (atlandi), 1 = yukleme hatasi.
#
# NOT: Bu dosya SADECE ASCII icermelidir. PowerShell 5.1, BOM'suz .ps1 dosyalarini ANSI
# kodlamasiyla okur; Turkce karakter string'i bozup parse hatasi verir.
param(
    [string]$DriveBase = "MrHobist/Website"
)

$root = Split-Path $PSScriptRoot -Parent

# --- rclone bul: once ortam degiskeni, sonra PATH, sonra winget kurulum yolu ---
$rclone = $env:WEBSITE_RCLONE
if (-not ($rclone -and (Test-Path $rclone))) {
    $c = Get-Command rclone -ErrorAction SilentlyContinue
    if ($c) { $rclone = $c.Source }
}
if (-not ($rclone -and (Test-Path $rclone))) {
    $found = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "rclone.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $rclone = $found.FullName }
}
if (-not ($rclone -and (Test-Path $rclone))) {
    Write-Output "[drive-sync] rclone bulunamadi - atlandi."
    exit 0
}

$remote = $env:WEBSITE_DRIVE_REMOTE
if (-not $remote) {
    Write-Output "[drive-sync] WEBSITE_DRIVE_REMOTE tanimli degil - atlandi."
    exit 0
}

# Remote gercekten yapilandirilmis mi?
$remotes = & $rclone listremotes 2>$null
if ($remotes -notcontains "${remote}:") {
    Write-Output "[drive-sync] '$remote' remote'u rclone.conf'ta yok - atlandi. (rclone config)"
    exit 0
}

# Ad SAAT icermez (yalnizca tarih + sha): ayni commit icin script birden fazla kez calissa da
# (post-commit hook + gitpush) ayni ad uretilir ve Drive'da kopya birikmez.
$sha = (& git -C $root rev-parse --short HEAD).Trim()
if (-not $sha) {
    Write-Output "[drive-sync] git commit bulunamadi - atlandi."
    exit 0
}
$stamp = Get-Date -Format "yyyyMMdd"
$zipName = "Website-$stamp-$sha.zip"
$zipPath = Join-Path $env:TEMP $zipName

# git archive: yalnizca TAKIP EDILEN dosyalar. Site tamamen takip edildigi icin bu arsiv
# yayina giden icerigin birebir kopyasidir.
& git -C $root archive --format=zip -o $zipPath HEAD 2>$null
if (-not (Test-Path $zipPath)) {
    Write-Output "[drive-sync] git archive uretilemedi - atlandi."
    exit 0
}

# --log-level ERROR: rclone'un NOTICE satirlari stderr'e gider ve PowerShell onlari
# NativeCommandError olarak gosterir (hook ciktisi hata gibi gorunur). Gercek hatalar gecer.
$out = & $rclone copyto $zipPath "${remote}:$DriveBase/Proje/$zipName" --log-level ERROR 2>&1
$code = $LASTEXITCODE
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

if ($code -eq 0) {
    Write-Output "[drive-sync] proje yuklendi: $DriveBase/Proje/$zipName"
    exit 0
} else {
    Write-Output "[drive-sync] PROJE YUKLENEMEDI: $out"
    exit 1
}
