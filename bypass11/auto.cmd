@echo off& title Auto Upgrade - MCT ||  supports Ultimate / PosReady / Embedded / LTSC / Enterprise Eval
set "EDITION_SWITCH="
set "SKIP_11_SETUP_CHECKS=1"
set OPTIONS=/SelfHost /Auto Upgrade /MigChoice Upgrade /Compat IgnoreWarning /MigrateDrivers All /ResizeRecoveryPartition Disable
set OPTIONS=%OPTIONS% /ShowOOBE None /Telemetry Disable /CompactOS Disable /DynamicUpdate Enable /SkipSummary /Eula Accept

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
