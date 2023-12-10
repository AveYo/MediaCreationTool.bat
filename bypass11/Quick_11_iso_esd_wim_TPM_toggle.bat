@(echo off% <#%) &color 07 &title Quick 11 iso esd wim TPM toggle by AveYo - with SendTo menu entry
set "0=%~f0" &set "1=%~f1"&set "2=%~2"& powershell -nop -c iex ([io.file]::ReadAllText($env:0)) &pause &exit/b ||#>)[1]

#:: what's new in v1.2: add uninstall when run again without parameters (issue #96) 
$timer = $(get-date)

#:: Install to SendTo menu when run from another location
$SendTo = [Environment]::GetFolderPath('ApplicationData') + '\Microsoft\Windows\SendTo'
$Script = "$SendTo\Quick_11_iso_esd_wim_TPM_toggle.bat"
if (!$env:1 -and $env:0 -and !(test-path $Script)) { 
  write-host "`n No input iso / esd / wim file to patch! use 'Send to' context menu ...`n" -fore Yellow
  copy $env:0 $Script -force
}
elseif (!$env:1 -and $env:0 -and (test-path $Script)) {
  write-host "`n Removed 'Send to' entry - run again to install ...`n" -fore Magenta
  del $Script -force
}
if (!$env:1) { return }

#:: Can force either patch or undo via second commandline parameter: 1 to patch 0 to undo
if (1 -eq $env:2) {$toggle = 1} elseif (0 -eq $env:2) {$toggle = 0} else {$toggle = 2}

#:: Verify extension is .iso .esd or .wim
$input = get-item -lit $env:1; $invalid = '.iso','.esd','.wim' -notcontains $input.Extension
if ($invalid) {write-host "`n Input is not a iso / esd / wim file ...`n" -fore Yellow; return } 
try {[io.file]::OpenWrite($input).close()} catch {write-host "`n ERROR! $input read-only or in use ...`n" -fore Red; return }

#:: TPM patch via InstallationType Server
$typeC = '<INSTALLATIONTYPE>Client'; $typeS = '<INSTALLATIONTYPE>Server'
$block = 1048576; $chunk = 2097152; $count = [uint64]([IO.FileInfo]$input).Length / $chunk - 1
$bytes = new-object "Byte[]" ($chunk); $begin = [uint64]0; $final = [uint64]0; $limit = [uint64]0
function tochars {return [Text.Encoding]::GetEncoding(28591).GetString([Text.Encoding]::Unicode.GetBytes($args[0]))}
$find1 = tochars "</INSTALLATIONTYPE>"; $find2 = tochars "</WIM>"; $cli = tochars $typeC; $srv = tochars $typeS

$f = new-object IO.FileStream ($input, 3, 3, 1); $p = 0; $p = $f.Seek(0, 2)
write-host "$input`nsearching $p bytes, please wait ...`n"
for ($o = 1; $o -le $count; $o++) { 
  $p = $f.Seek(-$chunk, 1); $r = $f.Read($bytes, 0, $chunk); if ($r -ne $chunk) {write-host invalid block $r; break}
  $u = [Text.Encoding]::GetEncoding(28591).GetString($bytes); $t = $u.LastIndexOf($find1, [StringComparison]4) 
  if ($t -ge 0) {
    $f.Seek(($t -$chunk), 1) >''
    for ($o = 1; $o -le $chunk; $o++) { $f.Seek(-2, 1) >''; if ($f.ReadByte() -eq 0xfe) {$begin = $f.Position; break} }
    $limit = $f.Length - $begin; if ($limit -lt $chunk) {$x = $limit} else {$x = $chunk}
    $bytes = new-object "Byte[]" ($x); $r = $f.Read($bytes, 0, $x); 
    $u = [Text.Encoding]::GetEncoding(28591).GetString($bytes); $t = $u.IndexOf($find2, [StringComparison]4)
    if ($t -ge 0) {$f.Seek(($t + 12 -$x), 1) >''; $final = $f.Position} ; break
  } else { $p = $f.Seek(-$chunk, 1)} 
}

if ($begin -gt 0 -and $final -gt $begin) {
  $x = $final - $begin; $f.Seek(-$x, 1) >''; $bytes = new-object "Byte[]" ($x); $r = $f.Read($bytes, 0, $x)
  if ($r -ne $x) {break}
  $t =  [Text.Encoding]::GetEncoding(28591).GetString($bytes)
  if ($t.IndexOf($cli, [StringComparison]4) -ge 0) {$src = 0} else {$src = 1} 
  if ($src -eq 0 -and $toggle -ne 0) {$old = $cli; $new = $srv} elseif ($src -eq 1 -and $toggle -ne 1) {$old = $srv; $new = $cli}
  else {write-host "`n:) $input already has TPM patch $toggle"; $f.Dispose(); return}
  $t = $t.Replace($old, $new); $t; $b = [Text.Encoding]::GetEncoding(28591).GetBytes($t); $f.Seek(-$x, 1) >''; $f.Write($b, 0, $x)
  if ($src -eq 1) {write-host "`n :D TPM patch removed" -fore Green} else {write-host "`n:D TPM patch added" -fore Green} 
  $f.Dispose(); [GC]::Collect()
} else {write-host "`n;( TPM patch failed" -fore Red; $f.Dispose()}

#:: how quick was that??
$(get-date) - $script:timer
#:: done
