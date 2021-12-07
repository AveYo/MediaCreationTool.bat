@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit/b
#:: double-click to run or just copy-paste into powershell - it's a standalone hybrid script
#:: v5 of the toggle script uses programdata instead of system32, no longer deletes appraiserres.dll, and clears bypass folder 
#:: uses IFEO to attach to Virtual Disk Service Loader process running during setup, then creates a bypass dir
#:: it must also do some ping-pong renaming of vdsldr in programdata
#:: you probably don't need to have it installed at all times - just when doing feature updates or manual setup within windows
#:: hence the on off toggle just by running the script again 
#:: can get 11 release beta or dev builds via Windows Update after using OfflineInsiderEnroll by whatever127 and abbodi1406 

$_Paste_in_Powershell = {
  $N = "Skip TPM Check on Dynamic Update"; $X = @("' $N (c) AveYo 2021 : v4 IFEO-based with no flashing cmd window") 
  $X+= 'C = "cmd /q AveYo /d/x/r pushd %systemdrive%\\$windows.~bt\\Sources\\Panther && mkdir Appraiser_Data.ini\\AveYo&"'
  $X+= 'M = "pushd %allusersprofile%& ren vd.exe vdsldr.exe &robocopy ""%systemroot%/system32/"" ""./"" ""vdsldr.exe""&"'
  $X+= 'D = "ren vdsldr.exe vd.exe& start vd.exe -Embedding" : CreateObject("WScript.Shell").Run C & M & D, 0, False'    
  $K = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vdsldr.exe'
  $P = [Environment]::GetFolderPath('CommonApplicationData'); $F = join-path $P '11tpm.vbs'; $V = "wscript $F //B //T:5" 
  if (test-path $K) {
    remove-item $K -force -ea 0 >''; del $F -force -ea 0; del (join-path $P 'vd.exe') -force -ea 0
    write-host -fore 0xf -back 0xd "`n $N v5 [REMOVED] run again to install "
  } else {
    new-item $K -force -ea 0 >''; set-itemproperty $K 'Debugger' $V -force -ea 0; [io.file]::WriteAllText($F, $X-join"`r`n")
    write-host -fore 0xf -back 0x2 "`n $N v5 [INSTALLED] run again to remove "
  } ;  rmdir $([Environment]::SystemDirectory[0]+':\\$Windows.~BT\\Sources\\Panther') -rec -force -ea 0; timeout /t 5
} ; start powershell -args "-nop -c & {`n`n$($_Paste_in_Powershell-replace'"','\"')}" -verb runas
$_Press_Enter
#::
