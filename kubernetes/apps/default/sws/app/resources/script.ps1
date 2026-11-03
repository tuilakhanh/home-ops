# setup-codex.ps1 — Setup Codex dùng CLIProxy (Windows / PowerShell)
# Tạo %USERPROFILE%\.codex\auth.json + config.toml, cùng logic với setup-codex.sh.
#
# Người dùng cuối (PowerShell):
#   irm https://cliproxy.sunsilk.id.vn/install.ps1 | iex
# Hoặc tải về rồi chạy:  powershell -ExecutionPolicy Bypass -File .\setup-codex.ps1
#
# Script BẮT BUỘC hỏi 2 thứ (không có mặc định thầm lặng):
#   1. CLIProxy API key (nhập ẩn, nhập 2 lần để xác nhận)
#   2. Bật/tắt WebSocket (phải gõ y hoặc n, Enter trống sẽ hỏi lại)
#
# Chỉ dành cho automation: truyền thẳng thì bỏ qua câu hỏi tương ứng:
#   .\setup-codex.ps1 -Key sk-xxxx -Websockets false

[CmdletBinding()]
param(
    [string]$Key = "",
    [string]$Websockets = "",
    [switch]$NoWebsockets,
    [switch]$WithWebsockets,
    [string]$BaseUrl = "https://cliproxy.sunsilk.id.vn/v1",
    [string]$Model = "",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    @"
setup-codex.ps1 — Setup Codex dùng CLIProxy (Windows)

Người dùng cuối (PowerShell):
  irm <URL-của-file-này> | iex

Script bắt buộc hỏi: (1) API key, (2) bật/tắt WebSocket (y/n).

Tuỳ chọn (chỉ cho automation, truyền thì bỏ qua câu hỏi tương ứng):
  -Key <key>           API key
  -Websockets <bool>   true/false, yes/no, y/n, on/off, 1/0
                       true = WebSocket (nhanh hơn, lỗi trả về luôn),
                       false = HTTP (gateway retry được khi Codex overload)
  -NoWebsockets        = -Websockets false
  -WithWebsockets      = -Websockets true
  -BaseUrl <url>       mặc định: https://cliproxy.sunsilk.id.vn/v1
  -Model <model>       ghi thêm model = "..."
  -Help                hiện hướng dẫn này
"@
}

if ($Help) { Show-Usage; return }

function ConvertTo-BoolText([string]$Value) {
    switch ($Value.Trim().ToLowerInvariant()) {
        { $_ -in "true", "1", "yes", "y", "on" }   { return "true" }
        { $_ -in "false", "0", "no", "n", "off" }  { return "false" }
        default { throw "--Websockets chỉ nhận true/false" }
    }
}

function ConvertFrom-SecureStringPlain([Security.SecureString]$Secure) {
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

function Remove-Whitespace([string]$Value) { return ($Value -replace '\s', '') }

function Set-TomlKv([string]$Block, [string]$KeyName, [string]$RawValue) {
    $line = "$KeyName = $RawValue"
    $pat = "(?m)^" + [regex]::Escape($KeyName) + "\s*=.*$"
    if ([regex]::IsMatch($Block, $pat)) { return [regex]::Replace($Block, $pat, $line, 1) }
    if ($Block.Trim()) { return $Block.TrimEnd() + "`n" + $line + "`n" }
    return $line + "`n"
}

function Backup-File([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        $bak = "$Path.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item -LiteralPath $Path -Destination $bak
        Write-Host "  backup: $bak"
    }
}

$keyFromFlag = -not [string]::IsNullOrWhiteSpace($Key)
$wsFromFlag = $false
if ($NoWebsockets)   { $Websockets = "false"; $wsFromFlag = $true }
if ($WithWebsockets) { $Websockets = "true";  $wsFromFlag = $true }
if (-not [string]::IsNullOrWhiteSpace($Websockets)) {
    $Websockets = ConvertTo-BoolText $Websockets
    $wsFromFlag = $true
}

$codexDir   = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$authFile   = Join-Path $codexDir "auth.json"
$configFile = Join-Path $codexDir "config.toml"

Write-Host "=== Setup Codex (CLIProxy) ==="

# --- 1. BẮT BUỘC hỏi key (trừ khi automation truyền -Key) ---
if (-not $keyFromFlag) {
    while ($true) {
        $Key = Remove-Whitespace (ConvertFrom-SecureStringPlain (Read-Host "1) Nhập CLIProxy API key (sk-..., nhập ẩn)" -AsSecureString))
        if (-not $Key) { Write-Host "❌ Key trống, nhập lại."; continue }
        $confirm = Remove-Whitespace (ConvertFrom-SecureStringPlain (Read-Host "   Nhập lại key để xác nhận" -AsSecureString))
        if ($Key -ne $confirm) { Write-Host "❌ Key nhập lại không khớp, nhập lại từ đầu."; continue }
        break
    }
} else {
    $Key = Remove-Whitespace $Key
    if (-not $Key) { throw "❌ Key trống." }
}

# --- 2. BẮT BUỘC hỏi bật/tắt websocket: phải gõ y/n, Enter trống hỏi lại ---
if (-not $wsFromFlag) {
    Write-Host @"
2) Chọn kiểu kết nối: WebSocket hay HTTP?
   • Bật (y): dùng WebSocket — phản hồi nhanh hơn, chữ hiện ra gần như tức thì.
     Nhưng khi server lỗi (ví dụ Codex đang quá tải/overload) thì lỗi sẽ trả
     về luôn, không tự thử lại được, bạn phải gửi lại thủ công.
   • Tắt (n): dùng HTTP thường — phản hồi có thể chậm hơn một chút.
     Bù lại gateway tự retry được khi gặp lỗi tạm thời như overload,
     nên ổn định hơn, ít bị văng giữa chừng.
   Không chắc thì chọn n (ổn định hơn).
"@
    while ($true) {
        $answer = (Read-Host "   Bật WebSocket? Gõ y = bật, n = tắt (bắt buộc chọn)").Trim().ToLowerInvariant()
        switch ($answer) {
            { $_ -in "y", "yes", "true", "1", "on" }   { $Websockets = "true"; break }
            { $_ -in "n", "no", "false", "0", "off" }  { $Websockets = "false"; break }
            default { Write-Host "❌ Chưa chọn. Gõ y để bật hoặc n để tắt."; continue }
        }
        if ($Websockets) { break }
    }
}

