Not just an Universal MediaCreationTool wrapper script with ingenious support for business editions,  
<img src="preview.png">
A powerful yet simple windows 10 / 11 deployment automation tool as well!  

Windows 11  
---------  
Script creates media that will **automatically skip upgrade or clean install checks**  
Sharpest bypass I came up with is using `/Product Server` option or `<INSTALLATIONTYPE>Server` on the install image,  
tho I understand that many of you dislike the _Installing Windows Server_ cosmetic artifact _(not purely cosmetic)_,  
so the methods used are my originals _Appraiser_Data.ini_ trick to upgrade plus _winsetup.dll_ patching in _boot.wim_.  

Check out the **bypass11 folder** for alternatives / standalone scripts [pending]  
[Quick_11_iso_esd_wim_TPM_toggle.bat](bypass11/Quick_11_iso_esd_wim_TPM_toggle.bat)  
usable with any downloaded windows 11 iso or extracted esd and wim  
right-click file - SendTo - select script to toggle bypass on or off (kickass feature: it restores iso to original hash)  
business / enterprise media is best since it comes with ei.cfg so setup won't ask for a key at start  
tho you can add a generic ei.cfg to the media\sources yourself:  
`[Channel]`  
`_Default`  

[Skip_TPM_Check_on_Dynamic_Update v4](bypass11/Skip_TPM_Check_on_Dynamic_Update_v4.cmd) and older v3, v2, v1  
will bypass windows 11 setup that was run manually under windows, or **via windows update**  
_bypass getting 11 after OfflineInsiderEnroll to Beta or Dev channels and doing an update check_  

Windows 10  
---------  
Script works just as well as before, not having to deal with microsoft's latest anti-consumer practices..  

Presets  
-------  
>1 **Auto Upgrade** with detected media, script assists setupprep for upgrading directly  
> _- can keep files and apps on more scenarios such as cross-edition setups_
> _- can troubleshoot upgrade failing by adding `no_update` to script name_  

>2 **Make ISO** with detected media in `Downloads` folder directly  
> _- can override detected media by adding edition name / language / arch to script name_  

>3 **Make USB** with detected media in specified usb target    
> _- can click Back and select ISO instead to save in a different path_  

>4 **Select** with picked Edition, Language, Arch - on specified target  
> _- implicit choice, will include setup override files_  

>5 **MCT Defaults** with GUI selected media, makes vanilla, default MCT iso/usb  
> _- no added files, script passes products.xml and quits without touching media_  

>1-4 presets will add any setup override files to created media  
> _- can be disabled by adding `def` to script name_  
> _- write `$OEM$` folder (if it exists) with post setup tweaks like `$OEM$\$$\Setup\Scripts\setupcomplete.cmd`_  
> _- write `sources\PID.txt` to preselect edition at media boot or setup within windows (if configured)_  
> _- write `auto.cmd` to re-run upgrade with cross-edition support from media on demand_  
> _- write `AutoUnattend.xml` in boot.wim to enable local account on Windows 11 Home_  
> _- patch `winsetup.dll` in boot.wim to remove windows 11 setup cock-blocks when booting from media_    

> configure via set vars, commandline parameters or rename script like `iso 21H2 Pro MediaCreationTool.bat`  
> recommended windows setup options with the least amount of issues on upgrades set via auto.cmd  
> awesome dialogs with keyboard focus to pick target version and preset action  

_No need to right-click Run as Admin, script will ask itself. Saving the Raw file no longer breaks line endings_  
_We did it! We broke [the previous gist](https://git.io/MediaCreationTool.bat)_ ;) So this is the new home. **Thank you all!**  

[discuss on MDL](https://forums.mydigitallife.net/forums/windows-10.54/)  

```
2018.10.10: reinstated 1809 [RS5]! using native xml patching for products.xml; fixed syntax bug with exit/b
2018.10.12: added data loss warning for RS5
2018.11.13: RS5 is officially back! + greatly improved choices dialog - feel free to use the small snippet in your own scripts
2019.05.22: 1903 [19H1]
2019.07.11: 1903 __release_svc_refresh__ and enable DynamicUpdate by default to grab latest CU
2019.09.29: UPDATED 19H1 build 18362.356 ; RS5 build 17763.379 and show build number
            added LATEST MCT choice to dynamically download the current version (all others have hard-coded links)
2019.11.16: 19H2 18363.418 as default choice (updated hard-coded links)
2020.02.29: 19H2 18363.592
2020.05.28: 2004 19041.264 first release
2020.10.29: 20H2 and anniversary script refactoring to support all MCT versions from 1507 to 20H2!!!
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
2021.10.09: outstanding refactoring around Windows 11 MCT; minimize while waiting MCT; unified 7 - 11 appearance
2021.10.20: create generic iso if no edition arg; use Downloads folder; no 11 setup checks on boot in VirtualBox; fixes #2
2021.10.23: 11 22000.258
            more intuitive presets; 11 setup override via AutoUnattend.xml or via boot.wim (for VirtualBox 5.x) with FIX arg
            only reliable ui automation; enhanced script output
2021.11.03: multiple download methods; improved automation; improved auto.cmd; moved autounattend.xml to boot.wim
            revising 11 setup bypass (wip) - not being content with any methods is the reason why I've not updated in a while             
2021.11.09: skip windows 11 upgrade checks with setup.exe (not just auto.cmd); no server label; local account on 11 home           
            auto.cmd has more fixes to keep files and apps on upgrade; reliable ui automation; alternative downloaders 
```
