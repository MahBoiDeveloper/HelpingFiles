@echo off
chcp 65001 > nul

for /f "tokens=*" %%f in ('dir /a:d /b source') do (
	rmdir /s /q "target\%%f"
	)

echo Конец батника
timeout /t 30 > nul
