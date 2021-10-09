@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit/b
#:: double-click to run or just copy-paste into powershell - it's a standalone hybrid script
#:: v2 of the toggle script comes to the aid of outliers for whom v1 did not work due to various reasons (broken/blocked/slow wmi)
#:: uses IFEO instead to attach to the same Virtual Disk Service Loader process running during setup, then launches a cmd erase 
#:: of appraiserres.dll - but it must also do some ping-pong renaming of the exe in system32\11 - great implementation nonetheless 
#:: (for simplicity did not use powershell invoking CreateProcess and DebugActiveProcessStop to overcome IFEO constrains)
#:: in v2 the cmd window will briefly flash while running diskmgmt - so it is not "better" per-se. just more compatible / reactive
#:: you probably don't need to have it installed at all times - just when doing feature updates or manual setup within windows
#:: hence the on off toggle just by running the script again

$_Paste_in_Powershell = {
  $N = 'Skip TPM Check on Dynamic Update'
  $0 = sp 'HKLM:\SYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 1 -type dword -force -ea 0
  $B = gwmi -Class __FilterToConsumerBinding -Namespace 'root\subscription' -Filter "Filter = ""__eventfilter.name='$N'""" -ea 0
  $C = gwmi -Class CommandLineEventConsumer -Namespace 'root\subscription' -Filter "Name='$N'" -ea 0
  $F = gwmi -Class __EventFilter -NameSpace 'root\subscription' -Filter "Name='$N'" -ea 0
  if ($B) { $B | rwmi } ; if ($C) { $C | rwmi } ; if ($F) { $F | rwmi }
  $C = "cmd /q $N (c) AveYo, 2021 /d/x/r>nul (erase /f/s/q %systemdrive%\`$windows.~bt\appraiserres.dll"
  $C+= '&md 11&cd 11&ren vd.exe vdsldr.exe&robocopy "../" "./" "vdsldr.exe"&ren vdsldr.exe vd.exe&start vd -Embedding)&rem;'
  $K = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vdsldr.exe'
  if (test-path $K) {ri $K -force -ea 0; write-host -fore 0xf -back 0xd "`n $N [REMOVED] run again to install "}
  else {$0=ni $K -force -ea 0;sp $K 'Debugger' $C -force; write-host -fore 0xf -back 0x2 "`n $N [INSTALLED] run again to remove "}
  timeout /t 5 } ; start -verb runas powershell -args "-nop -c & {`n`n$($_Paste_in_Powershell-replace'"','\"')}"
$_Press_Enter
#::