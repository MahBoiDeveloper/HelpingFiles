: Encoding:    UTF-8
: Author:      mah_boi
: License:     GNU GPL v3
: Name:        C&C ergc registry key fix by mah_boi
: Description: Script for edit "Default" key in registry in folder "ergc" for game of C&C series
: Version:     1.0

@echo off
cd /d %~dp0
setlocal enabledelayedexpansion

: Evaluate rights to the admin
    net session >nul 2>&1
    if not %errorlevel%==0 (
        powershell "start %0 -verb runas"
        exit /b
    )

: Variables and constans
    : General for bat type
    set ps=powershell
    set psc=%ps% -nop -c
    set "COLOR.GREEN=42;97m"
    set "COLOR.RED=41;97m"
    set opcode=

    : General for this specific bat
    set log_file=CNCErgcFix.log
    set dir_name=CNCErgcFix
    set option_ad=%appdata%\%dir_name%
    set option_lad=%localappdata%\%dir_name%
    set option_sd=%systemdrive%\%dir_name%
    set win64regpath=HKLM\SOFTWARE\WOW6432Node\Electronic Arts
    set win32regpath=HKLM\SOFTWARE\Electronic Arts
    set ergc_key=KEKW%date:~0,2%%date:~3,2%%date:~6,4%%time:~0,2%%time:~3,2%%time:~6,2%%time:~9,2%
    set install_dir=%option_ad%
    set reg_branch=

    : Check win version
    systeminfo | find "x64-based PC" > nul
    if %errorlevel%==0 (
        set reg_branch=%win64regpath%
    ) else (
        set reg_branch=%win32regpath%
    )

    : Game registry branches
    set "G=%reg_branch%\EA Games\Generals\ergc"
    set "ZH=%reg_branch%\EA Games\Command and Conquer Generals Zero Hour\ergc"
    set "TW=%reg_branch%\Electronic Arts\Command and Conquer 3\ergc"
    set "KW=%reg_branch%\Electronic Arts\Command and Conquer 3 Kanes Wrath\ergc"
    set "RA3=%reg_branch%\Electronic Arts\Red Alert 3\ergc"

: Menu procedures
    :cycle
        call :menu
        if %opcode%==1 call :write "%COLOR.RED%" "WIP" & pause & goto :cycle
        if %opcode%==2 call :write "%COLOR.RED%" "WIP" & pause & goto :cycle
        if %opcode%==3 call :status     & goto :cycle
        if %opcode%==4 call :legacy_fix & goto :cycle
        if %opcode%==5 call :write "%COLOR.RED%" "WIP" & pause & goto :cycle
        if %opcode%==6 call :select_dir & goto :cycle
        if %opcode%==7 call :write "%COLOR.RED%" "WIP" & pause & goto :cycle
        if %opcode%==8 call :write "%COLOR.RED%" "WIP" & pause & goto :cycle
        if %opcode%==9 call :write "%COLOR.RED%" "WIP" & pause & goto :cycle
    goto :exit

    : Batch file main menu
    :menu
        cls
        title CNC ergc Key Fix
        mode 76, 30
        echo: 
        echo: 
        echo: 
        call :write "%COLOR.RED%"   "           WARNING: THIS SCRIPT EDITS YOUR TASK SCHEDULER SETTINGS          "
        : dcall :write "%COLOR.RED%"   "               THIS PROGRAM COMES WITH ABSOLUTELY NO WARRANTY               "
        echo:       ______________________________________________________________
        echo: 
        echo:                                   ACTIONS 
        echo: 
        echo:             [1] Install fix
        echo:             [2] Remove fix
        echo:             [3] Check fix status
        echo:             [4] Run legacy one-time fix
        echo:             [5] WIP
        echo:             __________________________________________________
        echo:             
        echo:             [6] Change install directory
        echo:             [7] WIP
        echo:             [8] WIP
        echo:             [9] WIP
        echo: 
        echo:             [0] Exit
        echo:       ______________________________________________________________
        echo: 
        echo:             Install dir: %install_dir%
        echo: 
        call :write "%COLOR.GREEN%" "                  Enter key from set [0,1,2,3,4,5,6,7,8,9]                  "
        choice /C:1234567890 /N
        set opcode=%errorlevel%
        if %opcode%==0 (
            exit
        )
        cls
    exit /b

: Main procedures
    :legacy_fix
        call :write "%COLOR.GREEN%" "The new key is %ergc_key%"
        call :log "Set a new key for Generals..."
        reg add "%reg_branch%\EA Games\Generals\ergc"                                 /ve /t REG_SZ /d "%ergc_key%" /f
        call :log "Set a new key for GeneralsZH..."
        reg add "%reg_branch%\EA Games\Command and Conquer Generals Zero Hour\ergc"   /ve /t REG_SZ /d "%ergc_key%" /f
        call :log "Set a new key for TW..."
        reg add "%reg_branch%\Electronic Arts\Command and Conquer 3\ergc"             /ve /t REG_SZ /d "%ergc_key%" /f
        call :log "Set a new key for KW..."
        reg add "%reg_branch%\Electronic Arts\Command and Conquer 3 Kanes Wrath\ergc" /ve /t REG_SZ /d "%ergc_key%" /f
        call :log "Set a new key for RA3..."
        reg add "%reg_branch%\Electronic Arts\Red Alert 3\ergc"                       /ve /t REG_SZ /d "%ergc_key%" /f
        call :write "%COLOR.GREEN%" "Done"
        if not "%~1"=="1" pause
    exit /b

    :status
        call :write "%COLOR.GREEN%" "Done"
        %psc% "$text = [IO.File]::ReadAllText('%~f0'); $code = ($text -split '(?m)^:__PS_SCRIPT__\r?\n', 2)[1]; & ([scriptblock]::Create($code))"
        if not "%~1"=="1" pause
    exit /b

    :select_dir
        echo: 
        echo: 
        echo: 
        echo: 
        echo: 
        echo:       ______________________________________________________________
        echo: 
        echo:                              SELECT DIRECTORY 
        echo: 
        echo:             [1] %option_ad%
        echo:             [2] %option_lad%
        echo:             [3] %option_sd%
        echo:             __________________________________________________
        echo: 
        echo:             [0] Exit
        echo:       ______________________________________________________________
        echo: 
        echo:             Current dir: %install_dir%
        echo: 
        call :write "%COLOR.GREEN%" "                        Enter key from set [0,1,2,3]                        "
        choice /C:1230 /N
        set opcode=%errorlevel%
        if %opcode%==1 ( set "install_dir=%option_ad%"  )
        if %opcode%==2 ( set "install_dir=%option_lad%" )
        if %opcode%==3 ( set "install_dir=%option_sd%"  )
        if %opcode%==0 (
            exit /b
        )
    exit /b

: Other procedures
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
goto :eof

: powershell file content
:__PS_SCRIPT__
Write-Host "Hello World"
