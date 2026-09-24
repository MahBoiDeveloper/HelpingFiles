: Builder for YR Mod Builder by mah_boi
:   Version: 1.1

@echo off
cd /d %~dp0
setlocal enabledelayedexpansion

: General
set ps=powershell
set psc=%ps% -nop -c
set "COLOR.GREEN=42;97m"
set "COLOR.RED=41;97m"
set username=
set ip=
set port=
set scp_dst=
set opcode=

: Directories
set build=build
set client=client-assets
set mixes=mod-assets
set tools=tools
set vwcf=%build%\VersionWriter-CopiedFiles

: Tools
set vw=VersionWriter.exe
set ar=ccmix.exe
set zip=%tools%\%ar%

: Configs
set pup=preupdateexec
set up=updateexec
set vwc=versionconfig.ini

if "%~1"=="/build"  goto :command_build
if "%~1"=="--build" goto :command_build

:cycle
    call :menu

    if %opcode%==1 call :build_mixes        & goto :cycle
    if %opcode%==2 call :copy_client        & goto :cycle
    if %opcode%==3 call :version_writer     & goto :cycle
    if %opcode%==4 call :deploy             & goto :cycle
    if %opcode%==5 call :all                & goto :cycle
    if %opcode%==6 call :build_specific_mix & goto :cycle
    if %opcode%==7 call :exterminate_build  & goto :cycle
    if %opcode%==8 call :write "%COLOR.RED%" "WIP" & pause & goto :cycle

goto :exit

: Batch file main menu
:menu
    cls
    title Reboot Script Wizard
    mode 76, 30
    echo: 
    echo: 
    echo: 
    echo: 
    echo:       ______________________________________________________________
    echo: 
    echo:                                   ACTIONS 
    echo: 
    echo:             [1] Compile and copy mixes
    echo:             [2] Copy client files
    echo:             [3] Write new version
    echo:             [4] Deploy release to LAN server
    echo:             [5] Make all from the scratch
    echo:             __________________________________________________
    echo:             
    echo:             [6] Build specific mix
    echo:             [7] Remove build folder
    :: echo:             [8] 
    echo:             [0] Exit
    echo:       ______________________________________________________________
    echo: 
    call :write "%COLOR.GREEN%" "                  Enter key from set [0,1,2,3,4,5,6,7,8,9]                  "
    choice /C:1234567890 /N

    set opcode=%errorlevel%
    if %opcode%==0 (
        exit
    )
    cls
exit /b

:build_specific_mix
    echo:       ______________________________________________________________
    echo: 
    echo:                                MIX BUILDER
    echo: 
    echo:                       [0] EXPANDMD90 -- Voxels
    echo:                       [1] EXPANDMD91 -- Alpha Images
    echo:                       [2] EXPANDMD92 -- Sprite
    echo:                       [3] EXPANDMD93 -- UI
    echo:                       [4] EXPANDMD94 -- Cameo
    echo:                       [5] EXPANDMD95 -- Sounds [X]
    echo:                       [6] EXPANDMD96 -- EVA
    echo:                       [7] EXPANDMD97 -- Pallets
    echo:                       [8] EXPANDMD98 -- OST [X]
    echo:                       [9] EXPANDMD99 -- INI
    echo: 
    echo:       ______________________________________________________________
    echo: 

    call :write "%COLOR.GREEN%" "                  Enter key from set [0,1,2,3,4,5,6,7,8,9]                  "
    choice /C:1234567890 /N
    cls

    set NI=%errorlevel%
    if %NI%==10 ( set "NI=0" )

    set "SOURCE=%mixes%\expandmd9%NI%"
    set "OUTPUT=%build%\expandmd9%NI%.mix"

    if not exist "%SOURCE%" (
        call :log "ERROR: %SOURCE% not found!"
        pause
        exit /b
    )

    if not exist "%build%" mkdir "%build%"

    call :log "Compiling expandmd9%NI%..."

    %zip% --create --lmd --game=ra2 --dir "%SOURCE%" --mix "%OUTPUT%"

    call :write "%COLOR.GREEN%" "Done: %OUTPUT%"
    if not "%~1"=="1" pause
