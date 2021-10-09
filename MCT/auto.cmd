@title Auto Upgrade without prompts + change edition support & (set media=%1) & color 1f& echo off

set OPTIONS1=/SelfHost /Auto Upgrade /MigChoice Upgrade /DynamicUpdate Enable /UpdateMedia Decline
set OPTIONS2=/Compat IgnoreWarning /MigrateDrivers All /ResizeRecoveryPartition Disable /ShowOOBE None 
set OPTIONS3=/Telemetry Disable /CompactOS Disable /SkipSummary /Eula Accept

if defined media (pushd %media%) else pushd "%~dp0"
for %%i in ("x86\" "x64\" "") do if exist "%%~isources\setupprep.exe" set "dir=%%~i"
pushd "%dir%sources" || (echo "%dir%sources" & timeout /t 5 & exit/b)

::# elevate so that workarounds can be set
fltmc>nul || (set _="%~f0" %*& powershell -nop -c start -verb runas cmd \"/d/x/rcall $env:_\"  &exit/b)

::# Skip TPM Check on Dynamic Update 11 snippet
call :skip_tpm_check_on_dynamic_update

::# current version query
set NT="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
for /f "tokens=2*" %%R in ('reg query %NT% /v EditionID /reg:64 2^>nul') do set "EditionID=%%S"
for /f "tokens=2*" %%R in ('reg query %NT% /v ProductName /reg:64 2^>nul') do set "ProductName=%%S"
for /f "tokens=2*" %%R in ('reg query %NT% /v CurrentBuildNumber /reg:64 2^>nul') do set "Build=%%S"

::# media selection from PID.txt - get it verbosely in case auto.cmd is reused without MediaCreationTool.bat
set Value=& set Edition=& if exist PID.txt for /f "delims=" %%v in (PID.txt) do (set %%v)2>nul
if defined Value for %%K in (
  Cloud.V3WVW-N2PV2-CGWC3-34QGF-VMJ2C                   CloudN.NH9J3-68WK7-6FB93-4K3DF-DJ4F6 
  Core.YTMG3-N6DKC-DKB77-7M9GH-8HVX7                    CoreN.4CPRK-NM3K3-X6XXQ-RXX86-WXCHW
  CoreSingleLanguage.BT79Q-G7N6G-PGBYW-4YWX6-6F4BT      CoreCountrySpecific.N2434-X9D7W-8PF6X-8DV9T-8TYMD
  Professional.VK7JG-NPHTM-C97JM-9MPGT-3V66T            ProfessionalN.2B87N-8KFHP-DKV6R-Y2C8J-PKCKT
  ProfessionalEducation.8PTT6-RNW4C-6V7J2-C2D3X-MHBPB   ProfessionalEducationN.GJTYN-HDMQY-FRR76-HVGC7-QPF8P
  ProfessionalWorkstation.DXG7C-N36C4-C4HTG-X4T3X-2YV77 ProfessionalWorkstationN.WYPNQ-8C467-V2W6J-TX4WX-WT2RQ
  Education.YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY               EducationN.84NGF-MHBT6-FXBX8-QWJK7-DRR8H
  Enterprise.NPPR9-FWDCX-D2C8J-H872K-2YT43              EnterpriseN.DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4
) do if /i %%~xK equ .%Value% (set Edition=%%~nK)
if defined Edition if /i "%Edition%" neq "%EditionID%" call :rename %Edition% & goto setup force edition if selected

::# auto upgrade with edition lie workaround to keep files and apps - all 1904x builds allow up/downgrade between them
if not exist ei.cfg (set vol=0) else (set vol=1)
if /i "Embedded"            == "%EditionID%" if %vol% == 1 (call :rename Enterprise)  else (call :rename Professional)
if /i "IoTEnterpriseS"      == "%EditionID%" if %vol% == 1 (call :rename Enterprise)  else (call :rename Professional)
if /i "EnterpriseS"         == "%EditionID%" if %vol% == 1 (call :rename Enterprise)  else (call :rename Professional)
if /i "EnterpriseSN"        == "%EditionID%" if %vol% == 1 (call :rename EnterpriseN) else (call :rename ProfessionalN)
if /i "IoTEnterprise"       == "%EditionID%" if %vol% == 0 (call :rename Professional)
if /i "Enterprise"          == "%EditionID%" if %vol% == 0 (call :rename Professional)
if /i "EnterpriseN"         == "%EditionID%" if %vol% == 0 (call :rename ProfessionalN)
if /i "CoreCountrySpecific" == "%EditionID%" if %vol% == 1 (call :rename Professional)
if /i "CoreSingleLanguage"  == "%EditionID%" if %vol% == 1 (call :rename Professional)
if /i "Core"                == "%EditionID%" if %vol% == 1 (call :rename Professional)
if /i "CoreN"               == "%EditionID%" if %vol% == 1 (call :rename ProfessionalN)
if /i ""                    == "%EditionID%" (call :rename Professional)

:setup
start "auto" setupprep.exe %OPTIONS1% %OPTIONS2% %OPTIONS3%
exit/b

:rename EditionID
set NT="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
(reg query  %NT% /v ProductName_undo /reg:32 || reg add %NT% /v ProductName_undo /d "%ProductName%" /f /reg:32
 reg query  %NT% /v ProductName_undo /reg:64 || reg add %NT% /v ProductName_undo /d "%ProductName%" /f /reg:64
 reg query  %NT% /v EditionID_undo   /reg:32 || reg add %NT% /v EditionID_undo   /d "%EditionID%"   /f /reg:32
 reg query  %NT% /v EditionID_undo   /reg:64 || reg add %NT% /v EditionID_undo   /d "%EditionID%"   /f /reg:64
 reg delete %NT% /v ProductName   /f /reg:32  & reg add %NT% /v EditionID /d "%~1" /f /reg:32
 reg delete %NT% /v ProductName   /f /reg:64  & reg add %NT% /v EditionID /d "%~1" /f /reg:64
) >nul 2>nul &exit/b

:skip_tpm_check_on_dynamic_update - also available as standalone toggle script in the MCT subfolder
set "0=%~f0"& powershell -nop -c "iex ([io.file]::ReadAllText($env:0)-split'skip\:tpm.*')[1];" &exit/b skip:tpm
  $S = gi -force 'setupprep.exe' -ea 0; if ($S.VersionInfo.FileBuildPart -lt 22000) {return} #:: abort if not 11 media
  $C = "cmd /q $N (c) AveYo, 2021 /d/x/r>nul (erase /f/s/q %systemdrive%\`$windows.~bt\appraiserres.dll"
  $C+= '&md 11&cd 11&ren vd.exe vdsldr.exe&robocopy "../" "./" "vdsldr.exe"&ren vdsldr.exe vd.exe&start vd -Embedding)&rem;'
  $K = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vdsldr.exe'
  $0 = ni $K -force -ea 0; sp $K Debugger $C -force -ea 0
  $0 = sp HKLM:\SYSTEM\Setup\MoSetup 'AllowUpgradesWithUnsupportedTPMOrCPU' 1 -type dword -force -ea 0
#:: skip:tpm
