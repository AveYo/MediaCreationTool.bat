@title No 11 Setup Checks on Boot & set args=%1& echo off
::#  run from the root of the USB drive or extracted ISO files to remove all setup checks from winsetup.dll
::#  can finally boot from new Windows 11 media inside VirtualBox
 
pushd "%~dp0" & if defined args pushd %args% & if not exist sources\boot.wim popd
if not exist sources\boot.wim echo; SOURCES\BOOT.WIM NOT FOUND! & timeout /t 5 & exit/b
fltmc>nul || (set _="%~f0" %* & powershell -nop -c start -verb runas cmd \"/d/x/rcall $env:_\"  & exit/b)
dism /cleanup-wim & set BOOT=%SystemDrive%\ESD\BOOT& mkdir %SystemDrive%\ESD\BOOT >nul 2>nul
dism /mount-wim /wimfile:sources\boot.wim /index:2 /mountdir:%BOOT% & (set DO=commit) & if exist %ini% (set DO=discard)
pushd %BOOT%\sources & takeown /f winsetup.dll /a >nul & icacls winsetup.dll /grant administrators:f >nul
set c1= $b = [System.IO.File]::ReadAllBytes('winsetup.dll'); $h = [System.BitConverter]::ToString($b)-replace'-'
set c2= $s = [BitConverter]::ToString([Text.Encoding]::Unicode.GetBytes('Module_Init_HWRequirements'))-replace'-'
set c3= $i = ($h.IndexOf($s)/2); $r = [Text.Encoding]::Unicode.GetBytes('Module_Init_GatherDiskInfo'); $l = $r.Length
set c4= if ($i -gt 1) {for ($k=0;$k -lt $l;$k++) {$b[$i+$k] = $r[$k]} ; [System.IO.File]::WriteAllBytes('winsetup.dll',$b)}
if not exist winsetup.dll (set c1=&set c2=&set c3=&set c4=) else copy /y winsetup.dll "%temp%\" >nul 2>nul
powershell -nop -c %c1%;%c2%;%c3%;%c4%; & popd & if defined c1 fc "%BOOT%\sources\winsetup.dll" "%TEMP%\winsetup.dll"
dism /unmount-wim /mountdir:%BOOT% /commit & rmdir /s /q %BOOT% >nul 2>nul & del /f /q sources\appraiserres.dll>nul
if not defined args choice /c EX1T
::