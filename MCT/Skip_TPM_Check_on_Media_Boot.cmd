@echo off & (set media=%1) & rem title Skip TPM Check on Media Boot 
::#  run from the root of the USB drive or ISO files to add reg overrides in sources\boot.wim via winpeshl.ini

pushd "%~dp0" & if defined media pushd %media% & if not exist sources\boot.wim popd
if not exist sources\boot.wim echo; SOURCES\BOOT.WIM NOT FOUND! & timeout /t 5 & exit/b
fltmc>nul || (set _="%~f0" %* & powershell -nop -c start -verb runas cmd \"/d/x/rcall $env:_\"  & exit/b)
dism /cleanup-wim & mkdir C:\ESD\AveYo>nul 2>nul & set ini=C:\ESD\AveYo\Windows\System32\winpeshl.ini & (set By=By)
dism /mount-wim /wimfile:sources\boot.wim /index:2 /mountdir:C:\ESD\AveYo & (set DO=commit) & if exist %ini% (set DO=discard)
 >%ini% echo;[LaunchApps]
>>%ini% echo;cmd, "/c reg add HKLM\SYSTEM\Setup\LabConfig /v %By%passTPMCheck /d 1 /t reg_dword /f"
>>%ini% echo;cmd, "/c reg add HKLM\SYSTEM\Setup\LabConfig /v %By%passSecureBootCheck /d 1 /t reg_dword /f"
>>%ini% echo;cmd, "/c reg add HKLM\SYSTEM\Setup\LabConfig /v %By%passStorageCheck /d 1 /t reg_dword /f"
>>%ini% echo;cmd, "/c reg add HKLM\SYSTEM\Setup\LabConfig /v %By%passRAMCheck /d 1 /t reg_dword /f"
>>%ini% echo;%%SYSTEMDRIVE%%\setup.exe
echo;&echo;Windows\System32\winpeshl.ini &echo;----------------------------- &type %ini% &echo;-----------------------------&echo;
dism /unmount-wim /mountdir:C:\ESD\AveYo /%DO% & rmdir /s /q C:\ESD\AveYo & del /f /q sources\appraiserres.dll>nul
::