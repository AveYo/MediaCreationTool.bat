Get 11 on 'unsupported' PC via Windows Update or mounted ISO (no patching needed)  
---------------------------------------------------------------------------------  
Step 1: use [Skip_TPM_Check_on_Dynamic_Update.cmd](Skip_TPM_Check_on_Dynamic_Update.cmd) to automatically bypass setup requirements  
_It's a set it and forget it script, with built-in undo - v7 using more reliable /Product Server trick_  
_V9 rebased on cmd due to defender transgression; skips already patched media (0b)_  

Step 2: use [OfflineInsiderEnroll](https://github.com/abbodi1406/offlineinsiderenroll) to subscribe to the channel you want  
_while on 10, use BETA for Windows 11 22000.x builds (release), DEV for Windows 11 225xx.x builds (experimental)_  

Step 3: check for updates via Settings - Windows Update and select Upgrade to Windows 11  

Get 11 on 'unsupported' PC via MediaCreationTool.bat  
----------------------------------------------------  
[MediaCreationTool.bat](../MediaCreationTool.bat) creates 11 media that will **automatically skip clean install checks**  
***Auto Upgrade*** preset, or launching `auto.cmd` from the created media will **automatically skip upgrade checks**  
Running `setup.exe` from the created media is not guaranteed to bypass setup checks (it should for now)  
To NOT add bypass to the media, use ***MCT Defaults*** preset or rename the script as `def MediaCreationTool.bat`  

> Regarding the bypass method, for a more reliable and future-proof experience,  
> clean installation is still handled via _winsetup.dll_ patching in _boot.wim_  
> upgrade is now handled ~~only~~ via `auto.cmd` with the */Product Server* trick  
> *Just ignore the 'Windows Server' label, please!*  
> NEWS: temporarily added back my old-style 0-byte bypass as it still works on release  

i: [Skip_TPM_Check_on_Dynamic_Update.cmd](Skip_TPM_Check_on_Dynamic_Update.cmd) acts globally and **skips setup.exe upgrade checks as well**  
_regardless of mounted iso / usb media already having a bypass added or not_  

Already have a 11 ISO, USB or extracted Files and want to add a bypass  
----------------------------------------------------------------------  
Use [Quick_11_iso_esd_wim_TPM_toggle.bat](Quick_11_iso_esd_wim_TPM_toggle.bat) from the confort of right-click - SendTo menu  

Switches installation type to Server skipping install checks, or back to Client if run again on the same file, restoring hash!  
**directly** on any downloaded windows 11 iso or extracted esd and wim, so there's no iso / dism mounting  
_defiantly quick_  

Works great with business / enterprise media since it comes with ei.cfg so setup won't ask for product key at start  
for consumer / core media you can add a generic `EI.cfg` to the media\sources yourself with this content:  
`[Channel]`  
`_Default`  

> if setup still asks for product key, input retail or gvlk keys found in media\sources\product.ini  
> _gvlkprofessional=W269N-WFGWX-YVC9B-4J6C9-T83GX gvlkcore=TX9XD-98N7V-6WMQ6-BX7FG-H8Q99_  
> _gvlkenterprise=NPPR9-FWDCX-D2C8J-H872K-2YT43 gvlkeducation=NW6C2-QMPVW-D7KKK-3GKT6-VCFB2 etc._  

i: [Skip_TPM_Check_on_Dynamic_Update.cmd](Skip_TPM_Check_on_Dynamic_Update.cmd) acts globally and **skips setup.exe upgrade checks as well**  
_regardless of mounted iso / usb media already having a bypass added or not_  

Offline local account on 11 Home / Pro  
--------------------------------------  
[MediaCreationTool.bat](../MediaCreationTool.bat) creates media that re-enables the *I dont have internet* OOBE choice (OOBE\BypassNRO)  
It does so via [AutoUnattend.xml](AutoUnattend.xml), inserted into `boot.wim` to not cause setup.exe issues under windows  
More conveniently can be placed at the root of 11 media, along with [auto.cmd](auto.cmd) to use for upgrades  
Should work with any 11 Release (22000.x) or Dev (22xxx.x) media - and it hides unsupported PC nags as a bonus ;)  
_If you have already connected at OOBE, can try email: `a` password: `a` to switch to local account_  

Manage and troubleshoot Windows Update on any windows version and edition  
-------------------------------------------------------------------------  
Use [windows_update_refresh.bat](https://pastebin.com/XQsgjt9p) to clear pending updates (including sneaky feature upgrades)  
Use [windows_drivers_update_toggle.bat](https://pastebin.com/cK8y4YEX) to block driver updates even on Home editions  
Use [windows_feature_update_toggle.bat](https://pastebin.com/EcLB14hg) to block feature upgrades on 1507 - 21H2 even on Home editions!  
