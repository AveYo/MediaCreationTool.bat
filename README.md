Not just an Universal MediaCreationTool wrapper script with ingenious support for business editions,  
<img src="preview.png">
A powerful yet simple windows 10 / 11 deployment automation tool as well!  

> configure via set vars, commandline parameters or rename script like `iso 21H2 Pro MediaCreationTool.bat`  
> recommended windows setup options with the least amount of issues on upgrades set via auto.cmd  
> awesome dialogs with keyboard focus to pick target version and preset action  

> **Auto Setup** with detected media without confirmation  
> _- can troubleshoot upgrade failing by adding `no_update` to script name_  
> **Create ISO** with detected media in `C:\ESD` folder without confirmation  
> _- can override detected media by adding edition name / language / arch to script name_  
> **Create USB** with detected media after confirmation  
> _- can click Back and select ISO instead to save in a different path_  
> custom presets above support 'oem' media customization, that can be disabled by adding `no_oem` to script name  
> _- pickup `$OEM$` folder (if it exists) with any post setup tweaks like `$OEM$\$$\Setup\Scripts\setupcomplete.cmd`_  
> _- write `sources\PID.txt` file to preselect edition at media boot or setup within windows (if configured)_  
> _- write `auto.cmd` file to re-run auto setup on demand, from media (includes Skip TPM if sources are 11)_  
> _- write `winpeshl.ini` file in boot.wim to Skip TPM Check on media boot (if sources are 11)_  
> **Select in MCT** with manual confirmation for everything in MCT GUI  
> _- no 'oem' media customization, script passes products.xml configuration and quits without touching media_  

> Skip TPM Check on Dynamic Update v1 _(wmi-based)_ or v2 _(ifeo-based)_ standalone toggle scripts in `MCT\` dir  
> _- system-wide, unblocks insider previews on windows update, or running setup.exe manually while online_  
> _- when using created media on another pc for the first time, can launch `auto.cmd` from media once to enable_  

_We did it! We broke gist.github.com_ ;) So this is the new home now. **Thank you all!**  

[discuss on MDL](https://forums.mydigitallife.net/forums/windows-10.54/)  

```
2018.10.10: reinstated 1809 [RS5]! using native xml patching for products.xml; fixed syntax bug with exit/b
2018.10.12: added data loss warning for RS5
2018.11.13: RS5 is officially back! + greatly improved choices dialog - feel free to use the small snippet in your own scripts
2019.05.22: 1903 [19H1]
2019.07.11: 1903 __release_svc_refresh__ and enable DynamicUpdate by default to grab latest CU
2019.09.29: UPDATED 19H1 build 18362.356 ; RS5 build 17763.379 and show build number
            added LATEST MCT choice to dinamically download the current version (all others have hard-coded links)
2019.11.16: 19H2 18363.418 as default choice (updated hard-coded links)
2020.02.29: 19H2 18363.592
2020.05.28: 2004 19041.264 first release
2020.10.29: 20H2 and aniversary script refactoring to support all MCT versions from 1507 to 20H2!!!
2020.10.30: hotfix utf-8, enterprise on 1909+
2020.11.01: fix remove unsupported options in older versions code breaking when path has spaces.. pff
2020.11.14: generate latest links for 1909,2004; all xml editing now in one go; resolved known cannot run script issues
2020.11.15: one-time clear of cached MCT, as script generates proper 1.0 catalog for 1507,1511,1703 since last update
            fixed compatibility with naked windows 7 powershell 2.0 / IPv6 / optional import $OEM$ / 1803+ business typo
            updated executables links for 1903 and 2004
2020.11.17: parse first commandline parameter as version, example: MediaCreationTool.bat 1909
2020.12.01: attempt to fix reported issues with 1703; no other changes (skipping 19042.630 leaked esd because it is broken)
2020.12.11: 20H2 19042.631; fixed pesky 1703 decryption bug on dual x86 + x64; improved cleanup; label includes version
2021.03.20: pre-release 21H1; optional auto upgrade or create media presets importing $OEM$ folder and key as PID.txt
2021.05.23: 21H1 release; enhanced script name args parsing, upgrade from embedded, auto.cmd / PID.txt / $OEM$ import
2021.06.06: create iso directly; enhanced dialogs; args from script name or commandline; refactoring is complete!
2021.08.04: done fiddling
2021.09.03: 21H2, both 10 and 11 [unreleased]
2021.09.25: Windows 11
            with Skip TPM Check on media boot as well as on dynamic update (standalone toggle script available)
            final touches for improved script reliability; enhanced auto upgrade preset; win 7 powershell 2.0 compatible
2021.09.30: fix Auto Setup preset not launching.. automatically
2021.10.04: fix for long standing tr localization quirks; Skip TPM Check v2 (ifeo-based instead of wmi)
2021.10.05: 11 22000.194 Release (rofl W11 MCT has limited capabilities, so still using 21H1 MCT because it works fine)
2021.10.09: outstanding refactoring around Windows 11 MCT; minimize while waiting MCT; unified 7 - 11 appearence
```

_use `download ZIP` button or pastebin link to get the script, as saving the Raw file breaks line endings_  
