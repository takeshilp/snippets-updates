# Snippets updater (docs/updates.md). ASCII only: Windows PowerShell 5.1 reads a BOM-less file as ANSI.
# Runs from a per-user scheduled task (hourly and at logon). Stages a newer release next to the extension folder and swaps the folders
# only while the browser is closed (never while it runs: the browser would mix old and new files). Nothing is ever reloaded.
#   update.ps1 [-Config <config.json>] [-NoWait] [-Uninstall]
param([string]$Config = (Join-Path $PSScriptRoot 'config.json'), [switch]$NoWait, [switch]$Uninstall)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$script:rc = 0
$HomeDir = Split-Path -Parent $Config
$LogFile = Join-Path $HomeDir 'update.log'
function Log($msg) {
  $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $msg
  Write-Host $line
  try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch { }
}
function Trim-Log {
  try { if ((Test-Path $LogFile) -and @(Get-Content $LogFile).Count -gt 600) { Set-Content -LiteralPath $LogFile -Value (Get-Content $LogFile -Tail 500) -Encoding UTF8 } } catch { }
}
function Get-Manifest($dir) {
  $p = Join-Path $dir 'manifest.json'
  if (-not (Test-Path -LiteralPath $p)) { return $null }
  try { return (Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}
# A Snippets folder: guards a wrong path in the config
function Test-Snip($m) { return ($null -ne $m -and $m.options_page -eq 'manager.html' -and $m.action.default_popup -eq 'popup.html') }
function Get-Text($url) {
  $wc = New-Object Net.WebClient
  $wc.Encoding = [Text.Encoding]::UTF8
  if ($wc.Proxy) { $wc.Proxy.Credentials = [Net.CredentialCache]::DefaultCredentials }
  return $wc.DownloadString($url)
}
function Get-File($url, $to) {
  $wc = New-Object Net.WebClient
  if ($wc.Proxy) { $wc.Proxy.Credentials = [Net.CredentialCache]::DefaultCredentials }
  $wc.DownloadFile($url, $to)
}

function Main {
  if (-not (Test-Path -LiteralPath $Config)) { Log "no config: $Config"; $script:rc = 1; return }
  $cfg = Get-Content -LiteralPath $Config -Raw -Encoding UTF8 | ConvertFrom-Json
  if (-not $cfg.dir) { Log 'config.json has no dir'; $script:rc = 1; return }
  $D = ([string]$cfg.dir).TrimEnd('\')
  $Next = "$D.next"; $Old = "$D.old"
  $Pending = Join-Path $D 'pending.json'
  $Staged = Join-Path $HomeDir 'staged.ok'
  $task = if ($cfg.task) { [string]$cfg.task } else { 'SnippetsUpdater' }

  if ($Uninstall) {
    try { Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction Stop } catch { }
    foreach ($p in $Next, $Old) { if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue } }
    if (Test-Path -LiteralPath $Pending) { Remove-Item -LiteralPath $Pending -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath $HomeDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host 'Updater removed: the task, the staged files and the updater folder.'
    Write-Host "The extension itself stays until you remove it at chrome://extensions (that deletes your snippets: export a backup first). Its folder: $D"
    return
  }

  # 2. a swap cut between its two renames
  if (-not (Test-Path -LiteralPath $D) -and (Test-Path -LiteralPath $Old)) { [IO.Directory]::Move($Old, $D); Log "recovered $D from $Old" }

  # 3. what is installed
  $loaded = $false; $installed = [version]'0.0.0'
  if (Test-Path -LiteralPath (Join-Path $D 'manifest.json')) {
    $m = Get-Manifest $D
    if (-not (Test-Snip $m)) { Log "not a Snippets folder: $D"; $script:rc = 1; return }
    $installed = [version]$m.version; $loaded = $true
  } elseif ((Test-Path -LiteralPath $D) -and @(Get-ChildItem -LiteralPath $D -Force).Count -gt 0) {
    Log "refusing: $D is not empty and has no manifest.json"; $script:rc = 1; return
  }
  # a staged folder that is ready: staged.ok names its version, it is a Snippets folder of that version, newer than the installed one
  function Get-Staged {
    if (-not (Test-Path -LiteralPath $Staged) -or -not (Test-Path -LiteralPath $Next)) { return $null }
    $v = (Get-Content -LiteralPath $Staged -Raw).Trim(); $sm = Get-Manifest $Next
    if ((Test-Snip $sm) -and $sm.version -eq $v -and [version]$v -gt $installed) { return $v }
    return $null
  }

  # 4. the latest release (0.17: not signed any more; the sha256 catches a broken download, a sig field of an older release is ignored)
  $l = $null
  try {
    $l = Get-Text ([string]$cfg.latest) | ConvertFrom-Json
    if ($l.version -notmatch '^\d+\.\d+\.\d+$' -or $l.sha256 -notmatch '^[0-9a-f]{64}$' -or -not $l.url) { throw 'latest.json is malformed' }
  } catch {
    Log ('could not get the latest release: ' + $_.Exception.Message)
    if (-not (Get-Staged)) { $script:rc = 1; return }
    $l = $null  # a staged update is waiting: go on to the swap
  }

  # 5. stage a newer release
  if ($l -and [version]$l.version -gt $installed -and (Get-Staged) -ne $l.version) {
    $zip = Join-Path $HomeDir 'download.zip'
    Get-File ([string]$l.url) $zip
    if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower() -ne $l.sha256) { Remove-Item -LiteralPath $zip -Force; Log 'sha256 mismatch, download dropped'; $script:rc = 1; return }
    if (Test-Path -LiteralPath $Next) { Remove-Item -LiteralPath $Next -Recurse -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $Next)
    Remove-Item -LiteralPath $zip -Force
    $sm = Get-Manifest $Next
    if (-not (Test-Snip $sm) -or $sm.version -ne $l.version -or -not $sm.background.service_worker -or -not (Test-Path -LiteralPath (Join-Path $Next ([string]$sm.background.service_worker)))) {
      Remove-Item -LiteralPath $Next -Recurse -Force; Log 'the downloaded package does not match its description, dropped'; $script:rc = 1; return
    }
    [IO.File]::WriteAllText($Staged, [string]$l.version, (New-Object Text.UTF8Encoding $false))
    Log "staged $($l.version)"
  }
  $target = Get-Staged
  if (-not $target) { return }  # nothing newer: silent (no log line per hour)

  # 6. wait for the browser to close (only when the folder is loaded: a fresh install has nothing running)
  $names = @()
  if ($loaded) {
    if ($cfg.procs) { $names = @($cfg.procs) } else {
      $esc = $D.Replace('\', '\\')
      foreach ($b in @(@('chrome', "$env:LOCALAPPDATA\Google\Chrome\User Data"), @('msedge', "$env:LOCALAPPDATA\Microsoft\Edge\User Data"))) {
        if (-not (Test-Path -LiteralPath $b[1])) { continue }
        foreach ($f in @(Get-ChildItem -LiteralPath $b[1] -Filter 'Secure Preferences' -Recurse -Depth 1 -ErrorAction SilentlyContinue)) {
          try { if ((Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8).IndexOf($esc, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $names += $b[0]; break } } catch { }
        }
      }
      if (-not $names) { $names = @('chrome', 'msedge') }
    }
  }
  $session = (Get-Process -Id $PID).SessionId
  function Test-Running { return ($names.Count -gt 0 -and @(Get-Process -Name $names -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $session }).Count -gt 0) }
  if (Test-Running) {
    [IO.File]::WriteAllText($Pending, "{`"version`":`"$target`"}", (New-Object Text.UTF8Encoding $false))
    if ($NoWait) { Log "$target is staged, waiting for the browser to close"; return }
    $until = (Get-Date).AddHours(11)
    while ((Get-Date) -lt $until) {
      Start-Sleep -Seconds 15
      if (-not (Test-Running)) { Start-Sleep -Seconds 5; if (-not (Test-Running)) { break } }  # closed at two checks: a relaunch for the browser's own update is not a close
    }
    if (Test-Running) { return }
  }

  # 7. swap: two renames on one volume, the old version stays in D.old
  $tries = if ($cfg.tries) { [int]$cfg.tries } else { 20 }
  for ($i = 1; $i -le $tries; $i++) {
    if (Test-Running) { Log 'the browser started again, swap postponed'; return }
    try {
      if (Test-Path -LiteralPath $Old) { Remove-Item -LiteralPath $Old -Recurse -Force }
      if ($loaded) { [IO.Directory]::Move($D, $Old) } elseif (Test-Path -LiteralPath $D) { Remove-Item -LiteralPath $D -Recurse -Force }
      try { [IO.Directory]::Move($Next, $D) } catch { if ($loaded) { [IO.Directory]::Move($Old, $D) }; throw }
      # the add-ons put into the folder by hand stay with the new version (docs/addon.md); never a reason to redo the swap
      foreach ($a in 'addon.js', 'addon-breaks.js') { try { if ($loaded -and (Test-Path -LiteralPath (Join-Path $Old $a))) { Copy-Item -LiteralPath (Join-Path $Old $a) -Destination $D -Force } } catch { Log ($a + ' not kept: ' + $_.Exception.Message) } }
      Remove-Item -LiteralPath $Staged -Force -ErrorAction SilentlyContinue
      Log "updated $installed -> $target"
      return
    } catch {
      Log ("swap try $i failed: " + $_.Exception.Message)
      if ($i -lt $tries) { Start-Sleep -Seconds 3 }
    }
  }
  Log 'swap failed: the installed version stays, the new one stays staged for the next run'
  $script:rc = 1
}
# the mutex name follows the config task name (a test seam; the default is the real one)
$mutexName = 'Local\SnippetsUpdater'
try { $t = (Get-Content -LiteralPath $Config -Raw -Encoding UTF8 | ConvertFrom-Json).task; if ($t) { $mutexName = 'Local\' + $t } } catch { }
$mutex = New-Object System.Threading.Mutex($false, $mutexName)
try {
  if (-not $mutex.WaitOne(0)) { exit 0 }
  Trim-Log
  Main
} catch {
  Log ('error: ' + $_.Exception.Message)
  $script:rc = 1
} finally {
  try { $mutex.ReleaseMutex() } catch { }
}
exit $script:rc
