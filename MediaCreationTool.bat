@goto latest at github.com/AveYo/MediaCreationTool.bat
:Universal MCT wrapper script for all Windows 10/11 versions from 1507 to 21H2!
:: Nothing but Microsoft-hosted source links and no third-party tools; script just configures an xml and starts MCT
:: Ingenious support for business editions (Enterprise / VL) selecting language, x86, x64 or AiO inside the MCT GUI
:: Changelog: 2022.03.20 stable
:: - all issues ironed out; upgrade keeping files from Eval editions too; pickup $ISO$ dir content to add on media
:: - DU in 11: auto installs 22000.556 atm; older skip_11_checks, without Server label; Home offline local account
:: on upgrade: latest build, on offline install: 11 22000.318 / 21H2 19044.1288 / 21H1 19043.1348 / 20H2 19042.1052

::# uncomment to skip GUI dialog for MCT choice: 1507 to 2109 / 11 - or rename script: "21H2 MediaCreationTool.bat"
rem set MCT=2110

::# uncomment to start auto upgrade setup directly (no prompts) - or rename script: "auto 11 MediaCreationTool.bat"
rem set /a AUTO=1

::# uncomment to start create iso directly in current folder - or rename script:   "iso 20H2 MediaCreationTool.bat"
rem set /a ISO=1

::# uncomment and change autodetected MediaEdition - or rename script:  "enterprise iso 2009 MediaCreationTool.bat"
rem set EDITION=Enterprise

::# uncomment and change autodetected MediaLangCode - or rename script:   "de-DE home 11 iso MediaCreationTool.bat"
rem set LANGCODE=en-US

::# uncomment and change autodetected MediaArch - or rename script:  "x64 iso 1909 Education MediaCreationTool.bat"
rem set ARCH=x64

::# uncomment and change autodetected KEY - or rename script / provide via commandline - not needed for generic key
rem set KEY=NPPR9-FWDCX-D2C8J-H872K-2YT43

::# uncomment to disable dynamic update for setup sources - or rename script: no_update 21H2 MediaCreationTool.bat"
rem set /a NO_UPDATE=1

::# uncomment to not add EI.cfg PID.txt auto.cmd $ISO$ dir content - or rename script:  "def MediaCreationTool.bat"
::# this will create a default, untouched MCT media 
rem set /a DEF=1

::# comment to not use recommended windows setup options that give the least amount of issues when doing upgrades
set OPTIONS=%OPTIONS% /Compat IgnoreWarning /MigrateDrivers All /ResizeRecoveryPartition Disable /ShowOOBE None

::# comment to not disable setup telemetry / disable Compact OS
set OPTIONS=%OPTIONS% /Telemetry Disable /CompactOS Disable

::# comment to not unhide Enterprise for 1709+ in products.xml
set /a UNHIDE_BUSINESS=1

::# comment to not insert Enterprise esd links for 1607,1703 or update links for 1909,2004,20H2,21H2,11 in products.xml
set /a INSERT_BUSINESS=1

::# MCT Version choice dialog items and default-index [11]
set VERSIONS=1507,1511,1607,1703,1709,1803,1809,1903,1909,20H1,20H2,21H1,21H2,11
set /a dV=14

::# MCT Preset choice dialog items and default-index [Select in MCT]
set PRESETS=^&Auto Upgrade,Auto ^&ISO,Auto ^&USB,^&Select,MCT ^&Defaults
set /a dP=4

:begin
call :reg_query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuildNumber"     OS_VERSION
call :reg_query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "DisplayVersion"         OS_VID
call :reg_query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "EditionID"              OS_EDITION
call :reg_query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductName"            OS_PRODUCT
call :reg_query "HKU\S-1-5-18\Control Panel\Desktop\MuiCached" "MachinePreferredUILanguages" OS_LANGCODE
for %%s in (%OS_LANGCODE%) do set "OS_LANGCODE=%%s"
set "OS_ARCH=x64" & if "%PROCESSOR_ARCHITECTURE:~-2%" equ "86" if not defined PROCESSOR_ARCHITEW6432 set "OS_ARCH=x86"

::# parse MCT choice from script name or commandline - accepts both formats: 1909 or 19H2 etc.
for %%V in (1.1507 2.1511 3.1607 4.1703 5.1709 6.1803 7.1809 8.1903 8.19H1 9.1909 9.19H2 10.2004 10.20H1 11.2009 11.20H2 12.2104
 12.21H1 13.2109 13.21H2 14.2110 14.11) do for %%s in (%MCT% %~n0 %*) do if /i %%~xV equ .%%~s set "MCT=%%~nV" & set "VID=%%~s"
if defined MCT if not defined VID set "MCT="

::# parse AUTO from script name or commandline - starts unattended upgrade / in-place repair / cross-edition
for %%s in (%~n0 %*) do if /i %%s equ auto set /a AUTO=1
if defined AUTO set /a PRE=1 & if not defined MCT set /a MCT=%dV% & if %OS_VERSION%0 lss 102400 set /a MCT=13

::# parse ISO from script name or commandline - starts media creation with selection
for %%s in (%~n0 %*) do if /i %%s equ iso set /a ISO=1
if defined ISO set /a PRE=2 & if defined AUTO (set AUTO=)

::# parse EDITION from script name or commandline - accept one of the staged editions in MCT install.esd - see sources\product.ini
set _=%EDITION% %~n0 %*& rem ::# also accepts the alternative names: Home, HomeN, Pro, ProN, Edu, EduN
for %%s in (%_:Home=Core% %_:Pro =Professional % %_:ProN=ProfessionalN% %_:Edu =Education % %_:EduN=EducationN%) do (
for %%E in ( ProfessionalEducation ProfessionalEducationN ProfessionalWorkstation ProfessionalWorkstationN Cloud CloudN
 Core CoreN CoreSingleLanguage CoreCountrySpecific Professional ProfessionalN Education EducationN Enterprise EnterpriseN
) do if /i %%s equ %%E set "EDITION=%%E")

::# parse LANGCODE from script name or commandline - accepts any words starting with xy-
for %%s in (%~n0 %*) do set ".=%%~s" & for /f %%C in ('cmd /q /v:on /c echo;!.:~2^,1!') do if "%%C" equ "-" set "LANGCODE=%%s"

::# parse ARCH from script name or commandline - no, it does not accept "both"
for %%s in (%~n0 %*) do for %%A in (x86 x64) do if /i %%s equ %%A set "ARCH=%%A"

::# parse KEY from script name or commandline - accepts the format: AAAAA-VVVVV-EEEEE-YYYYY-OOOOO
for %%s in (%KEY% %~n0 %*) do for /f "tokens=1-5 delims=-" %%A in ("%%s") do if "%%E" neq "" set "PKEY=%%s" & set "KEY="
if defined PKEY set "PKEY1=%PKEY:~-1%" & set "PKEY28=%PKEY:~28,1%"
if defined EDITION if "%PKEY1%" equ "%PKEY28%" (set "KEY=%PKEY%") else set "PKEY="

::# parse NO_UPDATE from script name or commandline - download latest DU for sources or not
for %%s in (%~n0 %*) do if /i %%s equ no_update set "NO_UPDATE=1"
if defined NO_UPDATE (set OPTIONS=%OPTIONS% /DynamicUpdate Disable) else (set OPTIONS=%OPTIONS% /DynamicUpdate Enable)

::# parse DEF from script name or commandline - dont add $ISO$\, PID.txt, auto.cmd, Skip TPM (if applicable) to created media
for %%s in (%~n0 %*) do if /i %%s equ def set "DEF=def"
::# hint: setup can run a script before logon, if present at $ISO$\sources\$OEM$\$$\Setup\Scripts\setupcomplete.cmd or OOBE.cmd

::# parse HIDE from script name or commandline - hide script window while awaiting MCT processing (new default is to minimize)
set /a hide=2 & for %%s in (%~n0 %*) do if /i %%s equ hide set /a hide=1

::# auto detected / selected media preset
if defined EDITION (set MEDIA_EDITION=%EDITION%) else (set MEDIA_EDITION=%OS_EDITION%)
if defined LANGCODE (set MEDIA_LANGCODE=%LANGCODE%) else (set MEDIA_LANGCODE=%OS_LANGCODE%)
if defined ARCH (set MEDIA_ARCH=%ARCH%) else (set MEDIA_ARCH=%OS_ARCH%)
if not defined VID (set VID=%OS_VID%)

::# edition fallback to ones that MCT supports
(set MEDIA_EDITION=%MEDIA_EDITION:Eval=%)
(set MEDIA_EDITION=%MEDIA_EDITION:Embedded=Enterprise%)
(set MEDIA_EDITION=%MEDIA_EDITION:EnterpriseS=Enterprise%)
(set MEDIA_EDITION=%MEDIA_EDITION:IoTEnterprise=Enterprise%)
(set MEDIA_EDITION=%MEDIA_EDITION:IoTEnterpriseS=Enterprise%)

::# get previous GUI selection if self elevated and skip to choice
for %%s in (%*) do for %%P in (1 2 3 4) do if %%~ns gtr 0 if %%~ns lss 15 if %%~xs. equ .%%P. set /a PRE=%%P & set /a MCT=%%~ns

::# write auto media preset hint
%<%:f0 " Detected Media "%>>% & if defined MCT %<%:5f " %VID% "%>>%
%<%:6f " %MEDIA_LANGCODE% "%>>%  &  %<%:9f " %MEDIA_EDITION% "%>>%  &  %<%:2f " %MEDIA_ARCH% "%>%
echo;
%<%:1f "1  Auto Upgrade  : MCT gets detected media, script assists setupprep for upgrading "%>%
%<%:1f "2    Auto ISO    : MCT gets detected media, script assists making ISO here | C:ESD "%>%
%<%:1f "3    Auto USB    : MCT gets detected media, script assists making USB stick target "%>%
%<%:1f "4     Select     : MCT gets selected Edition, Language, Arch onto specified target "%>%
%<%:1f "5  MCT Defaults  : MCT runs unassisted, creating media without script modification "%>%
echo;
%<%:17 "1-4 adds to media: PID.txt, EI.cfg, $ISO$ dir, auto.cmd for upgrade and tpm checks "%>%
%<%:17 "can rename script: "%>>% & %<%:1f "def MediaCreationTool.bat"%>>% & %<%:17 " to always create unmodified MCT media "%>%

::# show more responsive MCT + PRE pseudo-menu dialog or separate choice dialog instances if either MCT or PRE are set
if "%MCT%%PRE%"=="" call :choices2 MCT "%VERSIONS%" %dV% "MCT Version" PRE "%PRESETS%" %dP% "MCT Preset" 11 white 0x005a9e 320
if %MCT%0 lss 1 if %PRE%0 gtr 1 call :choices MCT "%VERSIONS%" %dV% "MCT Version" 11 white 0x005a9e 320
if %MCT%0 gtr 1 if %PRE%0 lss 1 call :choices PRE "%PRESETS%"  %dP% "MCT Preset"  11 white 0x005a9e 320
if %MCT%0 gtr 1 if %PRE%0 lss 1 goto choice-0 = cancel
goto choice-%MCT%

:choice-14
set "VER=22000" & set "VID=11" & set "CB=22000.318.211104-1236.co_release_svc_refresh" & set "CT=2021/11/" & set "CC=2.0"
set "CAB=https://download.microsoft.com/download/1/b/4/1b4e06e2-767a-4c9a-9899-230fe94ba530/products_Win11_20211115.cab"
set "EXE=https://software-download.microsoft.com/download/pr/888969d5-f34g-4e03-ac9d-1f9786c69161/MediaCreationToolW11.exe"
goto process ::# windows 11 : usability and ui downgrade, and even more ChrEdge bloat (but somewhat snappier multitasking)

:choice-13
set "VER=19044" & set "VID=21H2" & set "CB=19044.1288.211006-0501.21h2_release_svc_refresh" & set "CT=2021/11/" & set "CC=1.4.1"
set "CAB=https://download.microsoft.com/download/3/9/6/396ae429-afb2-49da-81d8-c16c6782d082/products_Win10_20211115.cab"
set "EXE=https://download.microsoft.com/download/b/0/5/b053c6bc-fc07-4785-a66a-63c5aeb715a9/MediaCreationTool21H2.exe"
goto process ::# refreshed 19041 base with integrated 21H2 enablement package - current

:choice-12
set "VER=19043" & set "VID=21H1" & set "CB=19043.1288.211006-0459.21h1_release_svc_refresh" & set "CT=2021/10/" & set "CC=1.4.1"
if %INSERT_BUSINESS%0 gtr 1 set "CB=19043.1348.211103-2252.21h1_release_svc_refresh" & set "CT=2021/11/"
set "CAB=https://download.microsoft.com/download/8/3/e/83e5badb-90bd-45c0-b868-28ada88230a0/products_win10_20211029.cab"
set "EXE=https://download.microsoft.com/download/d/5/2/d528a4e0-03f3-452d-a98e-3e479226d166/MediaCreationTool21H1.exe"
goto process ::# refreshed 19041 base with integrated 21H1 enablement package - newest (get this, then 19044 via WU ep of few kb)

:choice-11
set "VER=19042" & set "VID=20H2" & set "CB=19042.631.201119-0144.20h2_release_svc_refresh" & set "CT=2020/11/" & set "CC=1.4.1"
if %INSERT_BUSINESS%0 gtr 1 set "CB=19042.1052.210606-1844.20h2_release_svc_refresh" & set "CT=2021/07/"
set "CAB=https://download.microsoft.com/download/4/3/0/430e9adb-cf08-4b68-9032-eafca8378d42/products_20201119.cab"
set "EXE=https://download.microsoft.com/download/4/c/c/4cc6c15c-75a5-4d1b-a3fe-140a5e09c9ff/MediaCreationTool20H2.exe"
goto process ::# refreshed 19041 base with integrated 20H2 enablement package to mainly bundle ChrEdge

:choice-10
set "VER=19041" & set "VID=20H1" & set "CB=19041.508.200907-0256.vb_release_svc_refresh" & set "CT=2020/09/" & set "CC=1.4"
if %INSERT_BUSINESS%0 gtr 1 set "CB=19041.572.201009-1946.vb_release_svc_refresh" & set "CT=2020/11/"
set "CAB=https://download.microsoft.com/download/7/4/4/744ccd60-3203-4eea-bfa2-4d04e18a1552/products.cab"
set "EXE=https://software-download.microsoft.com/download/pr/8d71966f-05fd-4d64-900b-f49135257fa5/MediaCreationTool2004.exe"
goto process ::# visible improvements to windows update, defender, search, dx12, wsl, sandbox

:choice-9
set "VER=18363" & set "VID=19H2" & set "CB=18363.592.200109-2016.19h2_release_svc_refresh" & set "CT=2020/01/" & set "CC=1.3"
if %INSERT_BUSINESS%0 gtr 1 set "CB=18363.1139.201008-0514.19h2_release_svc_refresh" & set "CT=2020/11/"
set "CAB=https://download.microsoft.com/download/8/2/b/82b12fa5-cab6-4d37-8167-16630c6151eb/products_20200116.cab"
set "EXE=https://download.microsoft.com/download/c/0/b/c0b2b254-54f1-42de-bfe5-82effe499ee0/MediaCreationTool1909.exe"
goto process ::# refreshed 18362 base with integrated 19H2 enablement package to activate usability and security fixes

:choice-8
set "VER=18362" & set "VID=19H1" & set "CB=18362.356.190909-1636.19h1_release_svc_refresh" & set "CT=2019/09/" & set "CC=1.3"
set "CAB=https://download.microsoft.com/download/4/e/4/4e491657-24c8-4b7d-a8c2-b7e4d28670db/products_20190912.cab"
set "EXE=https://download.microsoft.com/download/9/8/8/9886d5ac-8d7c-4570-a3af-e887ce89cf65/MediaCreationTool1903.exe"
goto process ::# modern windows 10 starts here with proper memory allocation, cpu scheduling, security features

:choice-7
set "VER=17763" & set "VID=1809" & set "CB=17763.379.190312-0539.rs5_release_svc_refresh" & set "CT=2019/03/" & set "CC=1.3"
set "CAB=https://download.microsoft.com/download/8/E/8/8E852CBF-0BCC-454E-BDF5-60443569617C/products_20190314.cab"
set "EXE=https://software-download.microsoft.com/download/pr/MediaCreationTool1809.exe"
goto process ::# rather mediocre considering it is the base for ltsc 2019; less smooth than 1803 in games; intel pre-4th-gen buggy

:choice-6
set "VER=17134" & set "VID=1803" & set "CB=17134.112.180619-1212.rs4_release_svc_refresh" & set "CT=2018/07/" & set "CC=1.2"
set "CAB=https://download.microsoft.com/download/5/C/B/5CB83D2A-2D7E-4129-9AFE-353F8459AA8B/products_20180705.cab"
set "EXE=https://software-download.microsoft.com/download/pr/MediaCreationTool1803.exe"
goto process ::# update available to finally fix most standby memory issues that were present since 1703; intel pre-4th-gen buggy

:choice-5
set "VER=16299" & set "VID=1709" & set "CB=16299.125.171213-1220.rs3_release_svc_refresh" & set "CT=2018/01/" & set "CC=1.1"
set "CAB=https://download.microsoft.com/download/3/2/3/323D0F94-95D2-47DE-BB83-1D4AC3331190/products_20180105.cab"
set "EXE=https://download.microsoft.com/download/A/B/E/ABEE70FE-7DE8-472A-8893-5F69947DE0B1/MediaCreationTool.exe"
goto process ::# plagued by standby and other memory allocation bugs, fullscreen optimization issues, worst windows 10 ver by far

:choice-4
set "VER=15063" & set "VID=1703" & set "CB=15063.0.170317-1834.rs2_release" & set "CT=2017/03/" & set "CC=1.0"
if %INSERT_BUSINESS%0 gtr 1 set "CB=15063.0.170710-1358.rs2_release_svc_refresh" & set "CT=2017/07/"
rem set "XML=https://download.microsoft.com/download/2/E/B/2EBE3F9E-46F6-4DB8-9C84-659F7CCEDED1/products20170727.xml"
rem above refreshed xml often fails decrypting dual x86 + x64 - using rtm instead; the added enterprise + cloud are refreshed
set "CAB=https://download.microsoft.com/download/9/5/4/954415FD-D9D7-4E1F-8161-41B3A4E03D5E/products_20170317.cab"
set "EXE=https://download.microsoft.com/download/1/F/E/1FE453BE-89E0-4B6D-8FF8-35B8FA35EC3F/MediaCreationTool.exe"
goto process ::# some gamers still find it the best despite unfixed memory allocation bugs and exposed cpu flaws; can select Cloud

:choice-3
set "VER=14393" & set "VID=1607" & set "CB=14393.0.161119-1705.rs1_refresh" & set "CT=2017/01/" & set "CC=1.0"
set "CAB=https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/MediaCreationTool/prod/Products_20170116.cab"
set "EXE=https://download.microsoft.com/download/C/F/9/CF9862F9-3D22-4811-99E7-68CE3327DAE6/MediaCreationTool.exe"
goto process ::# snappy and stable for legacy hardware (but with excruciantly slow windows update process)

:choice-2
set "VER=10586" & set "VID=1511" & set "CB=10586.0.160426-1409.th2_refresh" & set "CT=2016/05/" & set "CC=1.0"
set "XML=https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/MediaCreationTool/prod/Products05242016.xml"
set "EXE=https://download.microsoft.com/download/1/C/4/1C41BC6B-F8AB-403B-B04E-C96ED6047488/MediaCreationTool.exe"
rem 1511 MCT exe works and can select Education - using 1607 one instead anyway for unified products.xml catalog 1.0 format
set "EXE=https://download.microsoft.com/download/C/F/9/CF9862F9-3D22-4811-99E7-68CE3327DAE6/MediaCreationTool.exe"
goto process ::# most would rather go with 1507 or 1607 instead, with little effort can apply latest ltsb updates on all editions

:choice-1
set "VER=10240" & set "VID=1507" & set "CB=10240.16393.150909-1450.th1_refresh" & set "CT=2015/09/" & set "CC=1.0"
set "XML=https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/MediaCreationTool/prod/Products09232015_2.xml"
set "EXE=https://download.microsoft.com/download/1/C/8/1C8BAF5C-9B7E-44FB-A90A-F58590B5DF7B/v2.0/MediaCreationToolx64.exe"
set "EXE32=https://download.microsoft.com/download/1/C/8/1C8BAF5C-9B7E-44FB-A90A-F58590B5DF7B/v2.0/MediaCreationTool.exe"
if /i "%PROCESSOR_ARCHITECTURE%" equ "x86" if not defined PROCESSOR_ARCHITEW6432 set "EXE=%EXE32%"
rem 1507 MCT exe works but cant select Education - using 1607 one instead anyway for unified products.xml catalog 1.0 format
set "EXE=https://download.microsoft.com/download/C/F/9/CF9862F9-3D22-4811-99E7-68CE3327DAE6/MediaCreationTool.exe"
goto process ::# fastest for potato PCs (but with excruciantly slow windows update process)

