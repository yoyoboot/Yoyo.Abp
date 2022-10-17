$prefix = 'dotnet nuget push '
$suffix = ' --source "l52abp-packs-admin"'

Get-ChildItem .\*.nupkg | Select-Object { $prefix + $_.Name + $suffix }  | Out-File -width 1000 .\push.bat -Force

(Get-Content .\push.bat | Select-Object -Skip 3) | Set-Content .\push.bat




