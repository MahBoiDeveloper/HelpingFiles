# Начало мега убер бибер могучего-ебучего скрипта по установке всего, чего надо, после переустановки винды

Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Repair-WinGetPackageManager -Force -Latest