:choice- ;( something happened (broken environment/powershell?) and should cancel, but continue with defaults instead
set /a MCT=%dv% & set /a PRE=%dP% & goto choice-%dV%

:choice-0
%<%:0c " CANCELED "%>% & timeout /t 3 >nul & exit /b

:latest unified console appearance under 7 - 11
@echo off& title MCT& set __COMPAT_LAYER=Installer& chcp 437 >nul& set set=& for %%s in (%*) do if /i %%s equ set (set set=1)
if not defined set set /a BackClr=0x1 & set /a TextClr=0xf & set /a Columns=32 & set /a Lines=120 & set /a Buff=9999
if not defined set set /a SColors=BackClr*16+TextClr & set /a WSize=Columns*256*256+Lines & set /a BSize=Buff*256*256+Lines
if not defined set for %%s in ("HKCU\Console\MCT") do (
 reg add HKCU\Console /v ForceV2 /d 0x01 /t reg_dword /f & reg add %%s /v ScreenColors /d %SColors% /t reg_dword /f
 reg add %%s /v ColorTable00 /d 0x000000 /t reg_dword /f & reg add %%s /v ColorTable08 /d 0x767676 /t reg_dword /f
 reg add %%s /v ColorTable01 /d 0x9e5a00 /t reg_dword /f & reg add %%s /v ColorTable09 /d 0xff783b /t reg_dword /f
 reg add %%s /v ColorTable02 /d 0x0ea113 /t reg_dword /f & reg add %%s /v ColorTable10 /d 0x0cc616 /t reg_dword /f
 reg add %%s /v ColorTable03 /d 0xdd963a /t reg_dword /f & reg add %%s /v ColorTable11 /d 0xd6d661 /t reg_dword /f
 reg add %%s /v ColorTable04 /d 0x1f0fc5 /t reg_dword /f & reg add %%s /v ColorTable12 /d 0x5648e7 /t reg_dword /f
 reg add %%s /v ColorTable05 /d 0x981788 /t reg_dword /f & reg add %%s /v ColorTable13 /d 0x9e00b4 /t reg_dword /f
 reg add %%s /v ColorTable06 /d 0x009cc1 /t reg_dword /f & reg add %%s /v ColorTable14 /d 0xa5f1f9 /t reg_dword /f
 reg add %%s /v ColorTable07 /d 0xcccccc /t reg_dword /f & reg add %%s /v ColorTable15 /d 0xffffff /t reg_dword /f
 reg add %%s /v QuickEdit      /d 0x0000 /t reg_dword /f & reg add %%s /v LineWrap /d 0 /t reg_dword /f
 reg add %%s /v LineSelection  /d 0x0001 /t reg_dword /f & reg add %%s /v CtrlKeyShortcutsDisabled /d 0 /t reg_dword /f
 reg add %%s /v WindowSize    /d %WSize% /t reg_dword /f & reg add %%s /v ScreenBufferSize /d %BSize% /t reg_dword /f
 reg add %%s /v FontSize   /d 0x00100008 /t reg_dword /f & reg add %%s /v FaceName /d "Consolas" /t reg_sz /f ) >nul 2>nul
::# set path, fix name (x), always use C:\ESD as WORK directory to prevent issues and preserve current one as ROOT
pushd "%~dp0" & set "S=%SystemRoot%" & set "nx0=%~nx0" & call set "nx0=%%nx0:)=]%%" & call set "nx0=%%nx0:(=[%%"
set "PATH=%S%\Sysnative;%S%\Sysnative\windowspowershell\v1.0\;%S%\System32;%S%\System32\windowspowershell\v1.0\;%PATH%"
set "WORK=%SystemDrive%\ESD" & if not defined ROOT (set "ROOT=%CD%") else if not exist "%ROOT%\*.bat" set "ROOT=%CD%"
mkdir "%WORK%" >nul 2>nul & attrib -R -S -H "%WORK%" >nul 2>nul & robocopy "%~dp0/" "%WORK%/" "%~nx0" >nul
if "%~nx0" neq "%nx0%" copy /y "%WORK%\%~nx0" "%WORK%\%nx0%" >nul & del /f /q "%WORK%\%~nx0" >nul
if not defined set start "MCT" cmd /d /x /c set "ROOT=%ROOT%" ^& call "%WORK%\%nx0%" %* set& exit /b
::# self-echo top 1-20 lines of script
prompt $G & (<"%~f0" (set /p _=&for /l %%s in (1,1,20) do set _=& set /p _=& call echo;%%_%%)) 
::# lean xp+ color macros by AveYo:  %<%:af " hello "%>>%  &  %<%:cf " w\"or\"ld "%>%   for single \ / " use .%|%\  .%|%/  \"%|%\"
for /f "delims=:" %%s in ('echo;prompt $h$s$h:^|cmd /d') do set "|=%%s"&set ">>=\..\c nul&set /p s=%%s%%s%%s%%s%%s%%s%%s<nul&popd"
set "<=pushd "%appdata%"&2>nul findstr /c:\ /a" &set ">=%>>%&echo;" &set "|=%|:~0,1%" &set /p s=\<nul>"%appdata%\c"
::# (un)define main variables
for %%s in (OPTIONS MCT XML CAB EXE VID PRE AUTO ISO EDITION KEY ARCH LANGCODE NO_UPDATE DEF AKEY) do set "%%s="
for %%s in (latest_MCT.url) do if not exist %%s (echo;[InternetShortcut]&echo;URL=github.com/AveYo/MediaCreationTool.bat)>%%s
goto Universal MCT

::--------------------------------------------------------------------------------------------------------------------------------
:process
if %PRE% equ 1 (set "PRESET=Auto Upgrade")
if %PRE% equ 2 (set "PRESET=Auto ISO")
if %PRE% equ 3 (set "PRESET=Auto USB")
if %PRE% equ 4 (set "PRESET=Select"       & set EDITION=& set LANGCODE=& set ARCH=& set KEY=)
if %PRE% equ 5 (set "PRESET=MCT Defaults" & set EDITION=& set LANGCODE=& set ARCH=& set KEY=)
if %PRE% equ 5 (goto noelevate) else set set=%MCT%.%PRE%

::# self elevate if needed for the custom presets to monitor setup progress, passing arguments and last GUI choices
fltmc>nul||(set A=/d /x /c set "ROOT=%ROOT%"^& start "MCT" "%~f0" %* %set%& powershell -nop -c start -verb runas cmd $env:A;&exit)
:noelevate 'MCT Defaults' does not need it, script just quits straightaway

::# cleanup Downloads\MCT workfolder and stale mount files
mkdir "%WORK%\MCT" >nul 2>nul & attrib -R -S -H "%WORK%" /D & pushd "%WORK%\MCT"
del /f /q products.* *.key EI.cfg PID.txt auto.cmd AutoUnattend.xml >nul 2>nul
set /a latest=0 & if exist latest set /p latest=<latest
echo;20220320>latest & if %latest% lss 20211116 del /f /q products*.* MediaCreationTool*.exe >nul 2>nul

::# edition fallback to ones that MCT supports - after selection
(set MEDIA_EDITION=%MEDIA_EDITION:Eval=%)
(set MEDIA_EDITION=%MEDIA_EDITION:Embedded=Enterprise%)
(set MEDIA_EDITION=%MEDIA_EDITION:IoTEnterprise=Enterprise%)
(set MEDIA_EDITION=%MEDIA_EDITION:EnterpriseS=Enterprise%)
rem if %PRE% geq 2 (set MEDIA_EDITION=%MEDIA_EDITION:ProfessionalWorkstation=Enterprise%)
rem if %PRE% geq 2 (set MEDIA_EDITION=%MEDIA_EDITION:ProfessionalEducation=Education%)
if %VER% leq 16299 (set MEDIA_EDITION=%MEDIA_EDITION:ProfessionalWorkstation=Enterprise%)
if %VER% leq 16299 (set MEDIA_EDITION=%MEDIA_EDITION:ProfessionalEducation=Education%)
if %VER% leq 10586 (set MEDIA_EDITION=%MEDIA_EDITION:Enterprise=Professional%)
if %VER% leq 15063 if %INSERT_BUSINESS%0 lss 1 (set MEDIA_EDITION=%MEDIA_EDITION:Enterprise=Professional%)
if %VER% leq 10586 if %UNHIDE_BUSINESS%0 lss 1 (set MEDIA_EDITION=%MEDIA_EDITION:Education=Professional%)
if %VER% neq 15063 (set MEDIA_EDITION=%MEDIA_EDITION:Cloud=Professional%)

::# generic key preset - only for staged editions in MCT install.esd - see sources\product.ini
for %%s in (%MEDIA_EDITION%) do for %%K in (
  V3WVW-N2PV2-CGWC3-34QGF-VMJ2C.Cloud                     NH9J3-68WK7-6FB93-4K3DF-DJ4F6.CloudN
  YTMG3-N6DKC-DKB77-7M9GH-8HVX7.Core                      4CPRK-NM3K3-X6XXQ-RXX86-WXCHW.CoreN
  BT79Q-G7N6G-PGBYW-4YWX6-6F4BT.CoreSingleLanguage        N2434-X9D7W-8PF6X-8DV9T-8TYMD.CoreCountrySpecific
  VK7JG-NPHTM-C97JM-9MPGT-3V66T.Professional              2B87N-8KFHP-DKV6R-Y2C8J-PKCKT.ProfessionalN
  8PTT6-RNW4C-6V7J2-C2D3X-MHBPB.ProfessionalEducation     GJTYN-HDMQY-FRR76-HVGC7-QPF8P.ProfessionalEducationN
  DXG7C-N36C4-C4HTG-X4T3X-2YV77.ProfessionalWorkstation   WYPNQ-8C467-V2W6J-TX4WX-WT2RQ.ProfessionalWorkstationN
  YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY.Education                 84NGF-MHBT6-FXBX8-QWJK7-DRR8H.EducationN
  NPPR9-FWDCX-D2C8J-H872K-2YT43.Enterprise                DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4.EnterpriseN
) do if /i %%~xK equ .%%s set MEDIA_EDITION=%%~xK& call set MEDIA_EDITION=%%MEDIA_EDITION:.=%%& set "MEDIA_KEY=%%~nK"

::# detected / selected media preset
if defined EDITION (set EDITION=%MEDIA_EDITION%)
if "%MEDIA_EDITION%" neq "%OS_EDITION%" (set REG_EDITION=%MEDIA_EDITION%) else set (REG_EDITION=)
set "CONSUMER=%MEDIA_EDITION:Enterprise=%"
if "%CONSUMER%" equ "%MEDIA_EDITION%" (set CFG=Consumer) else (set CFG=Business)
if not defined EDITION (set UNSTAGED=1& set STAGED=) else (set UNSTAGED=& set STAGED=%MEDIA_EDITION%)
if defined STAGED (set MEDIA_CFG=%STAGED%) else (set MEDIA_CFG=%CFG%)
set MEDIA=& for %%s in (%LANGCODE%%EDITION%%ARCH%%KEY%) do (set MEDIA=%%s)
if defined MEDIA for %%s in (%MEDIA_LANGCODE%) do (set LANGCODE=%%s)
if defined MEDIA for %%s in (%MEDIA_EDITION%) do (set EDITION=%%s)
if defined MEDIA for %%s in (%MEDIA_ARCH%) do (set ARCH=%%s)
if defined MEDIA for %%s in (%MEDIA_KEY%) do (if not defined KEY set KEY=%%s)
::# windows 11 not available on x86
if %VER% geq 22000 (set MEDIA_ARCH=x64& if defined ARCH set ARCH=x64)

::# windows 11 vs 10 label quirks - guess I should not have combined them, but then again, 11 is 10 with a ui downgrade ;)
if %VER% geq 22000 (set X=11& set VIS=21H2) else (set X=10& set VIS=%VID%)

::# refresh screen
cls & <"%~f0" (set /p _=&for /l %%s in (1,1,20) do set _=& set/p _=& call echo;%%_%%)

::# write target media label with lang / edition / arch only for first 3 presets
%<%:f0 " Windows %X% Version "%>>% & %<%:5f " %VIS% "%>>%  &  %<%:f1 " %CB% "%>>%
if %PRE% leq 3 %<%:6f " %MEDIA_LANGCODE% "%>>%  &  %<%:9f " %MEDIA_CFG% "%>>%  &  %<%:2f " %MEDIA_ARCH% "%>%
echo;

::# download MCT and CAB / XML - new snippet to try via bits, net, certutil, and insecure/secure
if defined EXE echo;%EXE% & call :DOWNLOAD "%EXE%" MediaCreationTool%VID%.exe
if defined XML echo;%XML% & call :DOWNLOAD "%XML%" products%VID%.xml
if defined CAB echo;%CAB% & call :DOWNLOAD "%CAB%" products%VID%.cab
if exist products%VID%.xml copy /y products%VID%.xml products.xml >nul 2>nul
if exist products%VID%.cab del /f /q products%VID%.xml >nul 2>nul
if exist products%VID%.cab expand.exe -R products%VID%.cab -F:* . >nul 2>nul
set "/hint=Check urls in browser | del ESD dir | use powershell v3.0+ | unblock powershell | enable BITS serv"
echo;& set err=& for %%s in (products.xml MediaCreationTool%VID%.exe) do if not exist %%s set err=1
if defined err (%<%:4f " ERROR "%>>% & %<%:0f " %/hint% "%>%) else if not defined err %<%:0f " %PRESET% "%>%
if defined err (del /f /q products%VID%.* MediaCreationTool%VID%.exe 2>nul & pause & exit /b1)

::# configure products.xml in one go via powershell snippet - most of the MCT fixes happen there
call :PRODUCTS_XML

::# repack XML into CAB
makecab products.xml products.cab >nul

::#  MCT authors untouched media with no preset options or added files, script quits straightway
::# ====================================================================================================
if "MCT Defaults" equ "%PRESET%" (start MediaCreationTool%VID%.exe /Selfhost& exit /b)

::#  OR run script-assisted presets for auto upgrade without prompts / create iso directly / create usb
::# ====================================================================================================
if defined EDITION (set EDITION_SWITCH=%EDITION%) else (set EDITION_SWITCH=)
if not defined MEDIA (set LANGCODE=%MEDIA_LANGCODE%& set EDITION=%MEDIA_EDITION%& set ARCH=%MEDIA_ARCH%)
if defined UNSTAGED (set KEY=)

::# not using /MediaEdition option in MCT version 1703 and older - handled via CurrentVersion registry workaround
if %VER% gtr 15063 (set MEDIA_SEL=/MediaLangCode %LANGCODE% /MediaEdition %EDITION% /MediaArch %ARCH%) else (set MEDIA_SEL=)
if "Select" equ "%PRESET%" (set MEDIA_SEL=)

::# separate options for MCT and auto.cmd
set MOPTIONS=/Action CreateMedia %MEDIA_SEL% /Pkey Defer %OPTIONS% /SkipSummary /Eula Accept
set AOPTIONS=/Auto Upgrade /MigChoice Upgrade %OPTIONS% /SkipSummary /Eula Accept
set MAKE_OPTIONS=/SelfHost& for %%s in (%MOPTIONS%) do call set MAKE_OPTIONS=%%MAKE_OPTIONS%% %%s
set AUTO_OPTIONS=/SelfHost& for %%s in (%AOPTIONS%) do call set AUTO_OPTIONS=%%AUTO_OPTIONS%% %%s

::# generate PID.txt to preset EDITION on boot media - MCT install.esd indexes only, ProWS/ProEdu only via auto.cmd
for %%s in (Workstation WorkstationN Education EducationN) do if "Professional%%s" equ "%EDITION%" set "KEY="
if not defined PKEY if "Enterprise" equ "%EDITION%" set "KEY=" &rem explicitly remove generic PID.txt for Enterprise
if not defined KEY (del /f /q PID.txt 2>nul) else (echo;[PID]& echo;Value=%KEY%& echo;;Edition=%EDITION%)>PID.txt

::# generate EI.cfg for skipping key entry for generic 11 media
if not defined KEY if %VER% geq 22000 (echo;[Channel]& echo;_Default)>EI.cfg

::# generate auto.cmd for upgrading without prompts - also copied to media so it can be re-run on demand
::# keep files and apps from Ultimate / PosReady / Embedded / LTSC / Enterprise Eval 
set "0=%~f0"& powershell -nop -c "iex ([io.file]::ReadAllText($env:0) -split '[:]generate_auto_cmd')[1];"

::# generate AutoUnattend.xml for enabling offline local account on 11 Home editions
::# gets placed inside boot.wim so that it does not affect setup.exe under windows
set "0=%~f0"& powershell -nop -c "iex ([io.file]::ReadAllText($env:0) -split '[:]generate_AutoUnattend_xml')[1];"

::# cleanup stale files
dism /cleanup-wim >nul 2>nul

::# start script-assisted MCT via powershell (to monitor setup state and take necessary action)
set "0=%~f0" & powershell -nop -c "iex ([io.file]::ReadAllText($env:0) -split '[:]Assisted_MCT')[1];"
if not defined DEF if %hide% neq 1 pause >nul

EXIT

::--------------------------------------------------------------------------------------------------------------------------------
:Assisted_MCT
#:: unreliable processing like pausing setuphost removed; enhanced output; automation fixes; iso output path kung-fu
 $host.ui.rawui.windowtitle = "$env:PRESET $env:X $env:DEF"; $ErrorActionPreference = 0
 [io.path]::GetTempPath(),$env:TEMP,$env:TMP |% { if ($env:ROOT -like "*$_*") {$env:ROOT=$env:WORK} } # was run from zip?
 $DRIVE = [environment]::SystemDirectory[0]; $WD = $DRIVE+':\ESD'; $WS = $DRIVE+':\$WINDOWS.~WS\Sources'; $DIR = $WS+'\Windows'
 $ESD = $null; $USB = $null; $ISO = "$env:ROOT\$env:X $env:VIS $env:MEDIA_CFG $env:MEDIA_ARCH $env:MEDIA_LANGCODE.iso"
 if ('Auto Upgrade' -eq $env:PRESET) {$ISO = [io.path]::GetTempPath() + "~temporary.iso"}; del $ISO -force -ea 0 >$null
 if (test-path $ISO) {write-host " ERROR! " -fore Red -nonew; write-host "$ISO is read-only or in use`r`n"; sleep 5; return}
 cd -Lit("$env:WORK\MCT")

#:: workaround for version 1703 and earlier not having media selection switches
 if ($env:VER -le 15063 -and $null -ne $env:REG_EDITION) {
   $K = '"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"'; $E = $env:REG_EDITION
   cmd /d /x /c "(reg add $K /v EditionID /d $E /reg:32 /f & reg delete $K /v ProductName /reg:32 /f) >nul 2>nul"
   cmd /d /x /c "(reg add $K /v EditionID /d $E /reg:64 /f & reg delete $K /v ProductName /reg:64 /f) >nul 2>nul"
 }

#:: setup file watcher to minimally track progress
 function Watcher {
   $A = $args; $Exe = $A[0]; $File = $A[1]; $Folder = $A[2]; $Subdirs = @($false,$true)[$A[3] -eq 'all']
   $P = mkdir $Folder -force -ea 0; if (!(test-path $P)) {return 1}; $W = new-object IO.FileSystemWatcher; $W.Path = $P.FullName
   $W.Filter = $File; $W.IncludeSubdirectories = $Subdirs; $W.NotifyFilter = 125; $W.EnableRaisingEvents = $true; $ret = 1
   while ($true) {
     try { $get = $W.WaitForChanged(15, 15000) } catch { mkdir $Folder -ea 0 >$null; continue }
     if (-not $get.TimedOut) { write-host -fore Gray $get.ChangeType,$get.Name; $ret = 0;break} else {if ($Exe.HasExited) {break}}
   } ; $W.Dispose(); return $ret
 }

#:: load ui automation library
 $an = 'UIAutomationClientsideProviders','UIAutomationClient','UIAutomationTypes','System.Windows.Forms','Microsoft.VisualBasic'
 $ca = { [Windows.Automation.ClientSettings]::RegisterClientSideProviderAssembly($re[0].GetName()) }
 $re = $an |% { [Reflection.Assembly]::LoadWithPartialName("'$_") } ; try { & $ca } catch { & $ca }
 $cp = [Windows.Automation.AutomationElement]::ClassNameProperty
 $bt = "Button","ComboBox","Edit" |% {new-object Windows.Automation.PropertyCondition($cp, $_)}
 $null = new-item -path function: -name "Enter" -value { $app = get-process "SetupHost" -ea 0
 if ($null -ne $app) {[Microsoft.VisualBasic.Interaction]::AppActivate($app.Id)}; [Windows.Forms.SendKeys]::SendWait("{ENTER}") }
 $id = 0; if ('Auto USB' -ne $env:PRESET) {$id = 1}
 $sw = "ShowWindowAsync"; $dm = [AppDomain]::CurrentDomain."DefineDynami`cAssembly"(1,1)."DefineDynami`cModule"(1)
 $dt = $dm."Defin`eType"("AveYo",1179913,[ValueType]); $ptr = (get-process -pid $PID).MainWindowHandle.gettype()
 $dt."DefinePInvok`eMethod"($sw,"user`32",8214,1,[void],@($ptr,[int]),1,4) >$null; $nt = $dt."Creat`eType"()
 new-item -path function: -name "ShowWindow" -value {$nt."G`etMethod"($sw).invoke(0,@($args[0],$args[1]))} >$null

#:: start monitoring
 :mct while ($true) {
  #:: launch MCT with /Selfhost /Action CreateMedia options and wait for main window
   $set = get-process SetupHost -ea 0; if ($set) {$set.Kill()}
   $mct = start -passthru "$env:WORK\MCT\MediaCreationTool${env:VID}.exe" $env:MAKE_OPTIONS; if ($null -eq $mct) {break :mct}
   while ($null -eq (get-process SetupHost -ea 0)) {if ($mct.HasExited) {break :mct}; sleep -m 200 }
   $set = get-process SetupHost -ea 0; if ($null -eq $set) {break :mct}
   while ($set.MainWindowHandle -eq 0) { if ($mct.HasExited) {break :mct}; $set.Refresh(); sleep -m 200 }

  #:: using automation to click gui buttons directly due to UpgradeNow and CreateUpgradeMedia actions no longer working in 11 MCT
   if ('Select' -ne $env:PRESET) { try {
     $win = [Windows.Automation.AutomationElement]::FromHandle($set.MainWindowHandle); $nr = $win.FindAll(5, $bt[0]).Count
     if ($env:VER -le 15063) {while ($win.FindAll(5,$bt[1]).Count -lt 3) {if ($mct.HasExited) {break :mct}; sleep -m 200}; Enter}
     while ($win.FindAll(5,$bt[0]).Count -le $nr) {if ($mct.HasExited) {break :mct}; sleep -m 200}; $all = $win.FindAll(5,$bt[0])
     $all[$id].GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Select();$all[$all.Count-1].SetFocus(); Enter
     if ('Auto USB' -ne $env:PRESET) {
       while ($win.FindAll(5,$bt[2]).Count -le 0) {if ($mct.HasExited) {break :mct};sleep -m 50}; $val = $win.FindAll(5,$bt[2])[0]
       # using sendkeys Enter due to unreliable InvokePattern click(); extra sendwait(" ") + flush() due to new edit control issue
       [Windows.Forms.SendKeys]::SendWait(" "); $val.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).SetValue($ISO)
       [Windows.Forms.SendKeys]::Flush(); $b = $win.FindAll(5, $bt[0]); ($b |? {$_.Current.AutomationId -eq 1}).SetFocus(); Enter
     }
   } catch {} }

  #:: if DEF parameter used, quit without adding $ISO$, pid.txt, auto.cmd (includes 11 Setup override) to media
   if ($null -ne $env:DEF -and 'Auto Upgrade' -ne $env:PRESET) {break :mct}

  #:: get target $ISO or $USB from setup state file
   $ready = $false; $task = "PreDownload"; $action = "GetWebSetupUserInput"
   while (-not $ready) {
     [xml]$xml = get-content "$WS\Panther\windlp.state.xml"
     foreach ($t in $xml.WINDLP.TASK) { if ($t.Name -eq $task) { foreach ($a in $t.ACTION) { if ($a.ActionName -eq $action) {
       if ($null -ne $a.DownloadUrlX86) {$ESD = $a.DownloadUrlX86}
       if ($null -ne $a.DownloadUrlX64) {$ESD = $a.DownloadUrlX64}
       if ($null -ne $a.TargetISO) {$ISO = $a.TargetISO; $ready = $true}
       $u = $a.TargetUsbDrive; if ($null -ne $u -and $u -gt 0) {$USB = [char][Convert]::ToInt32($u, 16) + ":"; $ready = $true}
     }}}} ; if ($mct.HasExited) {break :mct}; sleep -m 1000
   }
 
   if ($mct.HasExited) {break :mct} # earlier detect of setup ui exit 
   if ('Auto Upgrade' -ne $env:PRESET -and $null -eq $USB) {write-host -fore Gray "Prepare", $ISO}
   if ('Auto Upgrade' -ne $env:PRESET -and $null -ne $USB) {write-host -fore Gray "Prepare", $USB}
   if ('Auto Upgrade' -eq $env:PRESET) {write-host -fore Gray "Prepare", $DIR}
   $label = "${env:X}_${env:VIS}" + ($ESD -split '(?=_client)')[1]
   $label = $label -replace '_clientconsumer','' -replace '_clientbusiness','' -replace 'fre_','_' -replace '.esd',''
   write-host -fore Gray "FromESD", $label; sleep 10; powershell -win $env:hide -nop -c ";"
   if ($mct.HasExited) {break :mct} # earlier detect of setup ui exit
   
  #:: watch setup files progress from the sideline (MCT has authoring control)
   write-host -fore Yellow "Started ESD download"; Watcher $mct "*.esd" $WD all >$null; if ($mct.HasExited) {break :mct}
   write-host -fore Yellow "Started media create"; Watcher $mct "*.wim"  $WS all >$null; if ($mct.HasExited) {break :mct}
   #write-host -fore Yellow "Started media layout"; Watcher $mct "ws.dat" $WS all >$null; if ($mct.HasExited) {break :mct}

  #:: add to media EI.cfg, PID.txt, auto.cmd, $ISO$ dir - disable via DEF arg
  #:: [issue #91] pick up $ISO$ content and add it to the root of the created media - place your $OEM$ into $ISO$\sources\$OEM$
   if ($null -eq $env:DEF) {
     pushd -lit "$env:ROOT"
     $f1 = '$ISO$'; if (test-path $f1) {xcopy /CYBERHIQ $f1 "$DIR" >$null; write-host -fore Gray "AddDirs", $f1} ; popd
     pushd -lit "$env:WORK"
     if (-not (test-path "$DIR\auto.cmd")) {
       $f2 = "MCT\auto.cmd"; if (test-path $f2) {copy -path $f2 -dest $DIR -force >$null; write-host -fore Gray "AddFile", $f2}
     }
     foreach ($P in "$DIR\x86\sources","$DIR\x64\sources","$DIR\sources") {
       if (!(test-path "$P\setupprep.exe")) {continue}
       if (-not (test-path "$DIR\EI.cfg") -and ($ESD -like '*_ret_*')) {
         $f3 = "MCT\EI.cfg"; if (test-path $f3) {copy -path $f3 -dest $P -force >$null; write-host -fore Gray "AddFile", $f3}
       }
       if (-not (test-path "$DIR\PID.txt")) {
         $f4 = "MCT\PID.txt"; if (test-path $f4) {copy -path $f4 -dest $P -force >$null; write-host -fore Gray "AddFile", $f4}
       }
     } ; popd
   }

  #:: watch media layout progress (with status)
   write-host -fore Gray "Convert install.esd"
   $ready = $false; $task = "MediaCreate"; $action = "Layout"
   while (-not $ready) {
     [xml]$xml = get-content "$WS\Panther\windlp.state.xml"
     foreach ($t in $xml.WINDLP.TASK) { if ($t.Name -eq $task) { foreach ($a in $t.ACTION) { if ($a.ActionName -eq $action) {
       $total = $a.ProgressTotal; $current = $a.ProgressCurrent
       if ($null -ne $total -and 0 -ne $total -and $total -eq $current) {$ready = $true}
       if ($null -ne $current -and 0 -ne $current) {$done = [Convert]::ToInt64($current, 16)} else {$done = 0}
       write-host -nonew -fore Gray "`r${done}% "
     }}}} ; if ($mct.HasExited) {break :mct}; sleep -m 10000
   }
   $action = "IsoLayout"; if ($null -ne $USB) {$action = "UsbLayout"}
   write-host -fore Yellow "`r`nStarted $action"

  #:: watch usb layout progress (with status) if target is $USB
   if ($null -ne $USB) {
     $ready = $false; $task = "MediaCreate"; $action = "UsbLayout"; $size = 0; $almost = 0; $foreground = 0
     while (-not $ready) {
       sleep -m 5000; if ($mct.HasExited) {break :mct}
       [xml]$xml = get-content "$WS\Panther\windlp.state.xml"
       foreach ($t in $xml.WINDLP.TASK) { if ($t.Name -eq $task) { foreach ($a in $t.ACTION) { if ($a.ActionName -eq $action) {
         $total = $a.ProgressTotal; $current = $a.ProgressCurrent
         if ($null -ne $total -and 0 -ne $total -and $total -eq $current) {$ready = $true}
        #:: hide setup ui and show script window in foreground (to prevent ui stalling / working dir cleanup when done)
         if ($size -eq 0) {$size = [Math]::Ceiling([Convert]::ToInt64($total, 16)/1048576); $almost = $size * 0.8}
         $done = [Math]::Ceiling([Convert]::ToInt64($current, 16)/1048576)
         if ($foreground -eq 0 -and $done -gt $almost) {
           $set = get-process SetupHost -ea 0; $SetupHost = $set.MainWindowHandle; powershell -win 0 -nop -c ";"
           ShowWindow $SetupHost 0; ShowWindow (get-process -Id $PID).MainWindowHandle 1; $foreground = 1
         }
         write-host -nonew -fore Gray "`r${size} MB  written: ${done} MB "
       }}}}
     }
     write-host -fore Gray "`r`nCreated $action"
   }

  #:: kill MCT process before temporary iso finish
   if ($env:VER -ge 22000 -or 'Auto Upgrade' -eq $env:PRESET) {
     $mct.Kill(); $s = get-process SetupPrep,SetupHost -ea 0; if ($s) { foreach ($setup in $s) {$setup.Kill()} }
     powershell -win 0 -nop -c ";"; ShowWindow (get-process -Id $PID).MainWindowHandle 1
     sleep 3; cmd /d /x /c "dism /cleanup-wim >nul 2>nul"; del $ISO -force -ea 0 >$null
   }

  #:: end monitoring
   break :mct
 }
