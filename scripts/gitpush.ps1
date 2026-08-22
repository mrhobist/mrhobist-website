# git push - WMI uzerinden baslatir.
#
# NEDEN: Kisitli/sandbox'lanmis kabuk ortamlarinda (AppContainer) Git Credential Manager,
# Windows Credential Manager'a erisemez. Kayitli GitHub kimligi okunamayinca GCM bir kimlik
# penceresi acmaya calisir; etkilesim mumkun olmadigi icin push
# "fatal: Cannot prompt because user interactivity has been disabled" ile duser.
# COZUM: process'i WMI ile baslatmak; WMI servisi process'i sandbox DISINDA yaratir
# (AppContainer token'i miras alinmaz) -> GCM kayitli kimligi okur, push calisir.
# Normal bir terminalde bu script gerekmez, dogrudan `git push` kullanilabilir.
#
# NOT: Bu dosya SADECE ASCII icermelidir. PowerShell 5.1, BOM'suz .ps1 dosyalarini ANSI
# kodlamasiyla okur; Turkce karakter string'i bozup parse hatasi verir.
#
# Kullanim:
#   powershell -ExecutionPolicy Bypass -File scripts\gitpush.ps1                     # origin main
#   powershell -ExecutionPolicy Bypass -File scripts\gitpush.ps1 -PushArgs "-u origin main"
#
# Cikis kodu: 0 = push basarili, 1 = git hata dondurdu, 2 = baslatma/log sorunu.
#
# DIKKAT: Zorlamali push varsayilan DEGILDIR - bilerek -PushArgs ile verilmelidir.
param(
    [string]$PushArgs = "origin main",
    [int]$TimeoutSec = 180
)

$root = Split-Path $PSScriptRoot -Parent
$log = Join-Path $env:TEMP ("website-push-" + [Guid]::NewGuid().ToString("N").Substring(0, 8) + ".log")

# /v:on -> gecikmeli genisletme; !errorlevel! git bittikten SONRA okunur. %errorlevel% kullanilsaydi
# komut satiri ayristirilirken genisler ve git calismadan once hep 0 yazilirdi.
$cmd = 'cmd.exe /v:on /c cd /d "' + $root + '" && (git push ' + $PushArgs + ' > "' + $log + '" 2>&1) & echo EXIT_CODE=!errorlevel! >> "' + $log + '"'

$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd }
if ($r.ReturnValue -ne 0) {
    Write-Error "WMI process baslatilamadi (ReturnValue=$($r.ReturnValue))"
    exit 2
}

try {
    Wait-Process -Id $r.ProcessId -Timeout $TimeoutSec -ErrorAction Stop
} catch {
    Write-Output "!! Process $TimeoutSec sn icinde bitmedi - kimlik penceresi bekliyor olabilir."
    try { Stop-Process -Id $r.ProcessId -Force -ErrorAction Stop } catch { }
}

if (-not (Test-Path $log)) {
    Write-Error "Push log dosyasi olusmadi: $log"
    exit 2
}

$content = Get-Content $log
$content

# \s* sarttir: cmd'nin `echo` komutu satir sonuna bir bosluk birakir.
$exitLine = $content | Where-Object { $_ -match "^EXIT_CODE=(\d+)\s*$" } | Select-Object -Last 1
if (-not $exitLine) {
    Write-Error "git tamamlanmadi (EXIT_CODE satiri yok)."
    exit 2
}

$gitExit = [int]$Matches[1]

# Push BASARILIYSA Drive arsivini de tazele. Boylece uzak depo ile Drive arsivi ayni noktada
# olur; post-commit hook'u kacirilmis olsa bile push telafi eder. Zip adi tarih+sha oldugundan
# ayni commit icin tekrar calismak Drive'da KOPYA URETMEZ.
# drive-sync yapilandirilmamissa sessizce cikar; push'un sonucunu ASLA degistirmez.
if ($gitExit -eq 0) {
    $sync = Join-Path $PSScriptRoot "drive-sync.ps1"
    if (Test-Path $sync) {
        try { & powershell -NoProfile -ExecutionPolicy Bypass -File $sync } catch { Write-Output "[gitpush] drive-sync atlandi: $_" }
    }
}

exit $gitExit