exit /b

:exterminate_build
    call :log "Removing %build% folder..."
    rmdir /s /q build\
    call :write "%COLOR.GREEN%" "Done"
    if not "%~1"=="1" pause
exit /b

:build_mixes
    mkdir %build% > nul 2> nul

    call :log "Copy pre-compiled assets..."
    for /f "tokens=*" %%f in ('dir "%mixes%\" /a:a /b') do (
        copy "%mixes%\%%f" "%build%\%%f"
        )
    echo.

    : Run compilation
    for /f "tokens=*" %%f in ('dir "%mixes%\" /a:d /b') do (
        call :log "Compiling %%f.mix..."
        start /min "" %zip% --create --lmd --game=ra2 --dir "%mixes%\%%f" --mix "%build%\%%f.mix"
        )

    : Wait for end
    :repeat
    for /f %%N in ('tasklist /FI "IMAGENAME eq %ar%" /FO CSV /NH ^| find /I /C "%ar%"') do (
        timeout /t 1 > nul
        set "count=%%N"
        )

    if %count% GTR 0 (
        goto :repeat
    )

    call :write "%COLOR.GREEN%" "Done"
    if not "%~1"=="1" pause
exit /b

:copy_client
    mkdir %build% >nul 2> nul
    call :log "Copy client files..."
    %psc% "cp -r -fo '%client%\*' '%build%\'"
    call :write "%COLOR.GREEN%" "Done"
    if not "%~1"=="1" pause
exit /b

:version_writer
    : Copy version writer
    call :log "Copy and patch version writer files..."
    copy %tools%\%vw% %build%\%vw%
    copy %tools%\%vwc% %build%\%vwc%
    for /f "delims=" %%H in ('%psc% "(git rev-parse --short HEAD).Trim()"') do set "GIT_HASH=%%H"
    %psc% "(Get-Content %build%\%vwc% -Raw) -replace '\d+\.\d+(?:\.\d+)?',('$0-'+(git rev-parse --short HEAD).Trim()) | Set-Content %build%\%vwc%"

    : Download music
    cd %build%
    call :log "Download zero-release mixes..."
    : gh release download v0.0 --repo DmitryVolkov666/Reboot_Test --pattern "*.mix"

    : Build version
    call :log "Write version..."
    %vw% -SUPRESSINPUTS
    cd ..

    : Copy configs
    call :log "Copy *updateexec configs..."
    copy %tools%\%pup% %vwcf%\%pup%
    copy %tools%\%up%  %vwcf%\%up%
    call :write "%COLOR.GREEN%" "Done"
    if not "%~1"=="1" pause
exit /b

:build_all
    echo build_all
    call :write "%COLOR.GREEN%" "Done"
    pause
exit /b

:deploy
    call :write "%COLOR.RED%" "WARNING: LAN UPLOADING MAY TAKE A LOT OF TIME. PRESS ENTER TO BEGIN UPLOAD."
    pause
    scp -P %port% -r %vwcf%\* %username%@%ip%:%scp_dst%
    pause
    call :write "%COLOR.GREEN%" "Done"
    if not "%~1"=="1" pause
exit /b

:all
    call :exterminate_build
    call :build_mixes
    call :copy_client
    call :version_writer
    call :deploy
exit /b

: Analyze args
:command_build
    call :build_mixes 1
    call :copy_client 1
goto :exit

: Log message to console with timestamp
:log
    echo [%date% -- %time:~0,-3%] %~1
exit /b

: Print color text (CMD)
: https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
:write
    echo [%~1%~2[0m
exit /b

: Print color text (Powershell)
:pswrite
    %ps% Write-Host %~3 -back %~1 -fore %~2
exit /b

:exit