#:: undo workaround for version 1703 and earlier not having media selection switches
 if ($env:VER -le 15063 -and $null -ne $env:REG_EDITION) {
   $K = '"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"'; $E = $env:OS_EDITION; $P = $env:OS_PRODUCT
   cmd /d /x /c "(reg add $K /v EditionID /d $E /reg:32 /f & reg add $K /v ProductName /d $P /reg:32 /f) >nul 2>nul"
   cmd /d /x /c "(reg add $K /v EditionID /d $E /reg:64 /f & reg add $K /v ProductName /d $P /reg:64 /f) >nul 2>nul"
 }

#:: if terminated unexpectedly or DEF used for default, untouched media:
 if (-not (test-path "$DIR\sources\ws.dat")) {
   if ((get-process SetupHost -ea 0) -and $null -ne $env:DEF) {return}
   powershell -win 0 -nop -c ";"; ShowWindow (get-process -Id $PID).MainWindowHandle 1
   pushd -lit "$env:WORK"; cmd /d /x /c "pushd c:\ & rmdir /s /q ""$DIR"" >nul 2>nul & del /f /q ""$WS\*.*"" >nul 2>nul"
   write-host " ERROR! " -fore Red -nonew; write-host "setup terminated unexpectedly`r`n"; sleep 7; return
 } 

#:: back to classic 0-byte skip 11 upgrade checks as it still works in release - and people keep nagging about Server label
 if ($env:VER -ge 22000) {
   cmd /d /x /c "cd.>""$DIR\sources\appraiserres.dll"""
 }

#:: Auto Upgrade preset starts auto.cmd from $DIR = C:\$WINDOWS.~WS\Sources\Windows
 if ('Auto Upgrade' -eq $env:PRESET) {
   cd -Lit("$env:WORK\MCT"); cmd /d /x /c "call ""$env:WORK\MCT\auto.cmd"" ""$DIR"""; sleep 7; return
 }

#:: skip windows 11 upgrade checks - for running setup from boot media
 if ($env:VER -ge 22000 -and (test-path "$DIR\sources\boot.wim")) {
   write-host -fore Gray "Disable boot.wim 11 setup checks - can use def for default MCT media instead"
   rmdir "$WD\MOUNT" -re -force -ea 0; mkdir "$WD\MOUNT" -force -ea 0 >$null; $winsetup = "$WD\MOUNT\sources\winsetup.dll"
   dism.exe /mount-wim /wimfile:"$DIR\sources\boot.wim" /index:2 /mountdir:"$WD\MOUNT"; write-host
   if (-not (test-path "$DIR\AutoUnattend.xml")) {
     $f5 = "$env:WORK\MCT\AutoUnattend.xml" 
     if (test-path $f5) {write-host importing file: $f5; copy -path $f5 -dest "$WD\MOUNT" -force >$null}
   }
   try { takeown.exe /f $winsetup /a >$null; icacls.exe $winsetup /grant *S-1-5-32-544:f; attrib -R -S $winsetup
     $patch = '/commit'; [io.file]::OpenWrite($winsetup).close() } catch {$patch = '/discard'}
   if ($patch -eq '/commit') { #:: an original setup override by AveYo to use when registry overrides fail (VirtualBox 5.x)
     $b = [io.file]::ReadAllBytes($winsetup); $h = [BitConverter]::ToString($b) -replace '-'
     $s = [BitConverter]::ToString([Text.Encoding]::Unicode.GetBytes('Module_Init_HWRequirements')) -replace '-'
     $i = ($h.IndexOf($s)/2); $r = [Text.Encoding]::Unicode.GetBytes('Module_Init_GatherDiskInfo'); $l = $r.Length
     if ($i -gt 1) {for ($k=0;$k -lt $l;$k++) {$b[$i+$k] = $r[$k]}; [io.file]::WriteAllBytes($winsetup,$b)}; [GC]::Collect()
   }
   dism.exe /unmount-wim /mountdir:"$WD\MOUNT" $patch; rmdir "$WD\MOUNT" -re -force -ea 0

  #:: create media
   if ($null -ne $USB) {
     write-host -fore Yellow "Refresh USB $USB"
     #:: if target is $USB, refresh boot.wim from sources
     replace "$DIR\sources\boot.wim" "$USB\sources" /r /u
   } else {
     write-host -fore Yellow "Refresh ISO"
     #:: if target is $ISO, load then call MakeISO snippet (formerly named DIR2ISO)
     iex ([io.file]::ReadAllText($env:0) -split '#\:MakeISO\:' ,3)[1]
     MakeISO $DIR $ISO $label
   }
  #:: cleanup
   pushd -lit "$env:WORK"; try {start -wait "$DIR\sources\setupprep1.exe" "/cleanup"} catch {}
   cmd /d /x /c "pushd c:\ & rmdir /s /q ""$DIR"" >nul 2>nul & del /f /q ""$WS\*.*"" >nul 2>nul"
 }

 write-host -fore Green "`r`n DONE "; write-host Press any key to exit . . .; sleep 7; return 
#:: done #:Assisted_MCT

::--------------------------------------------------------------------------------------------------------------------------------
:generate_auto_cmd $text = @"
@echo off& title Auto Upgrade  ||  supports Ultimate / PosReady / Embedded / LTSC / Enterprise Eval
set "EDITION_SWITCH=$env:EDITION_SWITCH"
set "SKIP_11_SETUP_CHECKS=$((0,1)[$null -eq $env:DEF])"
set OPTIONS=$env:AUTO_OPTIONS`r`n`r`n
"@ + @'
pushd "%~dp0" & for %%w in (%1) do pushd %%w
for %%i in ("x86\" "x64\" "") do if exist "%%~isources\setupprep.exe" set "dir=%%~i"
pushd "%dir%sources" || (echo "%dir%sources" not found! script should be run from windows setup media & timeout /t 5 & exit /b)

::# start sources\setup if under winpe (when booted from media) [Shift] + [F10]: c:\auto or d:\auto or e:\auto etc.
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinPE">nul 2>nul && (
 for %%s in (sCPU sRAM sSecureBoot sStorage sTPM) do reg add HKLM\SYSTEM\Setup\LabConfig /f /v Bypas%%sCheck /d 1 /t reg_dword
 start "WinPE" sources\setup.exe & exit /b 
) 

::# init variables
setlocal EnableDelayedExpansion
set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\windowspowershell\v1.0\;%PATH%"
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\windowspowershell\v1.0\;%PATH%"

::# elevate so that workarounds can be set under windows
fltmc >nul || (set _="%~f0" %*& powershell -nop -c start -verb runas cmd \"/d /x /c call $env:_\"& exit /b)

::# undo any previous regedit edition rename (if upgrade was interrupted)
set "NT=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
for %%v in (CompositionEditionID EditionID ProductName) do (
 call :reg_query "%NT%" %%v_undo %%v
 if defined %%v reg delete "%NT%" /v %%v_undo /f & for %%A in (32 64) do reg add "%NT%" /v %%v /d "!%%v!" /f /reg:%%A 
) >nul 2>nul

::# get current version
for %%v in (CompositionEditionID EditionID ProductName CurrentBuildNumber) do call :reg_query "%NT%" %%v %%v
for /f "tokens=2-3 delims=[." %%i in ('ver') do for %%s in (%%i) do set /a Version=%%s*10+%%j

::# WIM_INFO w_5=wim_5th b_5=build_5th p_5=patch_5th a_5=arch_5th l_5=lang_5th e_5=edi_5th d_5=desc_5th i_5=edi_5th i_Core=index
set "0=%~f0"& set wim=& set ext=.esd& if exist install.wim (set ext=.wim) else if exist install.swm set ext=.swm
set snippet=powershell -nop -c iex ([io.file]::ReadAllText($env:0)-split'#[:]wim_info[:]')[1]; WIM_INFO install%ext% 0 0  
set w_count=0& for /f "tokens=1-7 delims=," %%i in ('"%snippet%"') do (set w_%%i=%%i,%%j,%%k,%%l,%%m,%%n,%%o& set /a w_count+=1
set b_%%i=%%j& set p_%%i=%%k& set a_%%i=%%l& set l_%%i=%%m& set e_%%i=%%n& set d_%%i=%%o& set i_%%n=%%i& set i_%%i=%%n)

::# print available editions in install.esd via wim_info snippet
echo;------------------------------------------------------------------------------------
for /l %%i in (1,1,%w_count%) do call echo;%%w_%%i%%
echo;------------------------------------------------------------------------------------

::# get requested edition in EI.cfg or PID.txt or OPTIONS
if exist product.ini for /f "tokens=1,2 delims==" %%O in (product.ini) do if not "%%P" equ "" (set pid_%%O=%%P& set pn_%%P=%%O)
set EI=& set Name=& set eID=& set reg=& set "cfg_filter=EditionID Channel OEM Retail Volume _Default VL 0 1 ^$"
if exist EI.cfg for /f "tokens=*" %%i in ('findstr /v /i /r "%cfg_filter%" EI.cfg') do (set EI=%%i& set eID=%%i)
if exist PID.txt for /f "delims=;" %%i in (PID.txt) do set %%i 2>nul
if not defined Value for %%s in (%OPTIONS%) do if defined pn_%%s (set Name=!pn_%%s!& set Name=!Name:gvlk=!)
if defined Value if not defined Name for %%s in (%Value%) do (set Name=!pn_%%s!& set Name=!Name:gvlk=!)
if defined EDITION_SWITCH (set eID=%EDITION_SWITCH%) else if defined Name for %%s in (%Name%) do (set eID=%Name%)
if not defined eID set eID=%EditionID%& if not defined EditionID set eID=Professional& set EditionID=Professional
if /i "%EditionID%" equ "%eID%" (set changed=) else set changed=1

::# upgrade matrix - now also for Enterprise Eval - automatically pick edition that would keep files and apps
if /i CoreCountrySpecific equ %eID% set "comp=!eID!" & set "reg=!eID!" & if not defined i_!eID! set "eID=Core"
if /i CoreSingleLanguage  equ %eID% set "comp=Core"  & set "reg=!eID!" & if not defined i_!eID! set "eID=Core"
for %%e in (Starter HomeBasic HomePremium CoreConnectedCountrySpecific CoreConnectedSingleLanguage CoreConnected Core) do (
 if /i %%e  equ %eID% set "comp=Core"  & set "eID=Core"
 if /i %%eN equ %eID% set "comp=CoreN" & set "eID=CoreN"
 if /i %%e  equ %eID% if not defined i_Core  set "eID=Professional"  & if not defined reg set "reg=Core"
 if /i %%eN equ %eID% if not defined i_CoreN set "eID=ProfessionalN" & if not defined reg set "reg=CoreN"
)
for %%e in (Ultimate ProfessionalStudent ProfessionalCountrySpecific ProfessionalSingleLanguage) do (
  if /i %%e equ %eID% (set "eID=Professional") else if /i %%eN equ %eID% set "eID=ProfessionalN"
)
for %%e in (EnterpriseG EnterpriseS IoTEnterpriseS IoTEnterprise Embedded) do (
  if /i %%e equ %eID% (set "eID=Enterprise") else if /i %%eN equ %eID% set "eID=EnterpriseN"
)
for %%e in (Enterprise EnterpriseS) do (
  if /i %%eEval equ %eID% (set "eID=Enterprise") else if /i %%eNEval equ %eID% set "eID=EnterpriseN"
)
if /i Enterprise  equ %eID% set "comp=!eID!" & if not defined i_!eID! set "eID=Professional"  & set "reg=!comp!"
if /i EnterpriseN equ %eID% set "comp=!eID!" & if not defined i_!eID! set "eID=ProfessionalN" & set "reg=!comp!"
for %%e in (Education ProfessionalEducation ProfessionalWorkstation Professional Cloud) do (
  if /i %%eN equ %eID% set "comp=EnterpriseN"  & if not defined reg set "reg=%%eN"
  if /i %%e  equ %eID% set "comp=Enterprise"   & if not defined reg set "reg=%%e"
  if /i %%eN equ %eID% set "eID=ProfessionalN" & if defined i_%%eN  set "eID=%%eN"
  if /i %%e  equ %eID% set "eID=Professional"  & if defined i_%%e   set "eID=%%e"
)
set index=& set lst=Professional& for /l %%i in (1,1,%w_count%) do if /i !i_%%i! equ !eID! set "index=%%i" & set "eID=!i_%%i!" 
if not defined index set index=1& set eID=!i_1!& if defined i_%lst% set "index=!i_%lst%!" & set "eID=%lst%"& set "comp=Enterprise"
set Build=!b_%index%!& set OPTIONS=%OPTIONS% /ImageIndex %index%& if defined changed if not defined reg set "reg=!eID!"
echo;Current edition: %EditionID% & echo;Regedit edition: %reg% & echo;Index: %index%  Image: %eID%
timeout /t 10

::# disable upgrade blocks
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f /v DisableWUfBSafeguards /d 1 /t reg_dword >nul 2>nul  

::# prevent usage of MCT for intermediary upgrade in Dynamic Update (causing 7 to 19H1 instead of 7 to 21H2 for example) 
if "%Build%" gtr "15063" (set OPTIONS=%OPTIONS% /UpdateMedia Decline)

::# skip windows 11 upgrade checks: add launch option trick if old-style 0-byte file trick is not on the media  
if "%Build%" lss "22000" set /a SKIP_11_SETUP_CHECKS=0
reg add HKLM\SYSTEM\Setup\MoSetup /f /v AllowUpgradesWithUnsupportedTPMorCPU /d 1 /t reg_dword >nul 2>nul &rem ::# TPM 1.2+ only
if "%SKIP_11_SETUP_CHECKS%" equ "1" cd.>appraiserres.dll 2>nul & rem ::# writable media only
for %%A in (appraiserres.dll) do if %%~zA gtr 0 (set TRICK=/Product Server ) else (set TRICK=)
if "%SKIP_11_SETUP_CHECKS%" equ "1" (set OPTIONS=%TRICK%%OPTIONS%)

::# auto upgrade with edition lie workaround to keep files and apps - all 1904x builds allow up/downgrade between them
if defined reg call :rename %reg%
start "auto" setupprep.exe %OPTIONS%
echo;DONE

EXIT /b

:rename EditionID
set "NT=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
for %%v in (CompositionEditionID EditionID ProductName) do reg add "%NT%" /v %%v_undo /d "!%%v!" /f >nul 2>nul
for %%A in (32 64) do ( 
 reg add "%NT%" /v CompositionEditionID /d "%comp%" /f /reg:%%A
 reg add "%NT%" /v EditionID /d "%~1" /f /reg:%%A
 reg add "%NT%" /v ProductName /d "%~1" /f /reg:%%A
) >nul 2>nul
exit /b

:reg_query [USAGE] call :reg_query "HKCU\Volatile Environment" Value variable
(for /f "tokens=2*" %%R in ('reg query "%~1" /v "%~2" /se "|" %4 2^>nul') do set "%~3=%%S") & exit /b

#:WIM_INFO:# [PARAMS]: "file" [optional]Index or 0 = all  Output 0 = txt 1 = xml 2 = file.txt 3 = file.xml 4 = xml object
set ^ #=;$f0=[io.file]::ReadAllText($env:0); $0=($f0-split '#[:]WIM_INFO[:]' ,3)[1]; $1=$env:1-replace'([`@$])','`$1'; iex($0+$1)
set ^ #=& set "0=%~f0"& set 1=;WIM_INFO %*& powershell -nop -c "%#%"& exit /b %errorcode%
function WIM_INFO ($file = 'install.esd', $index = 0, $out = 0) { :info while ($true) {
  $block = 2097152; $bytes = new-object 'Byte[]' ($block); $begin = [uint64]0; $final = [uint64]0; $limit = [uint64]0
  $steps = [int]([uint64]([IO.FileInfo]$file).Length / $block - 1); $enc = [Text.Encoding]::GetEncoding(28591); $delim = @()
  foreach ($d in '/INSTALLATIONTYPE','/WIM') {$delim += $enc.GetString([Text.Encoding]::Unicode.GetBytes([char]60+ $d +[char]62))}
  $f = new-object IO.FileStream ($file, 3, 1, 1); $p = 0; $p = $f.Seek(0, 2)
  for ($o = 1; $o -le $steps; $o++) { 
    $p = $f.Seek(-$block, 1); $r = $f.Read($bytes, 0, $block); if ($r -ne $block) {write-host invalid block $r; break}
    $u = [Text.Encoding]::GetEncoding(28591).GetString($bytes); $t = $u.LastIndexOf($delim[0], [StringComparison]::Ordinal) 
    if ($t -lt 0) { $p = $f.Seek(-$block, 1)} else { [void]$f.Seek(($t -$block), 1)
      for ($o = 1; $o -le $block; $o++) { [void]$f.Seek(-2, 1); if ($f.ReadByte() -eq 0xfe) {$begin = $f.Position; break} }
      $limit = $f.Length - $begin; if ($limit -lt $block) {$x = $limit} else {$x = $block}
      $bytes = new-object 'Byte[]' ($x); $r = $f.Read($bytes, 0, $x) 
      $u = [Text.Encoding]::GetEncoding(28591).GetString($bytes); $t = $u.IndexOf($delim[1], [StringComparison]::Ordinal)
      if ($t -ge 0) {[void]$f.Seek(($t + 12 -$x), 1); $final = $f.Position} ; break } }
  if ($begin -gt 0 -and $final -gt $begin) {
    $x = $final - $begin; [void]$f.Seek(-$x, 1); $bytes = new-object 'Byte[]' ($x); $r = $f.Read($bytes, 0, $x)
    if ($r -ne $x) {$f.Dispose(); break} else {[xml]$xml = [Text.Encoding]::Unicode.GetString($bytes); $f.Dispose()}
  } else {$f.Dispose()} ; break :info }
  if ($out -eq 1) {[console]::OutputEncoding=[Text.Encoding]::UTF8; $xml.Save([Console]::Out); ''; return} 
  if ($out -eq 3) {try{$xml.Save(($file-replace'esd$','xml'))}catch{}; return}; if ($out -eq 4) {return $xml}
  $txt = ''; foreach ($i in $xml.WIM.IMAGE) {if ($index -gt 0 -and $($i.INDEX) -ne $index) {continue}; [int]$a='1'+$i.WINDOWS.ARCH
  $txt+= $i.INDEX+','+$i.WINDOWS.VERSION.BUILD+','+$i.WINDOWS.VERSION.SPBUILD+','+$(@{10='x86';15='arm';19='x64';112='arm64'}[$a])
  $txt+= ','+$i.WINDOWS.LANGUAGES.LANGUAGE+','+$i.WINDOWS.EDITIONID+','+$i.NAME+[char]13+[char]10}; $txt=$txt-replace',(?=,)',', '
  if ($out -eq 2) {try{[io.file]::WriteAllText(($file-replace'esd$','txt'),$txt)}catch{}; return}; if ($out -eq 0) {return $txt}
} #:WIM_INFO:# Quick WIM SWM ESD ISO info v2 - lean and mean snippet by AveYo, 2021

'@; [io.file]::WriteAllText('auto.cmd', $text) #:generate_auto_cmd

::--------------------------------------------------------------------------------------------------------------------------------
:generate_AutoUnattend_xml $text = @'
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="windowsPE"><component name="Microsoft-Windows-Setup" processorArchitecture="amd64" language="neutral"
   xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   publicKeyToken="31bf3856ad364e35" versionScope="nonSxS">
    <UserData><ProductKey><Key>AAAAA-VVVVV-EEEEE-YYYYY-OOOOO</Key><WillShowUI>OnError</WillShowUI></ProductKey></UserData>
    <ComplianceCheck><DisplayReport>Never</DisplayReport></ComplianceCheck><Diagnostics><OptIn>false</OptIn></Diagnostics>
    <DynamicUpdate><Enable>true</Enable><WillShowUI>Never</WillShowUI></DynamicUpdate><EnableNetwork>true</EnableNetwork>
  </component></settings>  
  <settings pass="specialize"><component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" language="neutral"
   xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   publicKeyToken="31bf3856ad364e35" versionScope="nonSxS">
    <RunSynchronous>
      <!-- offline local account via OOBE\BYPASSNRO on every site but literally no one credits AveYo for sharing it -->
      <RunSynchronousCommand wcm:action="add"><Order>1</Order>
        <Path>reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t reg_dword /d 1 /f</Path>
      </RunSynchronousCommand>
      <!-- hide unsupported nag on update settings - 25H1 is not a typo ;) -->
      <RunSynchronousCommand wcm:action="add"><Order>2</Order>
        <Path>reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseVersion /d 1 /t reg_dword /f</Path>
      </RunSynchronousCommand>
      <RunSynchronousCommand wcm:action="add"><Order>3</Order>
        <Path>reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseVersionInfo /d 25H1 /f</Path>
      </RunSynchronousCommand>
    </RunSynchronous>
  </component></settings>
  <settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" language="neutral" 
   xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   publicKeyToken="31bf3856ad364e35" versionScope="nonSxS">
    <OOBE>
      <HideLocalAccountScreen>false</HideLocalAccountScreen><HideOnlineAccountScreens>false</HideOnlineAccountScreens>
      <HideWirelessSetupInOOBE>false</HideWirelessSetupInOOBE><ProtectYourPC>3</ProtectYourPC>
    </OOBE>  
    <FirstLogonCommands>
      <!-- hide unsupported nag on desktop - originally shared by awuctl @ MDL -->
      <SynchronousCommand wcm:action="add"><Order>1</Order>
        <CommandLine>reg add "HKCU\Control Panel\UnsupportedHardwareNotificationCache" /v SV1 /d 0 /t reg_dword /f</CommandLine>
      </SynchronousCommand><SynchronousCommand wcm:action="add"><Order>2</Order>
        <CommandLine>reg add "HKCU\Control Panel\UnsupportedHardwareNotificationCache" /v SV2 /d 0 /t reg_dword /f</CommandLine>
      </SynchronousCommand>
    </FirstLogonCommands>
  </component></settings>
