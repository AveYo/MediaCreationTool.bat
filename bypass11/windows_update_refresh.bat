@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit /b

$_Paste_in_Powershell = {
  $host.ui.rawui.windowtitle = 'WINDOWS UPDATE REFRESH'
  bitsadmin /reset /allusers
  'wuauserv','bits','cryptSvc','usosvc' |% { start -win 1 net1 "stop $_" }
  sleep 5
  'wuauserv','bits','cryptSvc','usosvc' |% {
    $svc=tasklist /svc /fi "services eq $_" /fo csv | convertfrom-csv; if ($svc.PID -gt 10) {kill $svc.PID -force -ea 0}
  }
  'trustedinstaller','tiworker','wuauclt','sihclient','usoclient','mousocoreworker','setuphost','systemsettings' |% {
    kill -name $_ -force -ea 0
  }
  cmd /c rd /s /q "%SystemDrive%\`$WINDOWS.~BT\Sources\Panther"
  cmd /c rd /s /q "%SystemRoot%\system32\catroot2" # because kill $svc.PID ;)
  cmd /c rd /s /q "%SystemRoot%\SoftwareDistribution"
  cmd /c del /f /q "%SystemRoot%\Logs\WindowsUpdate\*"
  cmd /c del /f /q "%ProgramData%\USOPrivate\UpdateStore\*" # clearing USO suggested by abbodi1406 @ MDL
  cmd /c del /s /f /q "%ProgramData%\USOShared\Logs\*"
  cmd /c rd /s /q "%ProgramFiles%\UNP"
  try { Get-WindowsUpdateLog -LogPath $env:temp\temp.log -ForceFlush -Confirm:$False -ea 0 } catch {}
  <# AveYo: comment reg lines below to NOT hide 11 unsupported/upgrade nag #>
  reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersionInfo" /d 25H1 /f # 25H1 NOT a typo ;)
  reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersion" /d 1 /t reg_dword /f
  reg add "HKCU\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /d 0 /t reg_dword /f # hide desktop watermark
  reg add "HKCU\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /d 0 /t reg_dword /f # suggested by awuctl @ MDL
  net1 start wuauserv; net1 start bits; net1 start usosvc
  UsoClient RefreshSettings
  sleep 5
  start ms-settings:windowsupdate
  #timeout -1
} ; start -verb runas powershell -args "-nop -c & {`n`n$($_Paste_in_Powershell -replace '"','\"')}"
$_Press_Enter
