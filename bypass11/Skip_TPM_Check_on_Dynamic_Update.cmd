@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit/b
#:: double-click to run or just copy-paste into powershell - it's a standalone hybrid script

#:: v7 dynamically skips the anti-consumer windows 11 setup checks via /Product Server trick  
#:: it is most reliable, and only has a 'Windows Server' label cosmetic-ish difference
#:: works with:
#:: 11 setup via Windows Update (after using OfflineInsiderEnroll by whatever127 and abbodi1406)
#:: 11 setup via mounted iso / usb (use the Quick.. script for skipping 11 setup checks at boot)

$_Paste_in_Powershell = { $Code = @'
 $Nfo = 'Skip TPM Check on Dynamic Update v7, AveYo 2021'
 $Arg = (([environment]::get_CommandLine()-split'-[-]% ')[1]-split'.exe[\p{P}]? ')[1]
 foreach ($x in 'Product','DynamicUpdate','Telemetry') {$Arg = $Arg -replace $('\p{P}?/'+ $x +'\p{P}? \p{P}?[A-Z]+\p{P}? '),' '}
 $Cli = ' /DynamicUpdate Disable /Telemetry Disable ' + $Arg; $Srv = ' /Product Server' + $Cli
 $Dir = join-path $([Environment]::SystemDirectory[0..2]-join'') '$WINDOWS.~BT\Sources\'
 $Cfg = join-path $Dir 'EI.cfg'; $EI = '[Channel]' +[char]13+[char]10+ '_Default' +[char]13+[char]10
 $Exe = join-path $Dir 'SetupHost.exe'; $Inf = get-item -force -lit $Exe; [int]$Ver = $Inf.VersionInfo.FileBuildPart
 if ($Ver -ge 22000) {$Run = $Exe + $Srv} else {$Run = $Exe + $Cli}
 if ($Ver -ge 22000 -and !(test-path $Cfg)) {[io.file]::WriteAllText($Cfg, $EI)}

 $D=@(); $T=@(); $A=@(); $M=[AppDomain]::CurrentDomain.DefineDynamicAssembly(1,1).DefineDynamicModule(1) 
 foreach ($x in 0..2) {$D+=$M.DefineType('AveYo_'+$x,1179913,[ValueType])}; foreach ($x in 1..2) {$D+=$D[$x].MakeByRefType()}
 $S=[string]; $I=[int32]; $U=[uintptr]; $y=0; $z=0;  foreach ($x in $U,$U,$I,$I) {$9=$D[2].DefineField('f'+$y++,$x,6)}
 foreach ($x in $I,$S,$S,$S,$I,$I,$I,$I,$I,$I,$I,$I,[int16],[int16],$U,$U,$U,$U) {$9=$D[1].DefineField('f'+$z++,$x,6)}
 $9=$D[0].DefinePInvokeMethod('CreateProcess','kernel32',8214,1,[void],($S,$S,$I,$I,[bool],$I,$I,$S,$D[3],$D[4]),1,4)
 $9=$D[0].DefinePInvokeMethod('DebugActiveProcessStop','kernel32',8214,1,[void],($I),1,4)
 foreach ($x in 0..2) {$T+=$D[$x].CreateType()}; foreach ($x in 1..2) {$A+=[Activator]::CreateInstance($T[$x])}
 $R=$null, $Run, $null, $null, $false, 0x02000011, $null, $null, $A[0], $A[1] 
 $T[0].GetMethod('CreateProcess').invoke(0, $R); $T[0].GetMethod('DebugActiveProcessStop').invoke(0, $R[9].f2)
 $W=get-process -pid $R[9].f2 -ea 0; for (;;) {sleep 1; if (0-eq $R[9].f2 -or $null-eq $W -or $W.HasExited) {return} }
'@ -replace '\r?\n|\r', '; ' <# lines 20-29 are needed for escaping ifeo, remain calm ;) #>  

 $IFEO = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SetupHost.exe'
 $Prog = join-path $([Environment]::SystemDirectory[0..2] -join '') '$WINDOWS.~BT\Sources\SetupHost.exe'
 $Skip = "powershell -win 1 -nop -c iex (get-itemproperty '$IFEO\0' 'Code' -ea 0).Code; write-host --%"
 if (test-path "$IFEO\0") {
   remove-item $IFEO -rec -force -ea 0 >''
   write-host -fore 0xf -back 0xd "`n Skip TPM Check on Dynamic Update v7 [REMOVED] run again to install " 
 } else {                              
   new-item "$IFEO\0" -force -ea 0 >'' 
   set-itemproperty "$IFEO\0" 'Debugger' $Skip -force -ea 0; set-itemproperty "$IFEO\0" 'Code' $Code -force -ea 0
   set-itemproperty "$IFEO\0" 'FilterFullPath' $Prog -force -ea 0; set-itemproperty $IFEO 'UseFilter' 1 -type dword -force -ea 0
   write-host -fore 0xf -back 0x2 "`n Skip TPM Check on Dynamic Update v7 [INSTALLED] run again to remove "
 } 
 remove-item $($IFEO -replace 'SetupHost', 'vdsldr') -rec -force -ea 0 >''; rmdir (split-path $Prog) -rec -force -ea 0 >''
 $N = 'Skip TPM Check on Dynamic Update' <# also remove wmi-based v1 if somehow still installed, not just vdsldr-based v2 - v5 #>
 $U = 'root\subscription'; $C = gwmi -Class CommandLineEventConsumer -Namespace $U -Filter "Name='$N'" -ea 0 
 $B = gwmi -Class __FilterToConsumerBinding -Namespace $U -Filter "Filter = ""__eventfilter.name='$N'""" -ea 0
 $F = gwmi -Class __EventFilter -NameSpace $U -Filter "Name='$N'" -ea 0; $B,$C,$F |% {$_|rwmi -ea 0}; timeout /t 5
} ; start -verb runas powershell -args "-nop -c & {`n`n$($_Paste_in_Powershell-replace'"','\"')}"
$_Press_Enter
#::