New-Item -ItemType Directory -Force -Path $codexDir | Out-Null

# --- 3. Ghi auth.json ---
Write-Host "→ Ghi $authFile"
Backup-File $authFile
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$authJson = ([ordered]@{ auth_mode = "apikey"; OPENAI_API_KEY = $Key } | ConvertTo-Json) + "`n"
[IO.File]::WriteAllText($authFile, $authJson, $utf8NoBom)
# Windows: giới hạn quyền đọc auth.json cho user hiện tại (best-effort).
if ($env:OS -eq "Windows_NT") {
    try { & icacls $authFile /inheritance:r /grant:r "$($env:USERNAME):F" | Out-Null } catch { }
}

# --- 4. Ghi/cập nhật config.toml (giữ nguyên phần còn lại nếu đã có) ---
Write-Host "→ Cập nhật $configFile (supports_websockets = $Websockets)"
Backup-File $configFile
$text = if (Test-Path -LiteralPath $configFile) { [IO.File]::ReadAllText($configFile) } else { "" }

# Cách cũ chỉ thêm openai_base_url ở đầu file: xóa hẳn dòng đó (mọi vị trí).
$text = [regex]::Replace($text, "(?m)^openai_base_url\s*=.*\r?\n?", "")

$m = [regex]::Match($text, "(?m)^\[")
if ($m.Success) { $head = $text.Substring(0, $m.Index); $rest = $text.Substring($m.Index) }
else { $head = $text; $rest = "" }

$head = Set-TomlKv $head "model_provider" '"cliproxy"'
if ($Model.Trim()) { $head = Set-TomlKv $head "model" "`"$($Model.Trim())`"" }

$providerBlock = @"
[model_providers.cliproxy]
name = "CLIProxy"
base_url = "$BaseUrl"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = $Websockets
"@

# Block cliproxy luôn nằm ngay đầu file, ngay sau các key top-level. Block cũ ở đâu cũng bị gỡ.
$rest = [regex]::Replace($rest, "(?ms)^\[model_providers\.cliproxy\]\r?\n.*?(?=^\[|\z)", "").Trim()
$newText = $head.TrimEnd() + "`n`n" + $providerBlock.TrimEnd() + "`n"
if ($rest) { $newText += "`n" + $rest + "`n" }
[IO.File]::WriteAllText($configFile, $newText, $utf8NoBom)
Write-Host $newText

# --- 5. Kiểm tra lại ---
Write-Host ""
Write-Host "✅ Xong. Kiểm tra:"
$masked = "{0}…{1} (len={2})" -f $Key.Substring(0, 4), $Key.Substring($Key.Length - 4), $Key.Length
Write-Host "  auth.json : $authFile  key=$masked"
Write-Host "  websockets: $Websockets   base_url: $BaseUrl"
$codex = Get-Command codex -ErrorAction SilentlyContinue
if ($codex) { & codex --version } else { Write-Host "  (chưa thấy lệnh 'codex' trong PATH — cài Codex xong chạy: codex)" }
Write-Host "  Chạy thử: codex   |   Muốn đổi websocket thì chạy lại script này."