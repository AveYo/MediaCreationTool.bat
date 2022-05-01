@(set '(=)||' <# lean and mean cmd / powershell hybrid #> @'

::# get 11 via Windows Update on 'unsupported' PC, with /Product Server dynamic trick
::# if wu download stuck at 0% use OfflineInsiderEnroll by whatever127 and abbodi1406
::# V8: av false & fake positive? reject humanity (powershell), return to monke (cmd) 

@echo off & title get 11 via Windows Update on 'unsupported' PC || AveYo 2022
if /i "%~f0" neq "%ProgramData%\get11.cmd" goto setup
set CLI=%*& set SOURCES=%SystemDrive%\$WINDOWS.~BT\Sources&;
if not defined CLI (exit /b) else if not exist %SOURCES%\SetupHost.exe (exit /b)
if not exist %SOURCES%\SetupCore.exe mklink /h %SOURCES%\SetupCore.exe %SOURCES%\SetupHost.exe 
powershell -win 1 -nop -c ";"
set /a restart_application=0x800705BB & call set CLI=%%CLI:%1 =%%&;
set /a incorrect_parameter=0x80070057 & set SRV=%CLI:/Product Client =%&; 
set /a launch_option_error=0xc190010a & set SRV=/Product Server /Telemetry Disable /Compat IgnoreWarning %SRV:/Product Server =%&;
for /f %%W in ('tasklist /nh /fi "imagename eq setupprep.exe"') do if /i %%W==setupprep.exe set SRV=%CLI%&;
%SOURCES%\SetupCore.exe %SRV% 
if %errorlevel% == %restart_application% %SOURCES%\SetupCore.exe %SRV%
exit /b

:setup
::# elevate with native shell by AveYo
>nul reg add hkcu\software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r set \"f0=%%2\"& call \"%%2\" %%3"& set _= %* 
>nul fltmc|| if "%f0%" neq "%~f0" (cd.>"%temp%\runas.Admin" & start "%~n0" /high "%temp%\runas.Admin" "%~f0" "%_:"=""%" & exit /b)

::# lean xp+ color macros by AveYo:  %<%:af " hello "%>>%  &  %<%:cf " w\"or\"ld "%>%   for single \ / " use .%|%\  .%|%/  \"%|%\"
for /f "delims=:" %%s in ('echo;prompt $h$s$h:^|cmd /d') do set "|=%%s"&set ">>=\..\c nul&set /p s=%%s%%s%%s%%s%%s%%s%%s<nul&popd"
set "<=pushd "%appdata%"&2>nul findstr /c:\ /a" &set ">=%>>%&echo;" &set "|=%|:~0,1%" &set /p s=\<nul>"%appdata%\c"

::# toggle when launched without arguments, else jump to arguments: "install" or "remove" 
set CLI=%*& set IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options&;
wmic /namespace:"\\root\subscription" path __EventFilter where Name="Skip TPM Check on Dynamic Update" delete >nul 2>nul & rem v1
reg delete "%IFEO%\vdsldr.exe" /f 2>nul & rem v2 - v5
if /i "%CLI%"=="" reg query "%IFEO%\SetupHost.exe\0" /v Debugger >nul 2>nul && goto remove || goto install
if /i "%~1"=="install" (goto install) else if /i "%~1"=="remove" goto remove

:install
@prompt $H & echo on
copy /y "%~f0" "%ProgramData%\get11.cmd"
reg add "%IFEO%\SetupHost.exe" /f /v UseFilter /d 1 /t reg_dword
reg add "%IFEO%\SetupHost.exe\0" /f /v FilterFullPath /d "%SystemDrive%\$WINDOWS.~BT\Sources\SetupHost.exe"
reg add "%IFEO%\SetupHost.exe\0" /f /v Debugger /d "%ProgramData%\get11.cmd"
@echo off & echo;
%<%:2f " Skip TPM Check on Dynamic Update v8 [INSTALLED] run again to remove "%>%
if /i "%CLI%"=="" timeout /t 7
exit /b

:remove
@prompt $H & echo on
del /f /q "%ProgramData%\get11.cmd"
reg delete "%IFEO%\SetupHost.exe" /f 
@echo off & echo;
%<%:df " Skip TPM Check on Dynamic Update v8 [REMOVED] run again to install "%>%
if /i "%CLI%"=="" timeout /t 7
exit /b 

'@); $0 = "$env:temp\Skip_TPM_Check_on_Dynamic_Update.cmd"; ${(=)||} | out-file $0 -encoding default -force; & $0
# press enter
 
