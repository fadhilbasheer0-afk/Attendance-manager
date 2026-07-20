$src = "c:\PROJECTS\attendance app\lib\screens\teacher\teacher_class_main_screen.dart"
$tmp = "c:\PROJECTS\attendance app\lib\screens\teacher\teacher_class_main_screen_temp.dart"
$lines = Get-Content $src -Encoding UTF8
$trimmed = $lines[0..2425]
$trimmed | Out-File $tmp -Encoding UTF8
Copy-Item $tmp $src -Force
Remove-Item $tmp
Write-Host "Done. Line count:" ($trimmed.Length)
