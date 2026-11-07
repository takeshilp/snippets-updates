# Snippets installer (docs/updates.md). ASCII only. Run: iex (irm <raw url of this file>)
# Finds the folder the browser loads the extension from (or picks one for a fresh install), installs the updater into
# %LOCALAPPDATA%\SnippetsUpdater and registers a per-user scheduled task (hourly and at logon). No admin rights needed.
# SNIPPETS_DIR (environment variable) picks the extension folder when several are found.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-Snippets {
  $raw = 'https://raw.githubusercontent.com/takeshilp/snippets-updates/main'
  $latestUrl = 'https://github.com/takeshilp/snippets-updates/releases/latest/download/latest.json'
  $updHome = Join-Path $env:LOCALAPPDATA 'SnippetsUpdater'
  $task = 'SnippetsUpdater'
  function Test-Snip($dir) {
    $p = Join-Path $dir 'manifest.json'
    if (-not (Test-Path -LiteralPath $p)) { return $false }
    try { $m = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return $false }
    return ($m.options_page -eq 'manager.html' -and $m.action.default_popup -eq 'popup.html')
  }

  # 1. the extension folder
  $fresh = $false
  if ($env:SNIPPETS_DIR) { $dir = $env:SNIPPETS_DIR.TrimEnd('\') } else {
    $found = @()
    foreach ($ud in "$env:LOCALAPPDATA\Google\Chrome\User Data", "$env:LOCALAPPDATA\Microsoft\Edge\User Data") {
      if (-not (Test-Path -LiteralPath $ud)) { continue }
      foreach ($f in @(Get-ChildItem -LiteralPath $ud -Filter 'Secure Preferences' -Recurse -Depth 1 -ErrorAction SilentlyContinue)) {
        $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
        foreach ($m in [regex]::Matches($text, '"path":\s*"((?:[^"\\]|\\.)*)"')) {
          $p = [regex]::Unescape($m.Groups[1].Value)
          if ($p -and (Test-Path -LiteralPath $p -PathType Container) -and (Test-Snip $p)) { $found += $p.TrimEnd('\') }
        }
      }
    }
    $found = @($found | Sort-Object -Unique)
    if ($found.Count -gt 1) {
      Write-Host 'Several Snippets folders are loaded in your browsers:'
      $found | ForEach-Object { Write-Host "  $_" }
      Write-Host 'Pick the one to update: set the variable and run the installer again, for example:'
      Write-Host ('  $env:SNIPPETS_DIR = "' + $found[0] + '"')
      Write-Host ("  iex (irm $raw/install.ps1)")
      return
    }
    if ($found.Count -eq 1) { $dir = $found[0] } else { $dir = Join-Path $env:LOCALAPPDATA 'Snippets\extension'; $fresh = $true }
  }
  Write-Host "Extension folder: $dir"

  # 2. the folder and its neighbours must be writable (the updater swaps folders next to it)
  try {
    $parent = Split-Path -Parent $dir
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force $parent | Out-Null }
    New-Item -ItemType Directory "$dir.next" -ErrorAction Stop | Out-Null
    Remove-Item -LiteralPath "$dir.next" -Force
  } catch {
    Write-Host "Cannot write next to $dir ($($_.Exception.Message))."
    Write-Host 'Move the extension folder into your Documents folder, load it there again in chrome://extensions, and run the installer once more.'
    return
  }

  # 3. the updater and its config
  New-Item -ItemType Directory -Force $updHome | Out-Null
  $wc = New-Object Net.WebClient
  if ($wc.Proxy) { $wc.Proxy.Credentials = [Net.CredentialCache]::DefaultCredentials }
  $wc.DownloadFile("$raw/update.ps1", (Join-Path $updHome 'update.ps1'))
  $cfg = [ordered]@{ dir = $dir; latest = $latestUrl } | ConvertTo-Json -Compress
  [IO.File]::WriteAllText((Join-Path $updHome 'config.json'), $cfg, (New-Object Text.UTF8Encoding $false))

  # 4. the scheduled task (per user, no admin): at logon and every hour; conhost --headless keeps the console window away
  $user = "$env:USERDOMAIN\$env:USERNAME"
  $act = New-ScheduledTaskAction -Execute 'conhost.exe' -Argument ('--headless powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + (Join-Path $updHome 'update.ps1') + '"')
  $t1 = New-ScheduledTaskTrigger -AtLogOn -User $user
  $t2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 3650)
  $set = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 12)
  $pr = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
  Register-ScheduledTask -TaskName $task -Action $act -Trigger @($t1, $t2) -Settings $set -Principal $pr -Force | Out-Null

  # 5. first run
  Start-ScheduledTask -TaskName $task
  if ($fresh) {
    Write-Host 'Downloading the extension...'
    for ($i = 0; $i -lt 60 -and -not (Test-Path -LiteralPath (Join-Path $dir 'manifest.json')); $i++) { Start-Sleep -Seconds 2 }
    if (-not (Test-Path -LiteralPath (Join-Path $dir 'manifest.json'))) { Write-Host "Not ready yet: see $updHome\update.log" ; return }
    Write-Host 'Now load it into the browser:'
    Write-Host '  1. open chrome://extensions (or edge://extensions) and turn on Developer mode'
    Write-Host "  2. Load unpacked -> pick this folder: $dir"
    Write-Host '  3. open the extension manager, gear -> Sites, and add the sites where you want snippets (until then it works nowhere)'
  } else {
    Write-Host 'Updates install by themselves while the browser is closed. To install a waiting one now, close the browser for 30 seconds.'
    Start-Sleep -Seconds 10
    if (Test-Path (Join-Path $updHome 'update.log')) { Get-Content (Join-Path $updHome 'update.log') -Tail 5 }
  }
  # 6. removal
  Write-Host ''
  Write-Host ('To remove the updater: powershell -NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $updHome 'update.ps1') + '" -Uninstall')
}
Install-Snippets
