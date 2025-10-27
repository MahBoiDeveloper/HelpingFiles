@echo off
for /f "tokens=*" %%f in ('dir C:\*.log /a:a /s /b') do del /f /q %%f
for /f "tokens=*" %%f in ('dir C:\*.tmp /a:a /s /b') do del /f /q %%f
for /f "tokens=*" %%f in ('dir C:\*.temp /a:a /s /b') do del /f /q %%f
for /f "tokens=*" %%f in ('dir C:\*.dmp /a:a /s /b') do del /f /q %%f
for /f "tokens=*" %%f in ('dir C:\*.dump /a:a /s /b') do del /f /q %%f
pause
