@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit/b
#:: double-click to run or just copy-paste into powershell - it's a standalone hybrid script
#:: v3 of the toggle script hides the flashing cmd window via vbs, and sets all reg overrides for good measure
#:: uses IFEO to attach to Virtual Disk Service Loader process running during setup, then erases appraiserres.dll
#:: it must also do some ping-pong renaming of vdsldr in system32\11
#:: you probably don't need to have it installed at all times - just when doing feature updates or manual setup within windows
#:: hence the on off toggle just by running the script again 

$_Paste_in_Powershell = {
  $N = "Skip TPM Check on Dynamic Update"; $X = @("' $N (c) AveYo 2021 : v3 IFEO-based with no flashing cmd window") 
  $X+= 'C = "cmd /q AveYo /d/x/r erase /f/s/q %systemdrive%\$windows.~bt\appraiserres.dll&"'
  $X+= 'M = "md 11&cd 11&ren vd.exe vdsldr.exe &robocopy ""../"" ""./"" ""vdsldr.exe""&ren vdsldr.exe vd.exe&"'
  $X+= 'D = "start vd.exe -Embedding" : CreateObject("WScript.Shell").Run C & M & D, 0, False'    
  $U = 'root\subscription'; $C = gwmi -Class CommandLineEventConsumer -Namespace $U -Filter "Name='$N'" -ea 0 
  $B = gwmi -Class __FilterToConsumerBinding -Namespace $U -Filter "Filter = ""__eventfilter.name='$N'""" -ea 0
  $F = gwmi -Class __EventFilter -NameSpace $U -Filter "Name='$N'" -ea 0; $B,$C,$F |% {$_|rwmi -ea 0} # undo v1
  $L = 'HKLM:\SYSTEM\Setup\LabConfig'; $M = 'HKLM:\SYSTEM\Setup\MoSetup'; $L,$M |% {ni $_ -force -ea 0 >''}
  'sCPU','sRAM','sSecureBoot','sStorage','sTPM' |% {sp $L "Bypas${_}Check" 1 -type dword -force -ea 0 >''}
  sp $M 'AllowUpgradesWithUnsupportedTPMOrCPU' 1 -type dword -force -ea 0 >''
  $K = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vdsldr.exe'
  $V = "wscript 11.vbs //B //T:5"; $S = [environment]::SystemDirectory; if (test-path $K) {
  ri $K -force -ea 0 >''; del "$S\11.vbs" -force -ea 0; rmdir "$S\11" -force -re -ea 0
  write-host -fore 0xf -back 0xd "`n $N v3 [REMOVED] run again to install " } else {
  ni $K -force -ea 0 >''; sp $K Debugger $V -force -ea 0; [io.file]::WriteAllText("$S\11.vbs", $X-join"`r`n")
  write-host -fore 0xf -back 0x2 "`n $N v3 [INSTALLED] run again to remove " } ; timeout /t 5
} ; start -verb runas powershell -args "-nop -c & {`n`n$($_Paste_in_Powershell-replace'"','\"')}"
$_Press_Enter
#::