</unattend>

'@; [io.file]::WriteAllText('AutoUnattend.xml', $text); #:generate_AutoUnattend_xml - to be used via boot.wim on 11

::--------------------------------------------------------------------------------------------------------------------------------
:reg_query [USAGE] call :reg_query "HKCU\Volatile Environment" Value variable
(for /f "tokens=2*" %%R in ('reg query "%~1" /v "%~2" /se "," 2^>nul') do set "%~3=%%S")& exit /b

::--------------------------------------------------------------------------------------------------------------------------------
#:MakeISO:#  [PARAMS] "directory" "file.iso" [optional]"label"
set ^ #=;$f0=[io.file]::ReadAllText($env:0); $0=($f0-split '#\:MakeISO\:' ,3)[1]; $1=$env:1-replace'([`@$])','`$1'; iex($0+$1)
set ^ #=& set "0=%~f0"& set 1=;MakeISO %*& powershell -nop -c "%#%"& exit /b %errorcode%
function MakeISO ($dir,$iso,$label='DVD_ROM') {if (!(test-path -Path $dir -pathtype Container)) {"[ERR] $dir"; return 1}; $code=@"
 using System; using System.IO; using System.Runtime.Interop`Services; using System.Runtime.Interop`Services.ComTypes;
 public class dir2iso {public int AveYo=2021; [Dll`Import("shlwapi",CharSet=CharSet.Unicode,PreserveSig=false)]
 internal static extern void SHCreateStreamOnFileEx(string f,uint m,uint d,bool b,IStream r,out IStream s);
 public static int Create(string file, ref object obj, int bs, int tb) { IStream dir=(IStream)obj, iso;
 try {SHCreateStreamOnFileEx(file,0x1001,0x80,true,null,out iso);} catch(Exception e) {Console.WriteLine(e.Message); return 1;}
 int d=tb>1024 ? 1024 : 1, pad=tb%d, block=bs*d, total=(tb-pad)/d, c=total>100 ? total/100 : total, i=1, MB=(bs/1024)*tb/1024;
 Console.Write("{0}\r\n{1,2}%  {2}MB  MakeISO",file,0,MB); if (pad > 0) dir.CopyTo(iso, pad * block, Int`Ptr.Zero, Int`Ptr.Zero);
 while (total-- > 0) {dir.CopyTo(iso, block, Int`Ptr.Zero, Int`Ptr.Zero); if (total % c == 0) {Console.Write("\r{0,2}%",i++);}}
 iso.Commit(0); Console.WriteLine("\r{0,2}%  {1}MB  MakeISO",100,MB); return 0;} }
"@; & { $cs = new-object CodeDom.Compiler.CompilerParameters; $cs.GenerateInMemory = 1 #:: ` used to silence ps eventlog
 $compile = (new-object Microsoft.CSharp.CSharpCodeProvider).CompileAssemblyFromSource($cs, $code)
 $BOOT = @(); $bootable = 0; $mbr_efi = @(0,0xEF); $images = @('boot\etfsboot.com','efi\microsoft\boot\efisys.bin') #:: _noprompt
 0,1|% { $bootimage = join-path $dir -child $images[$_]; if (test-path -Path $bootimage -pathtype Leaf) {
 $bin = new-object -ComObject ADODB.Stream; $bin.Open(); $bin.Type = 1; $bin.LoadFromFile($bootimage)
 $opt = new-object -ComObject IMAPI2FS.BootOptions;$opt.AssignBootImage($bin.psobject.BaseObject); $opt.PlatformId = $mbr_efi[$_]
 $opt.Emulation = 0; $bootable = 1; $opt.Manufacturer = 'Microsoft'; $BOOT += $opt.psobject.BaseObject } }
 $fsi = new-object -ComObject IMAPI2FS.MsftFileSystemImage; $fsi.FileSystemsToCreate = 4; $fsi.FreeMediaBlocks = 0
 if ($bootable) {$fsi.BootImageOptionsArray = $BOOT}; $TREE = $fsi.Root; $TREE.AddTree($dir,$false); $fsi.VolumeName = $label
 $obj = $fsi.CreateResultImage(); $ret = [dir2iso]::Create($iso,[ref]$obj.ImageStream,$obj.BlockSize,$obj.TotalBlocks) }
 [GC]::Collect(); return $ret
} #:MakeISO:#  export directory as (bootable) udf iso - lean and mean snippet by AveYo, 2022.03.15

::--------------------------------------------------------------------------------------------------------------------------------
#:DOWNLOAD:# [PARAMS] "url" "file" [optional]"path"
set ^ #=;$f0=[io.file]::ReadAllText($env:0); $0=($f0-split '#\:DOWNLOAD\:' ,3)[1]; $1=$env:1-replace'([`@$])','`$1'; iex($0+$1)
set ^ #=& set "0=%~f0"& set 1=;DOWNLOAD %*& powershell -nop -c "%#%"& exit /b %errorcode%
function DOWNLOAD ($u, $f, $p = (get-location).Path) {
  $null = Import-Module BitsTransfer -ea 0; $wc = new-object Net.WebClient; $wc.Headers.Add('user-agent','ipad')
  $file = join-path $p $f; $s = 'https://'; $i = 'http://'; $d = $u.replace($s,'').replace($i,''); $https = $s+$d; $http = $i+$d
  foreach ($url in $http, $https) {
    if (([IO.FileInfo]$file).Exists) {return}; try {Start-BitsTransfer $url $file -ea 1} catch {}
    if (([IO.FileInfo]$file).Exists) {return}; try {Invoke-WebRequest $url -OutFile $file} catch {} ; $j = (Get-Date).Ticks
    if (([IO.FileInfo]$file).Exists) {return}; try {$null = bitsadmin /transfer $j /priority foreground $url $file} catch {}
    if (([IO.FileInfo]$file).Exists) {return}; try {$wc.DownloadFile($url, $file)} catch {}
  }
  if (([IO.FileInfo]$file).Exists) {return}; write-host -fore Yellow " $f download failed "
} #:DOWNLOAD:# try download url via bits, net, and http/https - snippet by AveYo, 2021

::--------------------------------------------------------------------------------------------------------------------------------
#:CHOICES:#  [PARAMS] indexvar "c,h,o,i,c,e,s"  [OPTIONAL]  default-index "title" fontsize backcolor forecolor winsize
set ^ #=;$f0=[io.file]::ReadAllText($env:0); $0=($f0-split '#\:CHOICES\:' ,3)[1]; $1=$env:1-replace'([`@$])','`$1'; iex($0+$1)
set ^ #=&set "0=%~f0"& set 1=;CHOICES %*& (for /f %%x in ('powershell -nop -c "%#%"') do set "%1=%%x")& exit /b
function CHOICES ($index,$choices,$def=1,$title='Choices',[int]$sz=12,$bc='MidnightBlue',$fc='Snow',[string]$win='300') {
 [void][Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); $f=new-object Windows.Forms.Form; $global:ret=''
 $bt=@(); $i=1; $ch=($choices+',Cancel').split(','); $ch |foreach {$b=New-Object Windows.Forms.Button; $b.Font='Consolas,'+$sz
 $b.Name=$i; $b.Text=$_;  $b.Margin='0,0,9,9'; $b.Location='9,'+($sz*3*$i-$sz); $b.MinimumSize=$win+',18'; $b.AutoSize=1
 $b.add_GotFocus({$this.BackColor=$fc; $this.ForeColor=$bc}); $b.add_LostFocus({$this.BackColor=$bc; $this.ForeColor=$fc})
 $b.FlatStyle=0; $b.Cursor='Hand'; $b.add_Click({$global:ret=$this.Name;$f.Close()}); $f.Controls.Add($b); $bt+=$b; $i++}
 $f.Text=$title; $f.BackColor=$bc; $f.ForeColor=$fc; $f.StartPosition=4; $f.AutoSize=1; $f.AutoSizeMode=0; $f.MaximizeBox=0
 $f.AcceptButton=$bt[$def-1]; $f.CancelButton=$bt[-1]; $f.Add_Shown({$f.Activate();$bt[$def-1].focus()})
 $f.ShowDialog() >$null; $index=$global:ret; if ($index -eq $ch.length) {return 0} else {return $index}
} #:CHOICES:#  gui dialog with inverted focus returning selected index - lean and mean snippet by AveYo, 2018 - 2021

::--------------------------------------------------------------------------------------------------------------------------------
#:CHOICES2:#  [INTERNAL]
set ^ #=;$f0=[io.file]::ReadAllText($env:0); $0=($f0-split '#\:CHOICES2\:' ,3)[1]; $1=$env:1-replace'([`@$])','`$1'; iex($0+$1)
set ^ #=&set "0=%~f0"&set 1=;CHOICES2 %*&(for /f "tokens=1,2" %%x in ('powershell -nop -c "%#%"')do set %1=%%x&set %5=%%y)&exit /b
function CHOICES2 {iex($f0-split '#\:CHOICES\:' ,3)[1]; function :LOOP { $a=$args
 $c1 = @($a[0], $a[1], $a[2], $a[3],  $a[-4], $a[-3], $a[-2], $a[-1]); $r1= CHOICES @c1; if ($r1 -lt 1) {return "0 0"}
 $a_7_ = $a[1].Split(',')[$r1-1] + ' ' + $a[7] #:: use 1st dialog result in the title for 2nd dialog
 $c2 = @($a[4], $a[5], $a[6], $a_7_,  $a[-4], $a[-3], $a[-2], $a[-1]); $r2= CHOICES @c2; if ($r2 -ge 1) {return "$r1 $r2"}
 if ($r2 -lt 1) {$a[2]=$r1; :LOOP @a} }; :LOOP @args #:: index1 choices1 def1 title1  index2 choices2 def2 title2  font bc tc win
} #:CHOICES2:#  MediaCreationTool.bat gui pseudo-menu via CHOICES snippet, streamlined in a single powershell instance

::--------------------------------------------------------------------------------------------------------------------------------
#:PRODUCTS_XML:#  [INTERNAL]    refactored with less looping over Files; addressed more powershell 2.0 quirks
set ^ #=;$f0=[io.file]::ReadAllText($env:0); $0=($f0-split '#\:PRODUCTS_XML\:' ,3)[1]; $1=$env:1-replace'([`@$])','`$1';iex($0+$1)
set ^ #=& set "0=%~f0"& set 1=;PRODUCTS_XML %*& powershell -nop -c "%#%"& exit /b
function PRODUCTS_XML { [xml]$xml = [io.file]::ReadAllText("$pwd\products.xml",[Text.Encoding]::UTF8); $root = $null
 $eulas = 0; $langs = 0; $ver = $env:VER; $vid = $env:VID; $X = $env:X; if ($X-eq'11') {$vid = "11 $env:VIS"}
 $url = "http://b1.download.windowsupdate.com/"
#:: apply/insert Catalog version attribute for MCT compatibility
 if ($null -ne $xml.SelectSingleNode('/MCT')) {
   $xml.MCT.Catalogs.Catalog.version = $env:CC; $root = $xml.SelectSingleNode('/MCT/Catalogs/Catalog/PublishedMedia')
 } else {
   $temp = [xml]('<?xml version="1.0" encoding="UTF-8"?><MCT><Catalogs><Catalog version="' + $env:CC + '"/></Catalogs></MCT>')
   $temp.SelectSingleNode('/MCT/Catalogs/Catalog').AppendChild($temp.ImportNode($xml.PublishedMedia,$true)) >$null
   $xml = $temp; $root = $xml.SelectSingleNode('/MCT/Catalogs/Catalog/PublishedMedia')
 }
 foreach ($l in $root.ChildNodes) {if ($l.LocalName -eq 'EULAS') {$eulas = 1}; if ($l.LocalName -eq 'Languages') {$langs = 1} }
#:: apply/insert EULA url fix to prevent MCT timing out while downloading it (likely TLS issue under naked Windows 7 host)
 $eula = "http://download.microsoft.com/download/C/0/3/C036B882-9F99-4BC9-A4B5-69370C4E17E9/EULA_MCTool_"
 if ($eulas -eq 1) { foreach ($i in $root.EULAS.EULA) {$i.URL = $eula + $i.LanguageCode.ToUpperInvariant() + '_6.27.16.rtf'} }
 if ($eulas -eq 0) {
   $tmp = [xml]('<EULA><LanguageCode/><URL/></EULA>'); $el = $xml.CreateElement('EULAS'); $node = $xml.ImportNode($tmp.EULA,$true)
   foreach ($lang in ($root.Languages.Language |where {$_.LanguageCode -ne 'default'})) {
     $i = $el.AppendChild($node.Clone()); $lc = $lang.LanguageCode
     $i.LanguageCode = $lc; $i.URL = $eula + $lc.ToUpperInvariant() + '_6.27.16.rtf'
   }
   $root.AppendChild($el) >$null
 }
#:: friendlier version + combined consumer editions label (not doing it for business too here as it would be ignored by mct)
 if ($langs -eq 1) {
   if ($ver -gt 15063) {$CONSUMER = "$vid Pro | Edu | Home"} else {$CONSUMER = "$vid Pro | Home"} #:: 1511
   foreach ($i in $root.Languages.Language) {
     foreach ($l in $i.ChildNodes) { $l.InnerText = $l.InnerText.replace("Windows 10", $vid) }
     if ($null -ne $i.CLIENT)    {$i.CLIENT   = "$CONSUMER"}    ;  if ($null -ne $i.CLIENT_K)  {$i.CLIENT_K  = "$CONSUMER K"}
     if ($null -ne $i.CLIENT_N)  {$i.CLIENT_N = "$CONSUMER N"}  ;  if ($null -ne $i.CLIENT_KN) {$i.CLIENT_KN = "$CONSUMER KN"}
   }
 }
 $BUSINESS = "$vid Pro | Edu | Enterprise"
 $root.Files.File | & { process {
   $_arch = $_.Architecture; $_lang = $_.LanguageCode; $_edi = $_.Edition; $_loc = $_.Edition_Loc; $ok = $true
  #:: clear ARM64 and %BASE_CHINA% entries to simplify processing - TODO: ARM support
   if ($_arch -eq 'ARM64' -or ($ver -lt 22000 -and $_loc -eq '%BASE_CHINA%')) {$root.Files.RemoveChild($_) >$null; return}
  #:: unhide combined business editions in xml that include them: 1709 - 21H1; unhide Education on 1507 - 1511; better label
   if ($env:UNHIDE_BUSINESS -ge 1) {
     if ($_edi -eq 'Enterprise' -or $_edi -eq 'EnterpriseN') {$_.IsRetailOnly = 'False'; $_.Edition_Loc = $BUSINESS}
     if ($ver -le 15063 -and ($_edi -eq 'Education' -or $_edi -eq 'EducationN')) {$_.IsRetailOnly = 'False'} #:: 1511
   }
 }}
 $lines = ([io.file]::ReadAllText($env:0) -split':PS_INSERT_BUSINESS_CSV\:')[1]; $insert = $false
 if ($null -ne $lines -and $env:INSERT_BUSINESS -ge 1 -and 19043,19042,19041,18363,15063,14393 -contains $ver) {
   $csv = ConvertFrom-CSV -Input $lines.replace('sr-rs','sr-latn-rs') | & { process { if ($_.Ver -eq $ver) {$_} } }
   $edi = @{ent='Enterprise';enN='EnterpriseN';edu='Education';edN='EducationN';clo='Cloud';clN='CloudN';
            pro='Professional';prN='ProfessionalN'}
   $insert = $true
 }
#:: insert individual business editions in xml that never included them: 1607, 1703
 if ($insert -and $ver -le 15063) {
   foreach ($e in 'ent','enN','pro','prN','edu','edN','clo','clN') {
     $items = $csv | & { process { if ($_.Client -eq $e) {$_} } } | group Lang -AsHashTable -AsString
     if ($null -eq $items) {continue}
     $cli = '_CLIENT' + $edi[$e]; $up = '/upgr/'; if ($ver -eq 14393 -and $e -like 'en*') {$up = '/updt/'} #:: .ToUpper()
     if ($e -like 'cl*') {$cli += '_RET_'} elseif ($e -like 'p*') {$cli += 'VL_VOL_'} else {$cli += '_VOL_'}
     if ($e -like 'cl*') {$BUSINESS = $edi[$e] -replace 'Cloud','S'} else {$BUSINESS = $edi[$e] -creplace 'N',' N'}
     $root.Files.File | & { process { if ($_.Edition -eq "Education") {
       $arch = $_.Architecture; $lang = $_.LanguageCode; $item = $items[$lang]; if ($null -eq $item) {return}
       if ($arch -eq 'x64')     {$_size = $item[0].Size_x64; $_sha1 = $item[0].Sha1_x64; $_dir = $item[0].Dir_x64}
       elseif ($arch -eq 'x86') {$_size = $item[0].Size_x86; $_sha1 = $item[0].Sha1_x86; $_dir = $item[0].Dir_x86}
       $c = $_.Clone(); if ($c.HasAttribute('id')) {$c.RemoveAttribute('id')} $c.IsRetailOnly = 'False'; $c.Edition = $edi[$e]
       $name = $env:CB + $cli + $arch + 'FRE_' + $lang; $c.Edition_Loc = "$vid $BUSINESS"
       $c.FileName = $name + '.esd'; $c.Size = $_size; $c.Sha1 = $_sha1
       $c.FilePath = $url + $_dir + $up + $env:CT + $name.ToLowerInvariant() + '_' + $_sha1 + '.esd'
       $root.Files.AppendChild($c) >$null
     }}}
   }
 }
#:: update existing FilePath entries for 1909, 2004, 2008 and insert entries for 21H2 and 11
 if ($insert -and $ver -gt 15063) {
   $items = $csv |group Client,Lang -AsHashTable -AsString
   if ($null -ne $items) {
     $root.Files.File | & { process {
       $cli = '_CLIENTCONSUMER_'; $chan = 'ret'; $edition = $_.Edition
       if ($edition -eq 'Enterprise' -or $edition -eq 'EnterpriseN') {$cli = '_CLIENTBUSINESS_'; $chan = 'vol'}
       $arch = $_.Architecture; $lang = $_.LanguageCode; $item = $items["$chan, $lang"]; if ($null -eq $item) {return}
       if ($arch -eq 'x64')     {$_size = $item[0].Size_x64; $_sha1 = $item[0].Sha1_x64; $_dir = $item[0].Dir_x64}
       elseif ($arch -eq 'x86') {$_size = $item[0].Size_x86; $_sha1 = $item[0].Sha1_x86; $_dir = $item[0].Dir_x86}
       if ('' -eq $_size) {$root.Files.RemoveChild($_) >$null; return}
       $name = $env:CB + $cli + $chan.ToUpperInvariant() + '_' + $arch + 'FRE_' + $_.LanguageCode
       $_.FileName = $name + '.esd'; $_.Size = $_size; $_.Sha1 = $_sha1
       $_.FilePath = $url + $_dir + '/upgr/' + $env:CT + $name.ToLowerInvariant() + '_' + $_sha1 + '.esd'
     }}
   }
 }
#:: clone Professional / Enterprise to work around MCT quirks when host OS is ProEdu / ProWS / EnterpriseS / Embedded
 $source = 'Enterprise'; $sourceN = 'EnterpriseN'; $clone = 'Embedded','IoTEnterpriseS','EnterpriseS'; $cloneN = 'EnterpriseSN'
 if ($ver -le 10586) {$source = 'Professional'; $sourceN = 'ProfessionalN'; $clone +='Enterprise'; $cloneN+='EnterpriseN'}
 if ($ver -le 16299) {$clone +='ProfessionalEducation','ProfessionalWorkstation'}
 if ($ver -le 16299) {$cloneN+='ProfessionalEducationN','ProfessionalWorkstationN'}
 if ($env:UNHIDE_BUSINESS -ge 1) {
   $root.Files.File | & { process {
     if ($_.Edition -eq $source) {
       foreach ($s in $clone) {
         $c = $_.Clone(); if ($c.HasAttribute('id')) {$c.RemoveAttribute('id')}
         $c.IsRetailOnly='False'; $c.Edition=$s; $root.Files.AppendChild($c) >$null
       }
     }
     elseif ($_.Edition -eq $sourceN) {
       foreach ($s in $cloneN) {
         $c = $_.Clone(); if ($c.HasAttribute('id')) {$c.RemoveAttribute('id')}
         $c.IsRetailOnly='False'; $c.Edition=$s; $root.Files.AppendChild($c) >$null
       }
   }}}
 }
 $xml.Save("$pwd\products.xml");

} #:PRODUCTS_XML:#  MediaCreationTool.bat configuring products.xml in one go

::--------------------------------------------------------------------------------------------------------------------------------
::# Insert business esd links in 1607,1703; Update 1909,2004,20H2,21H2 by hand until an updated products.xml from microsoft
::# Following are condensed ver,edition,lang,sizes,hashes,dirs to be recomposed into full official ESD links for MCT
::# I have chosen to generate them on-the-fly here instead of linking to third-party hosted pre-edited products.xml
::# Can skip copy-pasting some or all entries if not interested in updating the esd links for specific versions
::# [Dev] ESD name has all except size; can get it with (Invoke-WebRequest -Uri $url -Method Head).Headers['Content-Length']
:PS_INSERT_BUSINESS_CSV:_,Ver,Client,Lang,Size_x64,Size_x86,Sha1_x64,Sha1_x86,Dir_x64,Dir_x86
::#,14393,enN,bg-bg,2773448902,2111500580,d090ecc0e32e05a6c075eb8384f577315ac35ee2,f2206f926561fd89b69d6e7e61aa98956966dfd6,c,c
::#,14393,enN,cs-cz,2775734726,2113434488,3979b107d1af43aae3cc79bd7a2a081def5d04cf,e773288e71f7a17ec8e1525415134acbfa13a803,d,d
::#,14393,enN,da-dk,2799132592,2137434148,f0a667d9584f10c47b3db96b0e6700f1a47021c3,9defa59a1627b3440684ce9605a43a0c4e88c770,d,d
::#,14393,enN,de-de,2888504080,2219030252,e8a1023f0f21a7c99d1b5006ef520323238833cd,e62e766faffcd25ebce37b758aeac6e63208c332,d,d
::#,14393,enN,el-gr,2798418934,2123659240,8bd00622321661b9ca1eb7289d907a9056c713ce,880756cb261c7a7b32289e549011d9bb968d2706,d,d
::#,14393,enN,en-gb,2861883002,2200050658,f145a8eff3121dc8fb020c5a1750a0f2c117ecb3,7c3415af341630a1f01f2f0983e44579d6a23487,d,d
::#,14393,enN,en-us,2859877184,2201813278,fab646ab44b5d956a91e0d2aa0e4a37f22ddf7cd,5166cb73561f9c1190f9d6f8a35fe444877318f9,c,c
::#,14393,enN,es-es,2848523494,2196489320,7386e7b352e080a15f6a565feeace4c6e854703d,191a58383195e53864fcacb41313043a5ea77663,d,d
::#,14393,enN,et-ee,2748248864,2095947306,b487809fa9f137624e4bb205e389f0e599d17093,d9f88ee10c3f41e5e152b24c78a35ab1f15d6af4,d,d
::#,14393,enN,fi-fi,2796624854,2137783028,dc40703bd5eca75ce2d234e367f23db5a71c807f,d3ed9db8b398eda4497c6b9d897555f5a5663d84,c,c
::#,14393,enN,fr-fr,2852055774,2193600366,5838ee4f277ebd8ab33f3d40bbcc380a95f9e69b,36286ca54f121ca1247e1026e0c76bf3fdc4f2be,c,c
::#,14393,enN,hr-hr,2765426784,2100724714,f8d5c52045248839329634468038b184b7e9a491,742c2541073a78be847cbe684651b7fcab6b6fdb,c,c
::#,14393,enN,hu-hu,2780468248,2122154560,65b67804be6e6a5e66f0046a8c779fc9599b571e,444ac3b15980f3ef4f911fa2f920891e230118ca,d,d
::#,14393,enN,it-it,2798572882,2144445692,162bbba0399ed2e0cc12569676f4afcc685f08a0,f4deb16739ba26ec597725cc5a9a2580b33e7ca2,d,d
::#,14393,enN,lt-lt,2755834506,2094863630,11c047008667638f72cfa7391b0ac14ce954a427,0a1d7d1bd8456251c623d5c3f3e7e6f0a9c00e86,d,d
::#,14393,enN,lv-lv,2752316336,2093716546,230ac84bf1c669d375fd05159a8d26edb87cf264,98948912070a686f3b7060b9f80446faba677b2d,d,d
::#,14393,enN,nb-no,2773039326,2113695528,7939fcefabeed9a8cebf6ca04984e9c0f8470f50,ba8c7be3fb2a12ae3a227ac60b69ce225f367933,c,c
::#,14393,enN,nl-nl,2775118184,2130921230,fbb84419e1b8618b83b91873ed5cc7fa1365a009,40d9d1a599a5266947f337fa6acfcaeeece8a865,c,c
::#,14393,enN,pl-pl,2778912686,2125591884,7ea026557e632da890a64e0fcf72f3672ef12e53,487eab83f1e6f67058b50b9a889d790f49384567,d,d
::#,14393,enN,pt-pt,2787935254,2125017148,0afce496d59bbfc1f1c6580dfb49bf0ca1e30275,40a28c0263920c0e13a1c450511718f61f2c67e1,d,d
::#,14393,enN,ro-ro,2763055438,2101442992,d88e0b470995cc081f9e73d06baf0ce6080445c9,5452de2544692ba234c744cb18676f1cbc3c7c3c,d,d
::#,14393,enN,sk-sk,2763328164,2096292986,be661b5d237a8a93259d64754b09ae29f26cb42b,6322ebdfaea5955e28ec0edba5595e6ecc3eabba,c,c
::#,14393,enN,sl-si,2754008752,2096786702,73a4a166b1eedff7c7465eed4ce3daa8eec1c051,882e91a3c1e7a239ac4d39288c19228b8ba20c8d,c,c
::#,14393,enN,sv-se,2799778090,2130127248,70e0831a0c4078705b6699e8662d6cb0dc4875a0,66c58033888d81d9e914463d941a525ef1f1c29b,d,d
::#,14393,ent,ar-sa,2955820350,2253811598,672bb229c831b84e95a6dbff94818528894540d3,c6daaa38f3eb589e8654a266320032ed3aa3a6f5,d,d
::#,14393,ent,bg-bg,2911551848,2218360574,97d613cdfb2ded4df2f71ef29fc93ca3656c6ed8,2c0063b9f769ba2307f84717ac2b915206a9d4a3,d,d
::#,14393,ent,cs-cz,2918785956,2214354874,7542eab92328937b8d09ee02cf8fa9cc6a196830,3108854bb25b7c75bac13289db5c2a2e9c920578,d,d
::#,14393,ent,da-dk,2946222420,2240352350,bb9da04cd47d7973597386ffd203ed56e19d4d65,297f5fb65fa79f3ed1d0a6dcad202d863b71e9bc,c,c
::#,14393,ent,de-de,3019388686,2321843034,c9b01f8eceb84ea2e7abf8c8823a623d759a61d0,8af78913db117260a888d57c5376470cfc109670,d,d
::#,14393,ent,el-gr,2933879638,2226440968,14e182c6ed9ba36c720fbd0c3f5ce7d64ed38ca5,b8bad577e15fbfaa27b8bdb53d1c6724fe64357a,d,d
::#,14393,ent,en-gb,3002224046,2305860070,b972022ec65c9205195833b842983e527f287d0a,6d0466628b39e192bd675fae1dfafded7fff94d9,d,d
::#,14393,ent,en-us,3012544034,2310343386,cbf97f9ee545d6bbff70c7fb9740e9fe5d6f4d77,72e16690f022fde1c59abc93457a1c6b8bd4c5dc,c,c
::#,14393,ent,es-es,3002625924,2298493682,d6b21213c81c83c46965baf0c1da2f14d4f3eff2,4b3999d40e9ac39c1ba4c1dec301c51aacc50f28,c,c
::#,14393,ent,es-mx,2943527594,2249633892,e7bb91c6aa0c9295718f0ea2761005ac4c556cc8,3341b800403bb93375745ea4c3a4529ae5472fe3,c,c
::#,14393,ent,et-ee,2889988048,2192782608,ca9eba2953c9aed39e051f5d984e4a58c945d17d,06e7a360daba3388edefbdf56d958e98b2cae2d2,c,c
::#,14393,ent,fi-fi,2932564162,2235053854,b250bb11cbbea356417993455d639582ca4fd052,3d13bc3b7ca9411cd791c5c861e022bfbf2db2ce,d,d
::#,14393,ent,fr-ca,2970085652,2267316492,e33bc497cc5ef1a2ef362c23d2814d580aa22e26,2200c921718cf3b8246cf4e82ae7127668790444,d,d
::#,14393,ent,fr-fr,2996998394,2297031996,b599b3275302e57b8e1ad25271da68c299c4de39,8b6805f55fd7c6641d182131f500c0340887c0b6,d,d
::#,14393,ent,he-il,2927278142,2224939840,b82d6122d55c838393c5645520692acd101834a9,4011de9ecdf53b41fdb2ea9e0910bc6a0bca7939,c,c
::#,14393,ent,hr-hr,2898184950,2202588894,bc2cbd1d92e60598115098238f12e8dac2c2166f,c689528beb00b9157cc3d08c2409ffaec84ea56c,c,c
::#,14393,ent,hu-hu,2918877960,2223268852,a0453e7dc3d34716caac2cacb473aa65ccecea3e,47e181c321033ac99850fb222047635a83d71d43,c,c
::#,14393,ent,it-it,2953574274,2247219130,9b48a0fef984b867e8018708785a6c70a696a469,4e68dba7258c1af508d8c180564749b5b1b9b3fc,c,c
::#,14393,ent,ja-jp,3063387292,2355095860,ec30e2dfa29223fbeda28feeed89f7ed6d2911fd,24d900e9937c520b10056e53775e6a5934a916a2,c,c
::#,14393,ent,ko-kr,2979348462,2265728512,8b9af5c684e639b1787c901baddb33e3ec1f17d5,296956b802ccf9a76083e6398db20d2b67186fd0,c,c
::#,14393,ent,lt-lt,2890387644,2196863664,97f81a28fa526e57e2e38235ce7103aa0fca0ff5,1636c7532f21ebf6282e785f35840201ed6cb81c,c,c
::#,14393,ent,lv-lv,2897092188,2196617270,26775e677727ad2296e7de0620be132d144abd55,aa16e2b2f317ab45e43885bb700a428d74244ef3,d,d
::#,14393,ent,nb-no,2922664364,2218857478,7c42bfed895f37cf86153ee75325b5d4b71e3eab,a9bbff5197b258a37d4639a9699e938f86030777,d,d
::#,14393,ent,nl-nl,2934556272,2223733356,81b8974317b76417ae102951ec191f90fdfc00f9,c1ad0d57e0ba595e81ef7820f9db2b7c12114629,c,c
::#,14393,ent,pl-pl,2929138222,2228062654,7ddc4be2c46d3aa5b562bc593936b7bac33c6a4a,165494554c7fdb1be55e4399b6372515c2d6b1ab,c,c
::#,14393,ent,pt-br,2953378710,2264016962,71de2e5a288324151bec24830bcedca5ad77a1ad,a5006f26410655f0efa3a42c0ff63b6c9acf4d74,d,d
::#,14393,ent,pt-pt,2941611330,2229207498,52dc57e4107dec547e68a9e74eec10244cea4f92,0b1a60b57e687aba766001a8b306870c9e7241b3,d,d
::#,14393,ent,ro-ro,2887834662,2201439796,24950dd0d69cd50fe01f8e9309583772ef231518,f1d43e2cbf3006e034b64eca9bc94de7ffa8cf94,c,c
::#,14393,ent,ru-ru,2957770620,2261034630,8ce69e0236a2b5269c08a67edab908211585b3c1,50f2f76e8a0e62f26a6238fd9471b16ca1b26186,c,c
::#,14393,ent,sk-sk,2888894912,2197855320,14accd88aa808e900ba902ac6509a5786d41be79,1796ddb7072d64e971b3f7ef7c3c3ecadfc7dd00,d,d
::#,14393,ent,sl-si,2881745984,2196163006,c1ac7d37d86e4dbdbb2992acc8d3b6e60e52919a,2bcc0dd24a8fcf85e041d29c27be612d20f6c39a,d,d
::#,14393,ent,sr-rs,2910809030,2204793922,f8d80cb91733aa8b48c6b84327494e210b8e5494,242810176bd2c17e25c94b5478762bacd04f0c2c,c,c
::#,14393,ent,sv-se,2931748080,2231055130,d6196f5e660ef7055a0a5efad8892045131a7f9b,14642e83ecd3d000bfc10d5bcea08de83ca1fe39,c,c
::#,14393,ent,th-th,2910791934,2218450936,1286f4fef88b41884d8083aad666d63ca232be42,5660b3c566e05bbb58504c392470916996988bf5,c,c
::#,14393,ent,tr-tr,2915633822,2215962556,871cf4807375a39b335468d44407023f19bade5f,2dbe29adf9297d98e66e42558fa673c0e76b4cf8,d,d
::#,14393,ent,uk-ua,2915857130,2219357380,5b88fcd4211676ced3350a9bdf5abe0a37707991,02a14a526045c75cbbc1aa279d01f1f23686dd93,c,c
::#,14393,ent,zh-cn,3131493920,2421427008,e78e04e6204b107ffa36d898d58232c86e98199d,2ddd95d076810d788d63082cffcbbd75bf921243,d,d
::#,14393,ent,zh-tw,3059396808,2361521848,4b4e82301a37192b69d70496fcf57c16aad681eb,589eb269e0666134c1d31d67c665da50ea9b2a66,d,d
::#,15063,clN,en-us,3144657572,2437732564,e69925fec9aebc5fbf3852086ecb4c3fe00dfc2e,0fcc1248ab6ac55cae7ec24be5b21ff163d34fc1,c,c
::#,15063,clo,en-us,3315033420,2546331272,7e8eae476222bbb48de04862a8ac85bdd563461c,9d92ec014d1dcc4d1968b33e9cc9bc0748e07bcd,d,d
::#,15063,enN,bg-bg,3063703618,2343397300,859fd1064516d2d86970313e20682c3f2da3b0f7,3f2d95b5af40290989b42d7e85fb73c2deecb107,c,c
::#,15063,enN,cs-cz,3063480034,2339478712,5885cef1a0a88972eafbf3240a91944a5bbaef0c,ebb7e9db690c146503c1470f6431ebb3b9f90b8d,d,d
::#,15063,enN,da-dk,3064590226,2359187156,049db05e06fc85f2e4fa47daf620a91219f94da7,bc154a20faed8cb135617ea5f7c804a78b041663,c,c
::#,15063,enN,de-de,3175541170,2469646676,8114e5eade5115f06e87cc63d82a56e6da4e9d71,829e8e3a44ee0793a6c10b76d6fc0180cca52c60,c,c
::#,15063,enN,el-gr,3068824274,2359266864,b02813b4225d89cb685c75b0d13950e9f5af90db,1731ca121d36bb3115282277de3f467dee4eee2b,c,c
::#,15063,enN,en-gb,3137564572,2426801288,10b79168087eedc6f574af4c6c6893313702ec85,d45cfdcc6d7227a8ed12ad24d718df17709fa8fb,c,c
::#,15063,enN,en-us,3140230812,2433137092,3e2111b94ad40b063d6fc224da72f83205c374c8,b17b8827e6954672d2bd85276b73770801a3bf6a,c,c
::#,15063,enN,es-es,3147765694,2438326380,9bbfcdebcd28939d5463630e0938ba6a82c69387,87974fab21f2e4ffc783ee6de4e6942a6bcb943e,c,c
::#,15063,enN,et-ee,3032725650,2320212652,577a6202ef0105c44fa46e852f02cadeb4d8d9a3,4e55f61f68aaa863f3e98bd1159d09fe90508a7c,c,c
::#,15063,enN,fi-fi,3059882946,2342513800,d9c35e5ba0889424e10bd1391f482270b3c40853,70e4f643e220a70547bc75cafd358e5c247a918d,d,d
::#,15063,enN,fr-fr,3130815842,2428304540,34e9d32c32d40b6fa1bffb9d5e43b7ee52ccc8a4,61eaf46743223466e066c77c0563ad46501378d5,d,d
::#,15063,enN,hr-hr,3033535336,2328147230,80fc1b08c6b4d89b65ab5d4aff5b8c4460120800,ad15cd4f66559bdbe0c42552f4d9ff645fcc5151,d,d
::#,15063,enN,hu-hu,3056933946,2340664250,ff090817737eabc45aab729654e73446c79b053b,5bdb5d7c487fc0fb37b8b76c66c1f3e8e2682f06,c,c
::#,15063,enN,it-it,3100499922,2384586126,9f8316c823d069842e8cc52d9ced8b6915bfd612,4089301a2ea267526b974aae278aa5e0fc0134ae,c,c
::#,15063,enN,lt-lt,3025353026,2325646266,9aef261cd6fffa9d1db2ab1ab7cd52678ef06094,d1725c85939679dd82fb8d551909e8686773e53f,c,c
::#,15063,enN,lv-lv,3029332916,2325624994,7fa4685a86839f3d8093be889e7dcb14b99a4581,cdf68b52a97795d3bbddb17e08f5153868423082,c,c
::#,15063,enN,nb-no,3058404996,2337861734,17ec8c4db6dd115fc45050205d4ee391d55847a8,ab6a56a1e544b30cda33601f60ffdfe4b7a7c010,c,c
::#,15063,enN,nl-nl,3058285820,2340806626,9af5d931ed90868395e94fa99e15ce723153e7b4,202eed2dd65dab2791ec1a4b04afbb1a28ca997a,c,c
::#,15063,enN,pl-pl,3082538930,2365075840,3b8c6e1273d2d65562b81b0b1b63a8ce9ecdb3aa,5292273b4477d413dcec2533ad2459ba1821891b,c,c
::#,15063,enN,pt-pt,3074473316,2356933976,763b5bb74b702c18ba80f770dfa25a7af4dc4f91,5659133bec9806a48096068ee53c2838beae6f6c,c,c
::#,15063,enN,ro-ro,3035031152,2329162166,d9883e4a8242398402383ae47e4015a8c724b2f7,efa8623d089f7df5c41453b862c9e686d0b0b157,c,c
::#,15063,enN,sk-sk,3036114496,2330022126,c705871aa637455dbf04532b5ca462539d466d6d,b9b1705f81a7120a2bad78ffda154182814d53e9,c,c
::#,15063,enN,sl-si,3026544424,2326113308,cb1485805fa62f1ed18d28a0418e45c5d612b31a,8cccac3b248a6e6879bb8f5baeb06a375bc8fe68,c,c
::#,15063,enN,sv-se,3061594264,2339127740,6cb6b740c9f5390f0e1bd29cd33890a78f20775e,2e1c69c5a253cd7b7ed381e8a7d9ff02350ca8f2,c,c
::#,15063,ent,ar-sa,3269761758,2494711944,8efb029378cd955809e67baf2cc71c53c632e32c,489191d8cc329b9721ff26287bc71ff4cf02115a,d,d
::#,15063,ent,bg-bg,3221290404,2450825804,64316f68725e92c2567dcf86981e5eb1c635fd09,117a347347deaa73dce186af781b7eda8e4fc62f,d,d
::#,15063,ent,cs-cz,3231413240,2450581096,5d0fa9367cbc1ce83ceb9ec130af97000e89b150,30aa6d6caee1e882fd88018c7ddb9a747499b891,c,c
::#,15063,ent,da-dk,3248303690,2469352822,3005a5859d2010da9fd1a77e6aab14ca233d73dd,5451990e566561a587a8fd44bf81f3236fb27a8b,c,c
::#,15063,ent,de-de,3348816134,2577096876,f813662c59c2a382a940d82b96e825de80da7089,a19f69452edb66da0591a63ae7a2f9b319bedad3,c,c
::#,15063,ent,el-gr,3245990678,2468826000,f2f713a69c342e4b6513bdb8974213530f37d6ee,da04cef145557e500060759c3b759c03adf0580c,c,c
::#,15063,ent,en-gb,3312981002,2541092494,a7100680c5718d34474579b0154819e2e528ffd7,c4371bd42a1d3463c40ad05b4f328471e8be80c4,c,c
::#,15063,ent,en-us,3312849564,2542115274,5477ecbdb80b477d3cb049d0d64831b72797be8b,65162f45583f38d53d01c5e5a64a69d1e73cc005,d,d
::#,15063,ent,es-es,3319718002,2547575630,cf78240f01de56403f3ab7066cf061178a90ef3f,000f7839c99dfc3e883c9c41a2e7e1f9b9d1049c,c,c
::#,15063,ent,es-mx,3273904408,2496325838,8b4f2f3b2bf76a6ee78339332bb18e0476669b4d,9315c4f7cdbacac86b47aa2637e90b1820c1e0b5,d,d
::#,15063,ent,et-ee,3200923112,2429782490,2be6d35081b25a3e808343ea0aae69fbe781f506,1bb3b0c7df189c3cf2504a6c7b3044592991f510,c,c
::#,15063,ent,fi-fi,3230886556,2455546618,5bde9ca7461591e51af74416335694ecc4b1ca5f,32a72a1c0d4e70f7940e91c3e60aa10b6326d618,c,c
::#,15063,ent,fr-ca,3294268308,2520878858,cccbccd532887d278fa922fd09f56bfdca5088bb,904abb865818ee7ef3259129f49fde9464efd4cd,d,d
::#,15063,ent,fr-fr,3309828430,2542088822,64ff0e97c469fdd3b591ae226a16ebaa75c7e8d1,b2d1ccaca7117637ccc74c86876d6289ec2499a3,d,d
::#,15063,ent,he-il,3232690912,2455101288,d85a04e8c72279d00889be97fa9aa79e88964a89,8a6662b13ceb703d8ccc874351843fd6f9918ee1,c,c
::#,15063,ent,hr-hr,3212042850,2433083014,b07812c974941b314884778654da1831f41d838e,22b5565943863d9a82f6f0af17d0d8796e40dca9,c,c
::#,15063,ent,hu-hu,3222250300,2443754316,3eec65d51e8c24e8b0c823071ef246df465270c9,b50222d340eb136fd736f2eb256c97072ed74f14,c,c
::#,15063,ent,it-it,3272240844,2500145118,12c773f8db4c66d1a7d039e689a53e711f55b23b,1833f47a8968d2b31a8c90672dfb76d57a5ab022,c,c
::#,15063,ent,ja-jp,3391347078,2622699920,e214f6797b2f174db15901b79ae0285a0859e5e5,e7c95f7ecfc9a46f1a66479ead6c6fa6194c0e28,c,c
::#,15063,ent,ko-kr,3287839184,2511245616,801a09ef5a8b28a98b620bdb83472f2a17265e17,a7e52b0652ad20c351d8d5a79cc4e7904f48390a,c,c
::#,15063,ent,lt-lt,3204395822,2429457908,11584883f422bbd13394a3b7aa502572bf204ba7,14be449da61677562b2f49de9f401a84d6d2c88b,c,c
::#,15063,ent,lv-lv,3202719722,2429484246,c29e06c7e338df384fa4d0ec1798b07b4175056c,1b85049cb4f85c0a50723a17f2b566c3ae05aa9f,c,c
::#,15063,ent,nb-no,3224730246,2447487494,9b80ea391601f5eaa2dc82a86b51e4e8a5ef00d6,dfd2952d9ee50ffdaf70729577655fb52bbded02,d,d
::#,15063,ent,nl-nl,3233989634,2453608998,9d79d2877e7015039b7795311ee33b12e82103d4,db4d9998e2891a2c11af49e8edf864c4d669bee8,c,c
::#,15063,ent,pl-pl,3254871838,2474897208,78b3c876618557bccee0e9437466d70c0c136dcf,be5d2f555cdde8925c1ebd08a7f7a3222c9e612e,c,c
::#,15063,ent,pt-br,3271500426,2503336302,01c57b64de3a66b7795c363ce0b80ca3567bcb49,ffde6034bdc95b6b3d4e651a8677ddc6bb2d180c,d,d
::#,15063,ent,pt-pt,3240619572,2472391446,6fdb16fb6bfd01cc846818eac4bbd468731137d3,4d41383f7e149f8f332683a803e80913bc9b1dc2,d,d
::#,15063,ent,ro-ro,3213373488,2434175900,3b61d2d6592bf7172b20b6c087465e4e201a1b12,d150722d68fe7eeab6584e6b91ce40a51f6e83b9,c,c
::#,15063,ent,ru-ru,3276687624,2500599630,702da7305af22183af857b1d92f225ba89c846b1,e4925023ca2a7c875a257542177f51adef9ac00a,d,d
::#,15063,ent,sk-sk,3209901276,2428270146,2a76f3cf95bb8816bf2a4a77f60e5500eb0260df,2062f6e7a1cb1ae6dcc8755b6afec3cf92aaaeba,c,c
::#,15063,ent,sl-si,3205356168,2430123934,45c67e340e223378aa8aa6aa5678d1ac5e3285a1,5edf9bc85d7893d5f8489693be58606ffd0733ce,c,c
::#,15063,ent,sr-rs,3211056238,2432563554,59d39830461b47692ecb8d8b3d3d5b5510bd2b41,905b282702bd35a24335e13b7532bebdd6500577,c,c
::#,15063,ent,sv-se,3225016350,2456236258,d5bd28ea94a57f48c5dd9be95eaa77e1af5b879b,fdec6fe68064a5863424adbb88b1f3fab2f8f9ab,c,c
::#,15063,ent,th-th,3225739176,2452122006,10e7d1628d17f175c7be22b9cbfc31b0f4d6cf11,7e6804bb22e995c8d7fda7bf17003f1a598923c5,d,d
::#,15063,ent,tr-tr,3223779720,2446042716,2bf79ce9f82e719816523039c6219fcb1681f211,440ca442a89e088530739ad7b1fb911aa4455a06,c,c
::#,15063,ent,uk-ua,3231204960,2453614364,4689166d55d8b658144c219da32025ace59071be,e45c9e3569ab5763f1aa8fb3363256278a665d19,d,d
::#,15063,ent,zh-cn,3475307584,2693601882,ff6a432a6ee8204153cc057074fb07b5a41f201b,feaf7891cc55c6f2716923a5e5aad8c9edccbba3,c,c
::#,15063,ent,zh-tw,3402457552,2621863118,4b15f3fa006b472788efda8daae41dcc1cdc6335,ee8a66c1d34e68ba480b017f9aeed538a7847b05,c,c
::#,18363,ret,ar-sa,3534195534,2503681828,52fabba21d833ca1746fe01a9e140edc2384d2f8,b919ebda0e93697c8e07f45715c34d53a4550e18,c,c
::#,18363,ret,bg-bg,3616720365,2536193716,ecbaddb64333432ff362ba648a047126dc6d86a4,cf73a79d3e648c099b00a95b765967a2ab568f6e,c,c
::#,18363,ret,cs-cz,3596259408,2539164455,c6d216e87897543cd93c3849a2bfe1ea43f5a196,ca51e4668344315fdf76e1699885f80f7526915a,c,d
::#,18363,ret,da-dk,3626744664,2557337496,00986cd4dc16a7c63a9c38301aa99dc43b6da7fc,4539ccc6ec355dc9f6f9cc9f1bfea9b93ff06625,c,c
::#,18363,ret,de-de,3753625660,2653304701,d8be4510cda39d81db1db6a48cf55de0a48bb29b,9e20b40d3b3f1772d2e948a69de7580f16dc8c03,c,c
::#,18363,ret,el-gr,3625490491,2558937416,9644e53938815aca6294cc831c79200e4047c337,0d72241839cf34efe3633131a83656b4e92d579b,d,c
::#,18363,ret,en-gb,3726999678,2634727632,b58c7afb818787d7b637e0fa0536c290cb954b7c,d0a833ac07840929914661ed9c2c4e152a0aa43e,d,d
::#,18363,ret,en-us,3746732457,2646270866,170e462a455d70ca336bf4675c1fec02a21a9d67,c8393ee4bcb304ec61b5a8fb0198b60db36b4435,d,d
::#,18363,ret,es-es,3756800607,2650060364,ba78c4d274f2d81261a8a7f21217db93e11381e4,d7716927da2cea74807d080fbccb491ba1d8a897,d,c
::#,18363,ret,es-mx,3521473841,2523667818,10691b1f9528f21057bd3f8ff6a7e0a73dc3a6e6,95b379a02a112dee64bcdd5835fa06e8486e3b4f,d,d
::#,18363,ret,et-ee,3594420935,2517716050,e616b862e1c6889c7866fd288de94e1784f0b495,7cbded82f7c385535e50d471fba962ae009b4a38,c,d
::#,18363,ret,fi-fi,3598140463,2541038274,89647853e0a23b424df7c5d72b4ae20b3c41571d,a0552a455e7787aa5b874bc48310f844f8f65df8,c,d
::#,18363,ret,fr-ca,3547183350,2518932854,d02e9629c75a8668b1159bfaf67b64154e5a4a10,f4e2819c95f5bb788af96460b6e233adabafdaa4,c,d
::#,18363,ret,fr-fr,3757903522,2641536922,b52adfb7c2df14fbaaa1e7d3a8e6e8148283fb61,707ea14c6d9df9ec5f65927ea40bf6ff5f010b4c,d,d
::#,18363,ret,he-il,3499149195,2466957942,d73481b14d2a7edf88684e796fbdefce13e83865,4da96e9cb07d752ffee259c3f73c8e7fb277f9c9,c,c
::#,18363,ret,hr-hr,3601816053,2518725064,700f00793805cf91ee1433df7c47cf9938cd8c6a,d7fbc5fcc4ba5f87e5e27e5beb051ca41e34c717,c,c
::#,18363,ret,hu-hu,3606339666,2527574058,e0ece35475ef451705b078c8dfb87ce5b208c456,7f2fcbfbb210f071ccec0231af6ff061c4eb0927,d,d
::#,18363,ret,it-it,3659368504,2586153428,e4df1283e85ee82ca3e6a4ff8454709d0619e886,4a9c58e4a503502422b0df5d5f557b6d3e33e206,c,d
::#,18363,ret,ja-jp,3717942762,2722824559,940c15520159b71a4f902598b6fb11412aef03e8,2c2163574fb5e92b703b121a3f41f735e0eaed9c,c,c
::#,18363,ret,ko-kr,3509599307,2507662974,c6a9f46be961b555b02157f6d6564855d4ac2087,0c9f2e5c98a0772ec30d5e1a12a21abaa53ec14d,c,d
::#,18363,ret,lt-lt,3605328560,2525623222,77068837398c1bd8745a0fff7912bdd7a5af5f5a,09cf2972e2d643829bdcf0df2c4c31244a16a042,c,c
::#,18363,ret,lv-lv,3603336860,2524075145,b32fcc646c5903fe5f2cb0965064b7b4db41deaa,d9e922761da4550f3b2c067533e7f72664183818,c,d
::#,18363,ret,nb-no,3598008516,2537410248,d5823fadefe86de56f3b9e4ed82d2f537ffe6930,c1cc612b2d082e78e45c394ef45bbcdb2eea5851,d,c
::#,18363,ret,nl-nl,3602015901,2540847107,f16c02cd37e28d62d7cbae068b3665d711974498,8ead85f9e8ffb92f780ac4af6568972328224fe1,c,d
::#,18363,ret,pl-pl,3623954742,2562478387,32a2f20346023e15d3012c9b763f085d96d8cea3,5b2eabda21109a11d40c75d682e19580cff75e76,c,c
::#,18363,ret,pt-br,3526360750,2511295626,45dc921d718f454552f594a5118f1eff50e980ec,dba75f476ef36f27500ba89dd79e5e6a168e1dc5,c,c
::#,18363,ret,pt-pt,3654633787,2580822457,58dea38a0acc405ed3ff7d7f0bf57c971057ab5f,150b11cd62240290eef26234a9f940b4b9741f94,c,c
::#,18363,ret,ro-ro,3608412362,2517617112,775499dcfef68773c0981a601f3e750eb163a78e,0ee4b2af13c06d5baec4b2d3313baefb73a34df5,d,c
::#,18363,ret,ru-ru,3526653960,2520449336,7b09780c580b31b6c029f8bab6fdcd38300edb7a,d4d68912161ba7e774c1ae8bc2fb9b409f26ee37,c,c
::#,18363,ret,sk-sk,3592875792,2532722296,4b0519c5d29cd14ee60d569a63a61210714446ac,7d076f20902518c79e5c164db884ffd428e747ad,c,c
::#,18363,ret,sl-si,3590885252,2531509710,5d0a0450f5e812bd34f64d8baa329036cd57e218,db93a8696baf9f82099a08514186201db10b58fe,d,c
::#,18363,ret,sr-rs,3473762820,2459536778,46c0560c00a8d1610e80855989d3f82d613e949c,56f8d491ca221c6c24397cf575e0072edb62fbcb,d,d
::#,18363,ret,sv-se,3607556388,2539084928,a9150141b66cc5f777d1d25df41aaace1b6e7e4c,3a6733a0e6e671c39ce01330b67e7dd458b3b4db,c,c
::#,18363,ret,th-th,3473959714,2470289032,136e0b238ad6c9f68d8949b4e66e0a5ab824fd72,658a7a457de843392ab1412df9d36901dec962b2,d,d
::#,18363,ret,tr-tr,3454874782,2473688877,22a6aabed8919305484c64b721765594f22ce3bf,93782a360ca1ca008d02d3c564972eb4a98b37a8,c,d
::#,18363,ret,uk-ua,3480799111,2480365333,231667487f5d1ee0b628eb8f37e431e7f0b8d320,8cee39824bafe5385d537ea19634610571bc3a84,c,d
::#,18363,ret,zh-cn,3743699182,2727802108,2fab0741463c85d6c98e29942e1164aece5ea4a6,35aefd6712b6c9e4af8962c4a66dc147ca854fa3,c,c
::#,18363,ret,zh-tw,3695699407,2682296155,2fee332a79cf34665d0f828ccaf4516d28b0c85b,71f255dde4f7bf187d0ab6993b92afbc73870396,d,c
::#,18363,vol,ar-sa,3438487182,2463877856,44b7508dbd428c3770a4c6541a22e771880023f7,f6e7e559babf4b340dadd9167b7bd44b3392b48a,c,c
::#,18363,vol,bg-bg,3555503804,2478427478,18abc38b8244bd1983f0df9ccfed2fcae93dd5c4,43bd73e4967a0ffff46fdc30cb129cbcf21ec5b8,c,c
::#,18363,vol,cs-cz,3544206016,2456114546,7ea76b661002d51092d305d121a11bf3caf95ce7,18172af53696c48b87c88fe71890a1dcca493ae9,d,d
::#,18363,vol,da-dk,3548513556,2479829852,da3d602521690d82a22f169819951aea50674aa1,531fac95b3bc738e1c76fb13eec030c903e17819,d,c
::#,18363,vol,de-de,3688176224,2616340732,12d01c5ba4a9e496d113e4b16f407255c724ba72,8b65ec3845877f004ed1b024aa378c803c0d710a,d,d
::#,18363,vol,el-gr,3558884298,2481087098,7bb6a3ac13772230b607a4e483452a3d3e3e2756,53be030536e98a2c8131e3a40f53de117adc2c16,c,c
::#,18363,vol,en-gb,3624244211,2565433673,1afd7d55f9980e95c968699fb9d6a83f7fc1ca02,d098c781e57d62a9a9fd43afd0d5b8d4a50907ba,d,d
::#,18363,vol,en-us,3626567900,2586064754,6e83a5e8f3ca99b74467e51cc9f5cf4f8e5de476,d29c815c75e7d1e5ab9937704596f0bd97b45e2d,d,d
::#,18363,vol,es-es,3650584272,2599419212,2891d81c1a3690dac9dd62ce89977f94712db24e,c5855501e2374986e43c31172c3f1b8baf6e3a93,d,c
::#,18363,vol,es-mx,3430336908,2436459674,57503381aeb77cccf8294f4dafeab74cbe0ef950,e4d9102abc0f75c7c9c32c8395a39f41e07474c0,c,c
::#,18363,vol,et-ee,3518112390,2449000822,cbafb8998c1defd62edcf948d86117f3f5b4203a,4c4f949134b0e9d76203a78f3a9534c4c1749a11,c,c
::#,18363,vol,fi-fi,3543527114,2459816940,1c4873c5a5530be8b5a76fa5b3fe2fd60f5140cb,b587bfee033d54417305058f17a253be7ad57eb1,d,d
::#,18363,vol,fr-ca,3464877292,2486610154,751ad373801a67360eba3f7592c31f22715ca093,34928d27c7896afcd52b5df00cd8826beefc254f,c,d
::#,18363,vol,fr-fr,3625088635,2566787963,ebb8d09cc257a72fec8af3b672c0fffdefaac9eb,f4bdb4451d69216d4257b9bbbbdd246423b94118,d,d
::#,18363,vol,he-il,3418411702,2457925586,dfdb260ac42541834d64fba7c92fe9a3f44433a8,600f2217cf78951733e3c42f42ce768b357a2949,d,d
::#,18363,vol,hr-hr,3527137724,2460277762,be0e2ae7e64ab3e2f2cc887387137f26a23445ce,6a2b171dce7a6dac99b3351e1b4d9a6f06df3b77,d,c
::#,18363,vol,hu-hu,3539765872,2476271612,a8d08956fcea906d14a729927b9a4ff972c29351,017a35c75bb3691ef95d2012dbcbe19625fe48da,c,c
::#,18363,vol,it-it,3589744297,2511290334,3e5388a5b88a58f91fa46da5c0fc7127fe2a7529,4eb11a6b4213ed880da40e5d58002e4f27e30cfb,c,c
::#,18363,vol,ja-jp,3659614104,2658113529,47e797fef4015a2f8a8e047aac1bca08c959defb,bd3d9d8f4075959429984111c46abab750ca0ee2,c,c
::#,18363,vol,ko-kr,3449851782,2461608809,9cb9303f4adbe0fdd6fd6ea0e4c65fc574678e8b,6f9aeeb5c04ab2f2c4aae5135cd8137189c67f3d,d,d
::#,18363,vol,lt-lt,3518768755,2449382022,b5a117d824cb8694d41a45d97aa29b3a4911e602,c3d0b1200b17f4488fa506de4acdbc92b9980555,c,c
::#,18363,vol,lv-lv,3523056680,2449409594,2c5f7d4b65b276b27e6e2f0ca2e410e029492af4,0e4ac0ca473c37ca50ee9479793622b43a192fc6,c,c
::#,18363,vol,nb-no,3544730789,2461847874,aa05a78d662e07c5228e0191facb1dd9ac9f04a9,bb68b82b2dfa3f458fbd10a3c29443ffc58bb917,c,d
::#,18363,vol,nl-nl,3549561116,2458069947,9fe135842f500555cdd2bed9f0c1cd9286fe012b,dc2d1656a1f8999411858c30540c46fac671ccc1,c,d
::#,18363,vol,pl-pl,3572337138,2478124343,abc4abfacf682d93208e0bd3bd04977747dedfc9,febfc49e741b801910a02d670ab9b46f96237da0,d,c
::#,18363,vol,pt-br,3428726552,2444163246,4352b59c2bcdabfc0b7dc59e24174fe4ebf38abc,e4f04d8368d3598e2daf0a38039310d2697b0d15,d,d
::#,18363,vol,pt-pt,3565350068,2476180920,de29f9da02628ea8586c19c4931af73e07aa7dde,ae2a83effcd146aed0316252c94ef578c69801c9,d,d
::#,18363,vol,ro-ro,3517478570,2462901786,2beec4e4a9370638d81be6c13477047918781ccd,57872ac72196c4c262de113cd9c5b7c34db4f5a0,c,c
::#,18363,vol,ru-ru,3433382344,2444495902,e3b374d1718c3e59da1a3d0788ed931f8ba8b33a,11223ce1458f8bfd5e661a6db874387d4667aa1c,c,c
::#,18363,vol,sk-sk,3540286278,2457158107,232c2a415bc96faee36ecb1784aa424106e75d55,414f6ae918bc2fc54427685450a439c27c4e37c6,c,c
::#,18363,vol,sl-si,3541863904,2455048708,8cdd2535fb674cc31bf4d90534c510f20a74f0ba,ee84549e0c62fc4f115a5740a4cef7ce87f33632,c,c
::#,18363,vol,sr-rs,3370534021,2392943153,09b4929a17e4003fc49412bb66a15f63230d70b3,7a28f56020f0b1cbaa1337db93eb7a7addbbcc73,c,d
::#,18363,vol,sv-se,3549130526,2458325268,b107a4df6f20fad705ea537a7e5dc941d71f2186,ff0d69a33fde4e69806bc0b63b478e4188ceb44f,c,c
::#,18363,vol,th-th,3387929126,2411207900,a567f0a903a66963ec322ce724496a6597e14ea1,00c35ea978df4d6d85301077537c655c7410ecca,d,d
::#,18363,vol,tr-tr,3392986710,2389635164,9a2ba606d93ce2cdd3ae3911939435d1a088d5fb,ec4b9540928fa08e869434c27544b1fe2539f377,d,d
::#,18363,vol,uk-ua,3392754222,2413347222,2d69506768fdcea8dbba9db817f3061abf185147,b07a76669c2b2a7e90b0810d0c95f8719946392b,d,d
::#,18363,vol,zh-cn,3649266478,2647047456,47102873fd333e715f06c840e08a149963cfb6a4,8e1f607553ab7980c0c9ded018d8352b529320a4,d,d
::#,18363,vol,zh-tw,3629284727,2627531775,c4e3cea8745b894726133b81b9ad63c7344272b9,845b5ce812931b1cfcd665ee11b223549721bbee,d,c
::#,19041,ret,ar-sa,3424376474,2443826666,b318889964b75cef3a69ec75d28c7ef174157fac,34627c10a75e32440b8655fce3fa160b2561f81e,d,d
::#,19041,ret,bg-bg,3497891524,2461077962,89768c1292bb00d8bc59cc93a8bd31bf86fd0d60,b445575585fafced162431c8e491f35b20541083,c,d
::#,19041,ret,cs-cz,3489284116,2457579642,47089fda0dbd90725a7de74dcbe18edd8b10ffd5,b5a47c13798de6d47e39d82795d300c826e3e9b6,c,c
::#,19041,ret,da-dk,3507001682,2477282274,e4ce114cfd03048e730bd4662295ce780709392e,a59bd93c879daa86f99a1197de1ed1bbc9fab01a,d,d
::#,19041,ret,de-de,3614862366,2589284516,eac7aba66e17eed1405be412261ab2d232db0ac4,356c83719c01fa5bf454f6440a447dc226d354b2,c,c
::#,19041,ret,el-gr,3498039924,2468809106,e0ae333f9116e87cd0bc8cd6323bcfd18d793a79,26128c308750746770e9fa52a467dbebec6cd67b,c,d
::#,19041,ret,en-gb,3613068719,2567539510,f84e99690cc7b91e32ea810c5066a66d41d068b4,158d6aaffcbc3f05447d54bc29e0c87230e9a2e1,d,d
::#,19041,ret,en-us,3597848148,2571735054,06bd415350b963311586e1de57febcf257d9cff3,0f1b95cd0d53ba38bbcdc8c458ebfb87542d8451,c,c
::#,19041,ret,es-es,3609765180,2573133188,0f1a4d2a5a834ea061c0b181eae9222f41a1e7b2,755ac3d14b36876e382b8d889acfbb6d77c26447,c,d
::#,19041,ret,es-mx,3424062694,2442840954,db62d745b53bcc84ddea45736a2f49e7a44dbdf9,07c5d9d9a8c17d4ed831ca3e507c99e89226c05f,c,c
::#,19041,ret,et-ee,3456503784,2435272710,2ef7c92f0309c275f614b1575f25102c7ee16b84,f9e2a0dde19ce5a98ef62fa23850f2a1ea54fa7c,d,c
::#,19041,ret,fi-fi,3497923336,2464566905,43868003191ab607fd43a178379c322a0783355a,ea5f551e2b431bd528c7082e5f8aa80367ec9818,c,c
::#,19041,ret,fr-ca,3429493680,2463208232,e2f735e257f54396aad2d1fe3edb7d0b93503a58,a89f8c102b88384b797d8701a024af0959eb7860,c,c
::#,19041,ret,fr-fr,3609809548,2575907042,e054e10ceea4e5a745fa8af161b3cdb7e3b30ca0,97f0ac8d2938c959a40aff51fb00b015b13b31fb,c,c
::#,19041,ret,he-il,3387641100,2417997396,dbee3f52a33a1fa047e0ae2107cd1234b24b1bed,9744d0a39b5208975084d88bc62d13b85c8d8ab2,c,d
::#,19041,ret,hr-hr,3470072329,2438864354,75c479cde45f0947f1ba888ff43dc21645a60ba2,22068deb67b8f86e91242000158e3cf7c59f4743,d,c
::#,19041,ret,hu-hu,3479965078,2454964320,49af470384f50367f0da283b0a3cc8786c2ac579,66b3d6535d454ae1b46fc2cf1fc745cec4226096,c,c
::#,19041,ret,it-it,3545049736,2505035143,4c77371c4400e740a2c9587df2d9df702e634ef5,885c59294149196767752dc51cdada5f4e2436f0,d,c
::#,19041,ret,ja-jp,3567937591,2599663537,1a2dd0ed6cb646e9625542a85ffef6a3b85b6be2,5212ad20aaad1a86ec48ec74bf2401ea148e1f67,c,c
::#,19041,ret,ko-kr,3408943290,2428297516,309fcf1e62d221ef4aa46605720e4c98b3ebdf19,90f326a15fa2262821be32051d51f564738a8ab8,c,c
::#,19041,ret,lt-lt,3458060502,2434258738,3f58ab5dfd4d22c7608a53e4df20e09283120a85,0339147d76114c30afc8c534dd467b94d1f4061c,c,c
::#,19041,ret,lv-lv,3459293591,2433334878,82789facd7f365ac9b30c1ab817d0d2763eeedd3,d3a2550e3c9f1aff8145a407b9cfcd929275aa47,c,c
::#,19041,ret,nb-no,3486726744,2454241385,e7801f8aad13c147edaf4b81305cc903db1eac64,e706a4b35f245dad58cbe4a9995f4108863a3119,c,d
::#,19041,ret,nl-nl,3496217572,2459007239,fe71082799ca39b135ef9f79cbcd7f1c474ed2c9,bb5ced629bd6c4c355cba039f74390f96900b218,d,c
::#,19041,ret,pl-pl,3516672629,2478972583,6875b4cd91967e2ae66daf4bdb7b63b791fe1123,b4f1a225c49b01ead6f7ee29cea62f76d2fce28d,d,c
::#,19041,ret,pt-br,3429740362,2450903030,2860a35cb85fb005ccefe32227e5460f6dcd09b0,a096a5d0a35d4bf7e87f2a707f7cfc30998b5bd6,d,d
::#,19041,ret,pt-pt,3535617631,2494949674,ede953f70ab3486a942028aedcbf4b278db4d90b,bd8f218be4507c2dd628aba2bc1348041102d113,c,c
::#,19041,ret,ro-ro,3467100688,2438425587,5ecb0f93491e6b365452b098178b535f21700c3a,42d1e3d076ef3abc34881c910a235803230ed945,d,d
::#,19041,ret,ru-ru,3427409638,2445672042,958a2a4e08ef80cc8f51a6a2ec2e7cea9c1bdb46,ce67b93cc8a8607fcee480375180f98679d4f457,c,d
::#,19041,ret,sk-sk,3475940590,2440236480,2bc732a2e7f32361a5e5a8dfd8ef668a7e799021,4222b825ac5fd5f1d584f0a2b08d033fb3295a45,d,d
::#,19041,ret,sl-si,3479491576,2437397846,93b922173be1d4a1bd3e8deef75c4c2d677eb4ef,e98d3a38454a20a2d40ffae26d570b0be05e6a70,d,d
::#,19041,ret,sr-rs,3354336144,2378312436,94c1218ad5a0647e26f101bafa8fcc5aeb3a643d,90ccbf8f7809b15597ce3c81785b19c96c165a20,d,d
::#,19041,ret,sv-se,3495995024,2461632144,733d5a06b3a7e3b6d323f3de60d81358b37be3d5,a7f9db399893b571517a601d79ecebe2c3bc25ca,c,c
::#,19041,ret,th-th,3365441667,2391686522,536fcad0f98c0b33b9e4302262a11a53f0fb3341,107b585ad05e2ff14bbc179d893552a13da6d869,c,c
::#,19041,ret,tr-tr,3369376330,2388513330,e6bd2aa2fbc021259f0323565e161952f3e5ed87,0427edb24429c374e3578fd8353d96bca16e572d,d,d
::#,19041,ret,uk-ua,3371962482,2394813378,db50269f01b65a268b2d50315b6a0f930f8c36c5,e5633184a45a024e8823df4b16b43273df20f5bc,c,d
::#,19041,ret,zh-cn,3626392090,2639420517,97217085684d332e0e757b14a8aafb83ed4f9228,836fee7e6da1702baff5b1b70a31dbae282d073c,d,c
::#,19041,ret,zh-tw,3578643890,2599924262,357631c425711dfb56a056c83ede2fbf1f4b5ed4,4de762ee553d1215946f34a0ca151134dc99f524,c,d
::#,19041,vol,ar-sa,3337049672,2382164264,282a18b176760f7e4f558333b3b7fa5ca1160424,2d83c65b40d8541246a74347ea8f814f154fccd4,c,c
::#,19041,vol,bg-bg,3420008948,2405808668,7a5f62a3f9398759e0f8f9cd6082f5e7f6ed204b,e5502e4a3f055cc1302e46afe2c1606b68f3fa57,c,c
::#,19041,vol,cs-cz,3415536976,2403592642,295396d53ebd6b11f32f09221555f86136976128,fc6063ece178a987949b2ce467edb12fe3c00e09,c,d
::#,19041,vol,da-dk,3432382840,2418055684,cf4178a959823c7793da72655b112ed896aadcfc,36986250d3d4d7d23fa183fffb9b045304fe8588,d,d
::#,19041,vol,de-de,3545981312,2526462682,d8622fa89122a2e0e2c122bec7c7faab6552e981,a4b0cf2430fc5fb5d09f5929ba4e93299efc84d0,d,d
::#,19041,vol,el-gr,3421657688,2413797186,24be059f14afe6b7ee8b12c21fded81eec7eeb33,5d4021dd4c99d5abcbb9ca66fd6f5478e5554e14,c,c
::#,19041,vol,en-gb,3495718032,2489614296,a4d3fc298be25a876749f4d5c6adbb87adca612b,661023c661e83076134fb2076dbef1b13007e5ee,c,c
::#,19041,vol,en-us,3500119894,2494569638,a48a1cfc278325ab8a1c42ceedb987bbb80eda56,77dfcb554d1ae7c917ab15c1e9d0c2f4856ba9f5,c,c
::#,19041,vol,es-es,3515058812,2497868122,81da7db75f5a7489c94f3d4b6e9fe5a678763278,296d4ead8ac4560bae0fc2f23141c3b4628c8f82,c,c
::#,19041,vol,es-mx,3333388370,2381523108,12faa311404c11e48f0197c7301160055588421e,a33ee7767183bc5213e68948607546eb66ff36c2,d,d
::#,19041,vol,et-ee,3386938516,2374267332,48108700b1a40d847428d4306702eeb89ffdc122,87fe2d4d5371de17867db4e19578e1fb88d572b2,d,d
::#,19041,vol,fi-fi,3417568380,2404857436,93979b462f6e38fe7a3061848e13bcf3d7134a49,c7ca32216d18b1ac2296e26989106fce8aeb8adc,d,d
::#,19041,vol,fr-ca,3372327488,2406723436,c24875ff7d899d5d25ab2cc3161b29df93ceb907,88f10025b3fe0b3e6a4e88263942aae4e2425490,d,c
::#,19041,vol,fr-fr,3502615664,2494868554,78ac1b908a741e1c199843b1d178297befc53bef,24842f5b457f1588ab9d5d135b1c5399843a7242,d,c
::#,19041,vol,he-il,3326291904,2363110634,5e3e09ab97d25ebd43b7c7c64c3b2f6042a20a44,65f629dea18993e7e268a8ec219f57744e664281,c,c
::#,19041,vol,hr-hr,3394485528,2386293690,3957393bdc6a390b8ad8319a009482d634e9360e,8a2720641aed985b93418efade15b54f6fc4f6ef,d,c
::#,19041,vol,hu-hu,3410378170,2398604217,c0fd037cb6e71b3d8ff1c65cd0709ad4be70766b,8a515e58998334e61bc7da0e7575798303cf552d,c,c
::#,19041,vol,it-it,3456571166,2449850778,146c91ea307ae320d92fe1de52ea6dc1c21ef9ed,e46d46f366ca52a55a333446346fa44ce9ca4b92,c,d
::#,19041,vol,ja-jp,3516513370,2555241626,0d240e868c78b6657f386764bd64c1c0af2928b3,a4deb7d5ae34fb573c2e2608c6f03949ebdb3912,c,d
::#,19041,vol,ko-kr,3340000358,2382413742,67249288c44f559383c965f29aa7345c2ab4986c,ad31a542bb8ba7ab4f3d588fd1724e5077396480,d,d
::#,19041,vol,lt-lt,3374755582,2381555458,89158b640c7abf5d6ca555128e5a79315937be82,1a0392412c4686e8a2bb7b03414f6573c2c7cae0,d,d
::#,19041,vol,lv-lv,3376297534,2378948437,745fbbb5342bc0faf920933b5765cd46d0a4158e,cb956ea1f98a3b7abdf08cc8d8f46da1518a1e36,d,d
::#,19041,vol,nb-no,3412829848,2393852905,7ab759beab49fca69bbe4a237f8b22b0ad727e5a,69484d076fa1c02dcc65aefee68c0185f9de0357,c,d
::#,19041,vol,nl-nl,3410125156,2403615762,8174ede338619dae1d12ef2598cfc7efd5252e04,90238ad4dfdf83e9ebb532c56c54b6a3998dbd0f,d,c
::#,19041,vol,pl-pl,3434908644,2423333360,19edb7eb5299ad68084f81195fa71a8c138f0928,3984fc3d439902a6a9036d37a38c3c164470971d,c,c
::#,19041,vol,pt-br,3338185264,2384769636,0d9440dc88ac9bc801bd7bd2447d2c0b8a522794,ced8909d445026b240c7ae8bba928876d1592dae,d,d
::#,19041,vol,pt-pt,3431843388,2419892541,c393edfb10954926d28d52524ae46564a9e30313,1dbd60386a2ebe8c55bb7ef768ebc6899c570120,d,d
::#,19041,vol,ro-ro,3388179067,2387319172,770d4f485f0ef4d1cb2ef308bce57dab25b6b356,072034bfe8b6bc8c3091c81a601189106c8a6244,d,c
::#,19041,vol,ru-ru,3337179298,2379751666,ab11d756a8df20207fb54bda40844d4c24578bdf,0df5eadfb28ce196f9537c1538f49310f5aa0795,d,c
::#,19041,vol,sk-sk,3393372124,2390659820,c811826b28d6b5fcac627af8f9f17b9ec1d2b44d,ada3ae7425e811bebcbe37578360ad614e21e720,d,d
::#,19041,vol,sl-si,3398150744,2390916654,0bd241b3581f18103e5666acacbfa2192dc40939,75810797378b6617af7ce70bb6c7c3f128d15c29,d,d
::#,19041,vol,sr-rs,3258181170,2317685258,9bed7c7572427f5799d344e084857ea804f50c2e,2cc9fdef0b0e1cb0f88059007bb89dbc1890f6ac,c,d
::#,19041,vol,sv-se,3416343626,2402913840,a539d19e9b7ed95f1964c52475c79bcf3e37ef7c,015b5031c9179fcb9bebb12fb3459eac450fa5c4,d,c
::#,19041,vol,th-th,3290469514,2333566872,5176637227958a753c31ee24b058c6b22a8577fa,5c3af190420d84d4fdc2d7df0ce7cfa0d1ac0a4f,c,d
::#,19041,vol,tr-tr,3284251716,2324670322,5bdb765df04960bfa3485620915bbb70250b884e,697ade3f5f60e132efb440ec4b39829daa6d072b,c,c
::#,19041,vol,uk-ua,3286815020,2331143230,d661873706320af9226e0e9d94eebbc0fadc46ef,d3ca8eac86fa768f46e38af53dcec7b7c4c3450d,c,c
::#,19041,vol,zh-cn,3535283706,2584167773,f3515d1cb0ab219628c2a18e03fc75cb7dc11b86,b9a4cd37887f3fdf0715f2e0a5126b11e8f7575c,c,d
::#,19041,vol,zh-tw,3515637448,2554871592,4cda25b41f80e6d091135c43d90075bea1ebb8e9,746713766579000c9f9882179e8e907bfd995e67,c,d
::#,19042,ret,ar-sa,4144752120,3069996812,c5e20b8b9e9e357b5eac0f1b4daf27437e405a98,8e53c64e657833c5201d3e8011141ef9603433ed,d,d
::#,19042,ret,bg-bg,4273660900,3132767383,290eaef0e89c9374f8a85f22ca89da55f1ed3d4f,b1ddd971c9408d4f5d3953486eaa71db8f8d01af,c,d
::#,19042,ret,cs-cz,4266525711,3141417920,c9a31d4f86ea028f8b54abf5320426a1042739f4,6a5ff8da0af584aa217643c58c3dd27ac5639ed0,c,d
::#,19042,ret,da-dk,4277198628,3172322209,8faa45a5e36e200c991f96b5d03713d177392dbf,d28ad12137315b78ddfec39b398f7726c988b376,c,c
::#,19042,ret,el-gr,4286406975,3156522926,3b4b401e6f07d4aa61e2800665c971a6c3a5ec3e,4db08254c310bc18b18d48a1a1b140bddf6212df,c,c
::#,19042,ret,es-mx,4136440145,3071040092,b39b9725d6724222355ab51dc09b71a65ee808b0,6a0c555edfa352a53c094f8fe4b5f1e5b3a80fc7,d,c
::#,19042,ret,et-ee,4243981042,3114898234,721f6aeef310493ae2a68b2464c3395c37de02d3,3a5c1f1c052cfee024b2f97eb9dfac3c1d835420,c,c
::#,19042,ret,fi-fi,4285027992,3131390225,95b0cf42a3c3e0a7d90f06353aa4f66318a18610,7b18c0e5be70e65f9f57efa06c20624c9f4aea04,c,c
::#,19042,ret,fr-ca,4140214723,3080125608,a54a32bb93a8ff87140c7339e3bf885c73bc1048,35fdf7777c7e923dc9163c0e9ceddc5157e70eb1,c,c
::#,19042,ret,he-il,4102091978,3041784317,094e61c556c8a6af3f99ed2e091cd91231f5ed34,00e1293e30bb7c4115fc04f4b92a3df19a88f960,c,c
::#,19042,ret,hr-hr,4241729051,3108733766,cac865b558f0967196eb375ae3f63e6a1982a8d4,e57fe8f5d322546b65a194cb105c3905b8dff3aa,c,d
::#,19042,ret,hu-hu,4264742770,3148275898,41ee085b20c3d4525c6a7120d4f209b36d4865fe,d257c0906daaced84a7e79de3aa6c58cf9a6205f,c,d
::#,19042,ret,ko-kr,4111939832,3055115335,87f123052a36a0782874bf0025a7b1c8334575ad,7d6acc7ef7f7e98a1aa676772401e62b7f6f1736,c,c
::#,19042,ret,lt-lt,4248793438,3110403124,eeec57087116db3c1db2b0862b0edc870a1add01,c33648d6fd31141675a3aa804247a6958d77c560,c,d
::#,19042,ret,lv-lv,4233190462,3097361144,5d20985e16fcafd57b7d1c0870112cc73aa5e2ec,de712630acf39d4191c04de678e53dc78397b58f,c,d
::#,19042,ret,nb-no,4267105411,3139346967,51dd71368b0c680a52381e4b9bc2c1ea521fcb3c,12c4865917a8780922304cbfc3ec0f77dde46681,d,c
::#,19042,ret,nl-nl,4271095900,3118770342,bfac21d14ac28e81f0257dab14a6ae24f5d264ba,cafa08c0892c98e1fd4f2da37d8a2e52f560891c,d,c
::#,19042,ret,pl-pl,4289923972,3159835035,aa5873a2ae228ad397df4d781522c1c6e7ae7601,d8d189df881059404e08da271440f8882c2276d4,d,c
::#,19042,ret,pt-br,4141680670,3074275948,0dbbc4293c468298358f32ae2fc70672bd8ef865,77a8e7c6a692a4ddddeb47cd96ab5ef8b2d1a50a,c,c
::#,19042,ret,ro-ro,4250933129,3114487464,15f730a42ac220ab73e80c46ebc2eae1908761ad,a3edd4b0109b057891e9911bf7cda2353ccf6b36,c,d
::#,19042,ret,ru-ru,4146895708,3074675530,07277c99b6dccb64be4aa1b09bf5886662b64160,b814b43304f277307d8c00dd6ac23a4496a10930,c,c
::#,19042,ret,sk-sk,4252903736,3138506076,2c514f19c1e4832f9688afeb78e4fc419ec484f1,19e20b3164eff8abf2fa12feac50a5abfc183000,c,c
::#,19042,ret,sl-si,4248478064,3137763890,7c893eac0f1ffd9ea0c062ca4cd17689acbb29b0,07df0ccc583361fe1482add0ed2a86becab99dfd,c,c
::#,19042,ret,sr-rs,4072233446,3013740128,362f07585594baeeeb7d014cce118124ae4abda1,3a69e013344b782d6c8865e0e7c561de828f3822,c,c
::#,19042,ret,sv-se,4289371571,3146005785,a6ab24bbe1eefeeb7d8e02ced05ac52177b103dd,9d8d613c6fd1e28628228b9d44d0cd7c2dd50f9c,c,c
::#,19042,ret,th-th,4085961227,3034206679,7605e8b4b305942228d86328e568a8a2ad256127,d1f8d0be8ef8ed7539e5d586f4ddbfbf8ca47ce5,c,c
::#,19042,ret,tr-tr,4092026747,3016412954,0593f24849ea19b18a9846cc393d92e7c06ae090,e7b0fb6a83d0ae794cf01f2bf4e8e5e38daf692d,d,c
::#,19042,ret,uk-ua,4087452987,3020783590,3e7e75ba23674938e945238c89bfdb13bc20733b,9f7dc72d30aeacb241213e1bdde83f9cc0314cf1,c,c
::#,19042,vol,ar-sa,4016364432,2980601274,32d2f930cadfdd26c0af6d46c522187f56d27585,f075e5d4d7938a4113b5c95bc63bf6f0bd22b417,d,d
::#,19042,vol,bg-bg,4144049644,3037145305,2188560ee3722d14aac06a1830e60220f302e513,7b4d444aad37fbcd813c1306ae25433ae1440dd6,d,d
::#,19042,vol,cs-cz,4154663853,3026661906,46f09ce7f4ece42acb38ec276d14721c0dcc41e4,24344c721aaf720a36a36bbc33c09d0f2ce10bcb,d,c
::#,19042,vol,da-dk,4145622613,3053546243,4888ba7b7de1101675776346e0958aaa1f6ffa08,aa705cad406b81f5192e5bd10adf12fe8610379a,c,c
::#,19042,vol,de-de,4265993158,3164360441,308f6b8b7c369f1c1296d14eb2c7773dca0e0427,3e49d437c85f4d296defc07d6a2999f09e10b991,d,c
::#,19042,vol,el-gr,4157356786,3044012488,8aed0a4c8f48cc4d474f972de17e36e717b0c9c6,c2d3bfa245a79a9b96acd43d052e6da2843f86f9,c,c
::#,19042,vol,en-gb,4230881131,3114436693,600c4dd3705ee987d28e91be897127aabd3b29cd,f2ab05cf2a25be7995f3bd66147bb6179fe38132,c,c
::#,19042,vol,en-us,4209286277,3125180216,db2236f14e920b94af43e9adbc9061aaebad0651,7ed8b93befe6445abf71774a669bc6b8a86b9448,d,c
::#,19042,vol,es-es,4216868166,3140713925,c3e2acf2284fa3ee28b722364b6ee3d8ecd6f8a8,76dc11a04afc1b1376be2a061b138b566a8bfc8b,d,c
::#,19042,vol,es-mx,4016577223,2980802788,464558817181406488def89478e446e24eea8a1c,7e4e056f8e41c2817c9bb0959151eb3ed398fd06,d,d
::#,19042,vol,et-ee,4096449296,3010027512,62836928dd5af6e0902a4e824b0467b3448980fd,723836772c31efde3011af76d0b0115d017caf4a,c,d
::#,19042,vol,fi-fi,4138640032,3037212325,793fc8eb55201639f4d8f99f2d3439726588ee86,e21d45b5a580b36377d9a8103395c9357faacf77,c,d
::#,19042,vol,fr-ca,4050202826,3015230880,8de42e2037965682958fdae92eff54749879a598,5fae280d66062b729da16c0e15ab6ce324a5c0ff,c,c
::#,19042,vol,fr-fr,4221320264,3132074853,ec2ab2b0985c4e5996ff4403985fbb3d28a10ca6,556877233ef7748c1589d4bdd2639285e843fa86,c,d
::#,19042,vol,he-il,4010441856,2970047793,0be00d91b629b29f546e60a7c281452c30b49b86,14108b23b39bd1c00cdf117d6c7a6c0fc4408a21,c,c
::#,19042,vol,hr-hr,4114471022,3014272777,5299be227cec6998ea17dbed5cd88c828408483d,2ae1eff2cd0349d428854d5affcf958533de52ed,d,d
::#,19042,vol,hu-hu,4132688506,3029442245,500888357633d20560be39a91dd9a3c5642b21c0,e0df3ef1e19c024e662f1a8cfb57d9195d13f51f,d,d
::#,19042,vol,it-it,4167802742,3088429498,36017005acb9dc9681c18fe4283d69d81319347e,878720f72ced369f81a6fea3401a78427251bf2d,c,d
::#,19042,vol,ja-jp,4209022788,3157331626,b00ff4131c284add724c8929582e6e8c0c7f46b6,1bc737bc38fdc1c434f7ed3932ab56c52e35ebe8,d,d
::#,19042,vol,ko-kr,4025507868,2981909215,5c45969ac0acc16d036404c1e76dcad424ae5432,636f7580422a18f31f076a47cef5e6995003841a,c,d
::#,19042,vol,lt-lt,4096285856,3008967929,7bb53a5d1e6cf4bf38d35e40a9db1062c1c0a613,1cb91128065fc789754e1c1326498c96f8168906,c,c
::#,19042,vol,lv-lv,4101242345,3002808735,400eaea84ecf41c0c239c670174fc48433bc79f8,9e0082962e268551d9692328fce75b8d272728d0,c,c
::#,19042,vol,nb-no,4128611862,3024759592,3365382fc2f77ba733d96868b654bbc524550aaa,bd172fd516e90a6aaa6141a0af434e59033afc89,c,c
::#,19042,vol,nl-nl,4126584980,3027881534,5e28229afc9402bb1b46154ec22e620474917b54,08fe6c66d72dd197034e1352cd159105ed83da9a,d,c
::#,19042,vol,pl-pl,4156995746,3032612648,51d7291a9f1b1103468cbc442a47c2af306eb12a,b62e1cb76c58fc5bb676c5019e305b2b888180fa,c,c
::#,19042,vol,pt-br,4021228900,2982044418,a87759e95faee7fead58d4dc027f4b7d9dddb370,4a2dcc3a8b250f280c7d51228f9c416d8d8d642a,c,c
::#,19042,vol,pt-pt,4148851124,3042018418,54775912f0ca630bd4bcbbbd8cbd7e9ff8cf62f0,d7105097f9359b5eff3840bb9fc016379a2bddf3,d,c
::#,19042,vol,ro-ro,4112482183,3007208028,b052d5b92a8442acf5260bc740468ab4028a7d9a,5a7d1a1d81928caa5d19a85b98821762eaccfa17,d,c
::#,19042,vol,ru-ru,4018629888,2980422186,2138e94a2ee950b3190ce8a89ad3249cb9bc420f,e451453e64f0260a647eb557c39172e8ba947a42,c,d
::#,19042,vol,sk-sk,4131942008,3027718424,f04a492a2ef359ce620a97ba192f25dfe48985d8,d174644f56af023b86cbf91a89081cbc3c33d696,c,d
::#,19042,vol,sl-si,4109541468,3024677772,603fed79a973dc1f6a5787401285dca74d389624,ecf966948955ebc3c4abc452fdc82e210cda77db,c,d
::#,19042,vol,sr-rs,3954490428,2915016144,bcc5ccc2f05708f9f73c6ec2b5a8f95a68305b97,8fc9da5ec50d37718b685a9886ab2b9082697525,d,c
::#,19042,vol,sv-se,4134391226,3038464761,e64abf64f86e4a08615522995c36c01b01d3ea80,57fee08fb31e833151868718ad27d036c0996791,c,c
::#,19042,vol,th-th,3970617681,2934741323,e288f1f58e536086bf0bfbab22cb9aed0cf15606,fdfb62e7c0a15300d4a787f517f641a10a7e2b33,c,c
::#,19042,vol,tr-tr,3969027550,2926476964,b2072fd63ecafa22018a975901e3cb07d8a9041d,407ce5a9f1967b8a64f60f0eba33bcceae1807fd,c,d
::#,19042,vol,uk-ua,3967514562,2935859126,b90b0e27d64e94b015a4e6676b70bfc605ead499,addbc9de2467235ce16f9cfe9412329fa314d4ce,c,c
::#,19042,vol,zh-cn,4222077319,3173116376,b2d57b624a65882624df8c073075866a8936805d,8acbc8de96ef2a436881d1d7afae183d7f9c0506,d,d
::#,19042,vol,zh-tw,4201853468,3156032078,de338634b328c224a685f7508389833ab4d57ff5,d2a07c7dee382d8977ebeabf1b348270d450a192,d,c
::#,19043,ret,ar-sa,3796522540,2713987215,a96b496237751f6ba7f5db7e1d150564e3a1f6a0,fdeb6956321ecce439c0c346710befb36dc43032,c,c
::#,19043,ret,bg-bg,3855537865,2738961802,a4660f3182dbb0884e1312bcc8e7644f68c4abf4,79650464fbdc6dfcf01ccfefe5d84a13ff63367f,d,d
::#,19043,ret,cs-cz,3860257648,2730367672,2a6b3d2c48c48ae4bafe9d28af87ef351234e950,c972560c64f3e2f624d39ec713dccf135f75dd05,c,d
::#,19043,ret,da-dk,3872048120,2748761262,a0eb5f64e28d6e71dc36bf06e1da52ab9020c824,2ab6a2292146673fcdfa57ffdb5bf9cd15707edb,d,d
::#,19043,ret,de-de,3989757892,2854635078,30ac163215805d63cd91bbedcbf6b533ed3f407d,5cf792c1f99fdc93076a1d38b3780a2206cc4f99,c,d
::#,19043,ret,el-gr,3866106347,2748627157,7f8c53497f6ded42e640e56e918aa1fa7d6e5d81,e1705142d2ab3d536675aab29e6ae90011d825b0,d,d
::#,19043,ret,en-gb,3973458712,2841800898,82049141cc986140614746b509305869f906e56f,ff5724e9e1f18adf1eec3db2d6a71910f9679606,d,d
::#,19043,ret,en-us,3974282652,2850851984,97ae12fd67d7607c94c39656e2b2f84ff9083874,086af468927c859b65211bb0d344934e702ee9d1,d,c
::#,19043,ret,es-es,3989398530,2850298612,65ef4f350f8f7c14c1d33deeb0eccd19bf9d0a2b,16a4b847adf026a2664a6b808c0c7d7653ccc20c,c,c
::#,19043,ret,es-mx,3786477145,2714499292,188d86355450598505b27199b40b160095b67f63,934c7a8526ac30e046bfb40008a0f0944efebb67,d,c
::#,19043,ret,et-ee,3825511706,2704661560,b452cdfd122d0d2675b464aafb7c252ab2bf6960,ab64678f056c20ab55993e5ca92e2eb6fe026a58,d,c
::#,19043,ret,fi-fi,3858209670,2732403980,123662c2857e6b404b0b57c397c4086fe7ff1960,98c1c6f19656d27ba7d1b33af6796f79e129bb3f,c,d
::#,19043,ret,fr-ca,3799344776,2724854454,6ed180fd6c455a912f9521bf356a2a4a987d5e5b,290794e08365ed208a5788cbe895907265cd95ae,d,d
::#,19043,ret,fr-fr,3978409144,2848422250,d364ea01a0b89d1c7000ee96ee1f9c8c64a5e780,a922cba662d35ec5336e900344710c7a9d3b65b0,d,c
::#,19043,ret,he-il,3756567981,2680256700,8d06b301277c86f18a2f882a2514aa416d63045b,2a1fca0d8ce7f06dc9e1b93c0cf6abd2254a6204,d,d
::#,19043,ret,hr-hr,3840082670,2715740460,43b350a90d09187635cf7003adab8ea1108e7887,5a25211b17e10bfadb5f09ba77e221989323fede,c,d
::#,19043,ret,hu-hu,3855334400,2723746022,ede315a7f48ae622f8c7abca458d19822e16369f,c46d7f82189e12b86c6c16d442ab8fb40bfeefc9,d,c
::#,19043,ret,it-it,3898167798,2778674122,232eb5cd9e0d819e3e41a35b505cb76d2b88dbaf,5fed2da6d2063bbb67745a1948bf100c36d6cb53,c,c
::#,19043,ret,ja-jp,3934462658,2873797746,03cbd112658d3ac55d3d3082a8e1cd8fb1f6fde1,997d01f63ce38310fcbcfaac7ab9f7af9c793628,c,d
::#,19043,ret,ko-kr,3767999298,2702420272,243ed271b7f5c5b3618afe598d604467f12c0954,5d073595a84195221d72ef871fe1b6d63cd16e9b,c,d
::#,19043,ret,lt-lt,3834528626,2709606672,22c27ed2afb0662b234e56ef3d92d1f53eb00218,7e09cf821207440a89bcc5da914075c4e41960c1,d,c
::#,19043,ret,lv-lv,3831132668,2708793194,9d389cc1c57ae29a7ddde3b59cdcf59d5ab18536,79f96301a6fcffbb0c6681ee576ad172a919e429,c,d
::#,19043,ret,nb-no,3849883280,2726927211,887e4a9560ac6a389da978d7b7f3f390bde33ddd,4eab8264057c4e323beda781a5cf2ae1a5271b4c,d,c
::#,19043,ret,nl-nl,3854357670,2732550676,7a160fcd48ecf3e0dbd0c20875aedd6b86bb68b4,2cd49b1bc6b87390e309bb39795b2b1b889d2d4d,d,c
::#,19043,ret,pl-pl,3879400120,2753211546,89aef4609e5ddf0a5cdb08568c0af9b8638fa618,f5bf3ae2c565091f18967d0b6c679adbe7a09fb7,c,d
::#,19043,ret,pt-br,3790366014,2718398488,ffe1ec2f72cb407ce0d405d0a1a2ae90cb4a360d,147a5ac5642df489d6f54568962fdd1a5686d6f3,d,d
::#,19043,ret,pt-pt,3899594242,2768338085,1048ee46185479234f6bd49f40ef529d5c5f5a29,42f65ebf1614b80ce2ffc064e2948e4389467b05,d,c
::#,19043,ret,ro-ro,3837675212,2712810336,94e714deac7caa30c04d88fdcbfdef13a0f03465,1042981cb1c50aa78b9e161b5a3e83ae65276ec2,c,d
::#,19043,ret,ru-ru,3783746859,2715809468,a1928240c8fef564914a5eb09dacae32d24f4887,2413775bd23d0ee2db14afa7e318ec829c54fe48,c,d
::#,19043,ret,sk-sk,3842413417,2724595046,90e24345650de6050bc59af840881b28bfcada25,c8060187c27569f37f334fdb72f90d16669edb5f,d,d
::#,19043,ret,sl-si,3834982238,2722513656,9ab5530f86b6f890c6ccceea0765d0d0ad3ee875,a519880ceca8720c7305f2d0cab370da94b7a9a2,c,c
::#,19043,ret,sr-rs,3725972670,2651869220,568e0ca59daae2ed06273b022428676e7d620475,b2a0f952d4506bcc46348f2394306976105a38dc,c,d
::#,19043,ret,sv-se,3849856794,2730842070,d4fc52b4840f37c481c98ec921d57e6b5b3e7606,18229ccaa8d1da39c69f5131909cc68daeb7a1bc,d,c
::#,19043,ret,th-th,3735662520,2662934830,da093d61dfef8cdee09e89e3cd89c995c7cd2683,f28de6698962d9fae24a04767a81ebe3448b3025,d,d
::#,19043,ret,tr-tr,3734875173,2659088703,90572949d4770ce9dbac075a14e64bbdd8b01cc5,515547efa30a54e00eb0c36ce792f9060c018807,d,d
::#,19043,ret,uk-ua,3739508766,2666501848,e2e5933eddea1d21cf19da9f72ab5b6187f98141,c498e85cd3787c6d84c20b4aef2339fa62f776b7,d,d
::#,19043,ret,zh-cn,3983536850,2917424552,eea323e2b883527bc0030086427cd999addce5c8,5dc44eb6649d5aa4ef0bb62aaa8a9c830c123108,d,c
::#,19043,ret,zh-tw,3937475768,2873543704,a7cb5baa5a0bc9ea8ef71447974e3828d2a680fc,234d34a84cfff105b74988711dba42e018fb585d,d,d
::#,19043,vol,ar-sa,3681349114,2646952460,ac4eb087416cbf43f95d2947226b0400ffaa7ded,a5c2ef6265c6d3b532b80bde986409434f30626d,d,d
::#,19043,vol,bg-bg,3769063484,2680914283,150972ec66bcb963c4bf5557cc84e9b74b2f5896,77b22b31e37e8035f907804e8dfc94d648a4a747,d,d
::#,19043,vol,cs-cz,3765230072,2671454164,84e7cb7a6b8ceb4aab38840eea2e5865f7e25170,659f8dfbc1198bd58641e597cd57159291e41bc9,d,d
::#,19043,vol,da-dk,3801864686,2696475548,54150711b4b461f05d58fa9bf6a0051f4da2d0c0,fa80f90cf45a4fe1e7c794d0d60bff4deefe91dd,d,d
::#,19043,vol,de-de,3895418564,2803314922,a93fbcba42b4d93a267bed61644099594c77a645,bc70f4b6fd45dce05ceb9ac3aab14b241aa69857,d,d
::#,19043,vol,el-gr,3798485628,2694033004,d9440fe1ddb90be7a5fd944ef0163e6aa9b1207d,a38faab6ef7875066f380d76fb8f71a76ca27c99,d,c
::#,19043,vol,en-gb,3861880618,2763193856,27cf2cc20097af85ad40fbf7d29a4ddaa0b17f1b,6e25a693c5bae912b23050ea093c00040d81f558,d,d
::#,19043,vol,en-us,3862540292,2771733936,1f2d5c58815a486a9e67220aad3133b0bd45d0fa,5ff7197abe3c121fdddbe1b29f3458a124f66fdc,d,d
::#,19043,vol,es-es,3863207544,2771570820,fb0d0dd3b32cfdfa4280a9283005327746934227,347454d4cb18c18a2a55bcd60f071aa324fa2580,d,d
::#,19043,vol,es-mx,3692920220,2652566433,744f78d58d1c9761a7b18f1faeb41d7127a561b3,5c0b72a67346309baed354ffe495471ffa063003,d,d
::#,19043,vol,et-ee,3746211708,2653310406,3e49e62cc76b39503fe38b7778a6bd7f454ba1d5,f9f99bcd52967b9b8cc4cb48753bcfb502ba541e,c,c
::#,19043,vol,fi-fi,3775617860,2674949366,c5fcbad8fb3f65f716e5765c1a65b3a60c09bd58,d280e6407e92c0d2b16d08aaee5c7d80e174e1a0,d,d
::#,19043,vol,fr-ca,3723802142,2679860708,ad148616be82e9def492a7521879d5c34941c8b0,421e462990adb46ce461dd58a0c251cc1e1a66c4,d,d
::#,19043,vol,fr-fr,3877126596,2772626392,71e1e96bae79bcad1f58f7bc5133c0ec3a7c7ce3,3c69e6a461e3406c00116b9a2af6294c6460e6e0,c,d
::#,19043,vol,he-il,3678136944,2634537427,8e76b34503f79c906993c96e2e2e630be43c55cb,f2f06cb6d9a2d3d336c3f980b1ae1f1207751a46,d,d
::#,19043,vol,hr-hr,3758351648,2661855904,f50fa37afcbe2fcfa756bd2d755e2025f055da74,f1f3f1ce8d3b6b1a04ea443aa12e3f762ad6bd35,c,d
::#,19043,vol,hu-hu,3767182826,2671837114,c2aa0171f4ceae2e681cb11c45a44bb024d8b798,434cfeb94753630a258e44a37c08f0849020bfa8,d,c
::#,19043,vol,it-it,3824166620,2720100031,90ea853626fb3a9648ec7c22fbd3568cd44793d8,20c837b00595cfc542d5ed3e366cb295c1a2d016,c,d
::#,19043,vol,ja-jp,3852227440,2825404136,8f46bb0ae601e21d35478b64a0effaa6033ce970,9904a2328dffc1f644992c34f6cb425c1c98004a,c,d
::#,19043,vol,ko-kr,3694555939,2653883816,ea1f2db1435385f602e2ca5189a69c38f348d788,960f3775af64f723d396053ad6a99eeedacdbdeb,d,d
::#,19043,vol,lt-lt,3749684208,2653888476,16b48b9fc69ea7bb8e7b750f1f13a180552d39ed,3cfbb1d7e6de564c508f2925d8e2aa58ded4a846,c,d
::#,19043,vol,lv-lv,3748672775,2654182536,20c2f975c26552bccf32463960285f59e1a4b3bc,1410b8221237df0953fcf79a6b99b5e1610decf6,d,d
::#,19043,vol,nb-no,3762419328,2668386204,92c91748692c2a5938c4b0289ac66f9bc40ff46e,68069570fe5bb157c02ee70f3eff68a9667d9419,d,c
::#,19043,vol,nl-nl,3765536364,2672762084,33557696b5101175cb1661a9c580644a2d3b0717,c937b7557e722c6f22916e745f550834ab94096b,c,c
::#,19043,vol,pl-pl,3784633312,2695364514,b6a6417fe0ccad754d5b674c61153742f4eb9aa4,892094ba23aaf275396fdec144372d1fe3daef54,d,c
::#,19043,vol,pt-br,3699874600,2652863862,49da78fe39acb44af7a8db3d0195fedc6cb80830,a57ac3dc593fa03b44bd9a9646d0630af2236f12,c,c
::#,19043,vol,pt-pt,3790454870,2689698006,8d19690c39bdecb71783e1f648214f4ed286d953,e6bfa05b5d299d6fb53621d8711060934b2e52fe,d,d
::#,19043,vol,ro-ro,3761724551,2661041381,ae3a8daf40546b56fad5182ac1c9ba2a56da72da,62f8c112efe4cb32662e8b178b9eb115e2240ca5,d,d
::#,19043,vol,ru-ru,3693672396,2652263480,6c5d3e7a58fa81d0ed5b848f698afc5422743798,0f71c6005db675c9e217b95d3bc8e5ccf1137c7c,d,d
::#,19043,vol,sk-sk,3759652048,2666413270,e3d7dadd39c8f9810882bed9e25894bb24d5a6d5,06636d71f4b3f22d4262b216a392fd5611776f57,d,d
::#,19043,vol,sl-si,3762134544,2663536467,c2b702c8aed12c8777ec53500d1216aa79822e69,b5b8e1f9760bb8809ad84b653ec87a70d0daed92,d,d
::#,19043,vol,sr-rs,3628255006,2587775675,903985c87681f71f10fc9638903b848405b8055e,c6cd4e35386c6bc4d3364b209091bc1bc5ce1ae0,c,d
::#,19043,vol,sv-se,3769014224,2672801020,3e4a47daf9dc81a3e55456f5e7c051d6d51e4bcb,1ea327d60d75c6ffea8e43e32fbcf21dc071197c,d,c
::#,19043,vol,th-th,3637149024,2605428657,55a39c175b421d0c6725963bf522135ef58ac838,92488a66f198944850cc46bf5c9d14031e3a8130,d,d
::#,19043,vol,tr-tr,3632409366,2597318406,2896780089c51fd4925b5461f78e37260fb96f4e,32c59dc3791a14404d289612467f5600d3642ee1,c,d
::#,19043,vol,uk-ua,3633073140,2601657108,d3d06977ed2de7352489317563099c80093125cd,c5a6725fc7b6e5e58d680259ab827de6621f919f,d,d
::#,19043,vol,zh-cn,3885377254,2847833439,d6cc640b4cbc484e5d41cc966b3e105193c18ffd,dcdcfca5a388059e2db9cb55e950f29282bec529,d,c
::#,19043,vol,zh-tw,3856202777,2825194480,fac5d12d42d7aa7bbcad36b1314923a776e1a5c9,ae7a1a1d9212269227330c5298687887a1f5621d,d,d
