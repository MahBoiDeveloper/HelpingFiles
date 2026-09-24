: File Encoding: UTF-8
: Author:        mah_boi
: License:       GNU GPL v3
: Description:   Script for edit "Default" key in registry in folder "ergc" for game of C&C Series

: Полезные сайты, которые были использованы при создании батника:
:   Запись строк в переменные: https://fooobar.com/questions/1131716/read-lines-with-blank-spaces-from-a-file-using-batch
:   Редактирование строк: https://celitel.info/klad/nhelp/helpbat.php?dcmd=ex_string
:   Редактирование реестра: https://miradmin.ru/registry-cmd/

: Cкрипт по редактированию ключа реестра "(По умолчанию)" в папке "ergc" для игр серии C&C
: Основные операции в скрипте основаны на поведении пираток и сборок игр для Steam.
: Рекомендации:
:   1. Запускайте скрипт с правами администратора, иначе доступ к реестру 
:      получен не будет, а скрипт завершится с ошибкой.
:      По умолчанию на Windows 7 и старше скрипт будет запускаться без нареканий.
:   2. Запустите хотя бы 1 раз игру перед тем как запускать скрипт,
:      чтобы прописались все ключи и папки в реестре.
:   3. Если у Вас портативная сборка игры, то создайте дополнительно папки в реестре
:      (предполагается, что портативками пользуются только прошаренные пользователи винды):
:        - ПутьПоРеестру\Electronic Arts\Electronic Arts\TW-KW-RA3\ergc.
:        - ПутьПоРеестру\Electronic Arts\EA Games\ZH-GENERALS\ergc.
:      где ПутьПоРеестру - это HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ для 64-битных версий Windows,
:                          или HKEY_LOCAL_MACHINE\SOFTWARE\             для 32-битных версий Windows.
:          TW-KW-RA3 - это Command and Conquer 3 Kanes Wrath, или Command and Conquer 3, или Red Alert 3
:          ZH-GENERALS - это Command and Conquer Generals Zero Hour, или Generals

@echo off
chcp 65001 > nul

set ergc_key=KEKW%date:~0,2%%date:~3,2%%date:~6,4%%time:~0,2%%time:~3,2%%time:~6,2%%time:~9,2%
set reg_path=""

: Команда пишет в errorlevel код ошибки. Если 1 - нет админских прав, 0 - права есть
whoami /priv | find /i "SeChangeNotifyPrivilege                   Bypass traverse checking                                           Enabled" > nul 2> nul
if %errorlevel%==1 (
    : Вызвать этот же скрипт от имени админа
    powershell "start %0 -verb runas"
    exit /b
)

: Команда пишет в errorlevel код ошибки. Если 1 - винда 32-битная, 0 - винда 64-битная
systeminfo | find "x64-based PC" > nul
if %errorlevel%==0 (
    set reg_path=HKLM\SOFTWARE\WOW6432Node\Electronic Arts
) else (
    set reg_path=HKLM\SOFTWARE\Electronic Arts
)

echo Set a new key %ergc_key% in the %reg_path%...
echo.

echo Set a new key for ZH...
reg add "%reg_path%\EA Games\Command and Conquer Generals Zero Hour\ergc"   /ve /t REG_SZ /d "%ergc_key%" /f
echo.

echo Set a new key for Generals...
reg add "%reg_path%\EA Games\Generals\ergc"                                 /ve /t REG_SZ /d "%ergc_key%" /f
echo.

echo Set a new key for TW...
reg add "%reg_path%\Electronic Arts\Command and Conquer 3\ergc"             /ve /t REG_SZ /d "%ergc_key%" /f
echo.

echo Set a new key for KW...
reg add "%reg_path%\Electronic Arts\Command and Conquer 3 Kanes Wrath\ergc" /ve /t REG_SZ /d "%ergc_key%" /f
echo.

echo Set a new key for RA3...
reg add "%reg_path%\Electronic Arts\Red Alert 3\ergc"                       /ve /t REG_SZ /d "%ergc_key%" /f
echo.

:exit
pause

:eof
