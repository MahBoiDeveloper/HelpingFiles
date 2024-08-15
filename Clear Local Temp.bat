@echo off
chcp 65001 > nul

echo Удаление мусора в %temp% ...
for /f "tokens=*" %%f in ('dir %temp% /a:a /s /b')  do del /f /q "%%f" > nul 2> nul
echo Готово
echo.

pause
