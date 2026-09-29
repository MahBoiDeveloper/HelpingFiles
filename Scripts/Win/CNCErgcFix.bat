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
    set ps=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe
    set psc=%ps% -nop -c
    set psf=%ps% -NoProfile -ExecutionPolicy Bypass -File
    set "COLOR.GREEN=42;97m"
    set "COLOR.RED=41;97m"
    set opcode=

    : General for this specific bat
    set log_file=CNCErgcFix.log
    set ps_file=CNCErgcFix.ps1
    set dir_name=CNCErgcFix
    set task_name=%dir_name%
    set option_ad=%appdata%\%dir_name%
    set option_lad=%localappdata%\%dir_name%
    set option_sd=%systemdrive%\%dir_name%
    set win64regpath=HKLM\SOFTWARE\WOW6432Node\Electronic Arts
    set win32regpath=HKLM\SOFTWARE\Electronic Arts
    set ergc_key=KEKW%date:~0,2%%date:~3,2%%date:~6,4%%time:~0,2%%time:~3,2%%time:~6,2%%time:~9,2%
    set install_dir=%option_sd%
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
        if %opcode%==1 call :install_fix & goto :cycle
        if %opcode%==2 call :remove_fix  & goto :cycle
        if %opcode%==3 call :status      & goto :cycle
        if %opcode%==4 call :legacy_fix  & goto :cycle
        if %opcode%==5 call :write "%COLOR.RED%" "WIP" & pause & goto :cycle
        if %opcode%==6 call :select_dir  & goto :cycle
        if %opcode%==7 call :manual_key  & goto :cycle
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
        : call :write "%COLOR.RED%"   "               THIS PROGRAM COMES WITH ABSOLUTELY NO WARRANTY               "
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
        echo:             [7] Change new ergc key
        echo:             [8] WIP
        echo:             [9] WIP
        echo: 
        echo:             [0] Exit
        echo:       ______________________________________________________________
        echo: 
        echo:             New key: %ergc_key%
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
    :install_fix
        call :log "Install script to the %install_dir% folder..."
        mkdir "%install_dir%" > nul 2> nul
        (
            echo $LogFile = '%install_dir%\%log_file%'

            echo $ErgcPaths = @^( "%G%", "%ZH%", "%TW%", "%KW%", "%RA3%" ^)

            echo function Write-Log
            echo {
            echo     param^([string]$Message^)
            echo     $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            echo     Add-Content -LiteralPath $LogFile -Value "[$Timestamp] $Message" -Encoding UTF8
            echo }

            echo function New-ErgcKey { return 'KEKW' + ^(Get-Date -Format 'ddMMyyyyHHmmssff'^) }

            echo function Repair-Ergc
            echo {
            echo     try
            echo     {
            echo         $BadKeys = @^(^)
            echo         foreach ^($SubKeyPath in $ErgcPaths^) {
            echo             $Key = $null
            echo             try
            echo             {
            echo                 $Key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^(
            echo                     $SubKeyPath,
            echo                     $false
            echo                 ^)
            echo                 if ^($null -eq $Key^)
            echo                 {
            echo                     continue
            echo                 }
            echo                 # If empty then value is "(Default)"
            echo                 $Value = $Key.GetValue^(
            echo                     '',
            echo                     $null,
            echo                     [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            echo                 ^)
            echo                 if ^($Value -is [string] -and $Value -ceq '%%CDKEY%%'^)
            echo                 {
            echo                     $BadKeys += $SubKeyPath
            echo                 }
            echo             }
            echo             finally
            echo             {
            echo                 if ^($null -ne $Key^)
            echo                 {
            echo                     $Key.Dispose^(^)
            echo                 }
            echo             }
            echo         }
            echo         if ^($BadKeys.Count -eq 0^)
            echo         {
            echo             return
            echo         }
            echo         $NewValue = New-ErgcKey
            echo         foreach ^($SubKeyPath in $BadKeys^)
            echo         {
            echo             $Key = $null
            echo             try
            echo             {
            echo                 $Key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($SubKeyPath, $true^)
            echo                 if ^($null -eq $Key^)
            echo                 {
            echo                     continue
            echo                 }
            echo                 # Check value before write
            echo                 $CurrentValue = $Key.GetValue^('', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)
            echo                 if ^($CurrentValue -is [string] -and $CurrentValue -ceq '%%CDKEY%%'^)
            echo                 {
            echo                         $Key.SetValue^('', $NewValue, [Microsoft.Win32.RegistryValueKind]::String^)
            echo                     Write-Log "Fixed: HKLM\$SubKeyPath -> $NewValue"
            echo                 }
            echo             }
            echo             finally
            echo             {
            echo                 if ^($null -ne $Key^)
            echo                 {
            echo                     $Key.Dispose^(^)
            echo                 }
            echo             }
            echo         }
            echo     }
            echo     catch
            echo     {
            echo         Write-Log "ERROR: $($_.Exception.Message)"
            echo     }
            echo }

            echo $Query = @"
            echo SELECT *
            echo FROM RegistryTreeChangeEvent
            echo WHERE Hive = 'HKEY_LOCAL_MACHINE'
            echo AND RootPath = '$WmiRootPath'
            echo "@

            echo Write-Log "CNCErgcFix watcher started."
            echo Write-Log "Rewrite ergc on the start."
            echo Repair-Ergc
            echo try
            echo {
            echo     Register-WmiEvent -Namespace 'root\default' -Query $Query -SourceIdentifier 'CNCErgcFix.RegistryChange' ^| Out-Null
            echo     while ^($true^)
            echo     {
            echo         $Event = Wait-Event -SourceIdentifier 'CNCErgcFix.RegistryChange'
            echo         if ^($null -ne $Event^)
            echo         {
            echo             Remove-Event -EventIdentifier $Event.EventIdentifier -ErrorAction SilentlyContinue
            echo         }
            echo         # Timeout to wait the game finish write
            echo         Start-Sleep -Milliseconds 50
            echo         Repair-Ergc
            echo     }
            echo }
            echo catch
            echo {
            echo     Write-Log "WMI WATCHER ERROR: $($_.Exception.Message)"
            echo     exit 1
            echo }
            echo finally
            echo {
            echo     Unregister-Event -SourceIdentifier 'CNCErgcFix.RegistryChange' -ErrorAction SilentlyContinue
            echo }

        ) > "%install_dir%\%ps_file%"
        
        call :write "%COLOR.GREEN%" "Done"
        if not "%~1"=="1" pause
    exit /b

    :remove_fix
        rmdir /s /q "%option_ad%" > nul 2> nul
        rmdir /s /q "%option_lad%" > nul 2> nul
        rmdir /s /q "%option_sd%" > nul 2> nul
        rmdir /s /q "%install_dir%" > nul 2> nul
        call :write "%COLOR.GREEN%" "Done"
        if not "%~1"=="1" pause
    exit /b

    :legacy_fix
        call :write "%COLOR.GREEN%" "The new key is %ergc_key%"
        echo.

        call :log "Set a new key for Generals..."
        reg add "%G%" /ve /t REG_SZ /d "%ergc_key%" /f
        call :log "Set a new key for GeneralsZH..."
        reg add "%ZH%" /ve /t REG_SZ /d "%ergc_key%" /f
        call :log "Set a new key for TW..."
        reg add "%TW%" /ve /t REG_SZ /d "%ergc_key%" /f
        call :log "Set a new key for KW..."
        reg add "%KW%" /ve /t REG_SZ /d "%ergc_key%" /f
        call :log "Set a new key for RA3..."
        reg add "%RA3%" /ve /t REG_SZ /d "%ergc_key%" /f
        
        echo.
        call :write "%COLOR.GREEN%" "Done"
        if not "%~1"=="1" pause
    exit /b

    :status
        reg query "%G%"   /ve 2>nul | findstr /c:"REG_SZ" | %psc% "$v = $input -replace '^.*?REG_SZ\s*',''; $b = $v -and $v -ne '%%CDKEY%%'; $bg = if ($b) { 'Green' } else { 'DarkRed' }; Write-Host ('Generals:      ') -n; Write-Host $v -back $bg -fore White"
        reg query "%ZH%"  /ve 2>nul | findstr /c:"REG_SZ" | %psc% "$v = $input -replace '^.*?REG_SZ\s*',''; $b = $v -and $v -ne '%%CDKEY%%'; $bg = if ($b) { 'Green' } else { 'DarkRed' }; Write-Host ('Zero Hour:     ') -n; Write-Host $v -back $bg -fore White"
        reg query "%TW%"  /ve 2>nul | findstr /c:"REG_SZ" | %psc% "$v = $input -replace '^.*?REG_SZ\s*',''; $b = $v -and $v -ne '%%CDKEY%%'; $bg = if ($b) { 'Green' } else { 'DarkRed' }; Write-Host ('Tiberium Wars: ') -n; Write-Host $v -back $bg -fore White"
        reg query "%KW%"  /ve 2>nul | findstr /c:"REG_SZ" | %psc% "$v = $input -replace '^.*?REG_SZ\s*',''; $b = $v -and $v -ne '%%CDKEY%%'; $bg = if ($b) { 'Green' } else { 'DarkRed' }; Write-Host ('Kanes Wrath:   ') -n; Write-Host $v -back $bg -fore White"
        reg query "%RA3%" /ve 2>nul | findstr /c:"REG_SZ" | %psc% "$v = $input -replace '^.*?REG_SZ\s*',''; $b = $v -and $v -ne '%%CDKEY%%'; $bg = if ($b) { 'Green' } else { 'DarkRed' }; Write-Host ('Red Alert 3:   ') -n; Write-Host $v -back $bg -fore White"
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

    :manual_key
        set "new_ergc_key="
        set /p "new_ergc_key=Enter new ergc key: "
        if not defined new_ergc_key (
            call :write "%COLOR.RED%" "The key cannot be empty"
            goto :manual_key
        )
        set "ergc_key=!new_ergc_key!"
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

: PowerShell script content
: To run this text as PS script use cmd batch code:
: %psc% "$text = [IO.File]::ReadAllText('%~f0'); $code = ($text -split '(?m)^:__PS_SCRIPT__\r?\n', 2)[1]; & ([scriptblock]::Create($code))"
:__PS_SCRIPT__
Write-Host "PowerShell script file inside bat!"
