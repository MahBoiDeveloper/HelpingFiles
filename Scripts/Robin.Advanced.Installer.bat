:: Batch установщик Robin Platform 2.0.0 license Cloud by mah_boi
::   Version: 2.0
::   Полезные ссылки:
::     Запуск PS от имени TrustedInstaller: https://www.outsidethebox.ms/21899
::     Правильное использование IF: https://ab57.ru/cmdlist/if.html
::     Аргументы команды START: https://ab57.ru/cmdlist/start.html#:~:text=WAIT%20%2D%20%D0%97%D0%B0%D0%BF%D1%83%D1%81%D0%BA%20%D0%BF%D1%80%D0%B8%D0%BB%D0%BE%D0%B6%D0%B5%D0%BD%D0%B8%D1%8F%20%D1%81%20%D0%BE%D0%B6%D0%B8%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%D0%BC%20%D0%B5%D0%B3%D0%BE%20%D0%B7%D0%B0%D0%B2%D0%B5%D1%80%D1%88%D0%B5%D0%BD%D0%B8%D1%8F.&text=%D0%BA%D0%BE%D0%BC%D0%B0%D0%BD%D0%B4%D0%B0%2F%D0%BF%D1%80%D0%BE%D0%B3%D1%80%D0%B0%D0%BC%D0%BC%D0%B0%20%2D%20%D0%95%D1%81%D0%BB%D0%B8%20%D1%8D%D1%82%D0%BE%20%D0%B2%D0%BD%D1%83%D1%82%D1%80%D0%B5%D0%BD%D0%BD%D1%8F%D1%8F,%D0%B1%D1%83%D0%B4%D0%B5%D1%82%20%D0%B7%D0%B0%D0%BA%D1%80%D1%8B%D1%82%D0%BE%20%D0%BF%D0%BE%D1%81%D0%BB%D0%B5%20%D0%B7%D0%B0%D0%B2%D0%B5%D1%80%D1%88%D0%B5%D0%BD%D0%B8%D1%8F%20%D0%BA%D0%BE%D0%BC%D0%B0%D0%BD%D0%B4%D1%8B.
::     Скачивание с FTP через cURL: https://itproffi.ru/komanda-curl-sintaksis-primery-ispolzovaniya/#:~:text=curl%20%2D%2Dversion-,%D0%A1%D0%BA%D0%B0%D1%87%D0%B8%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%84%D0%B0%D0%B9%D0%BB%D0%B0,%D0%B8%2F%D0%B8%D0%BB%D0%B8%20%D0%BC%D0%B5%D1%81%D1%82%D0%BE%20%D0%B4%D0%BB%D1%8F%20%D1%81%D0%BA%D0%B0%D1%87%D0%B8%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F

@echo off
setlocal enabledelayedexpansion
cd "%USERPROFILE%\Desktop"
chcp 65001 > nul
set PS=powershell
set "COLOR.GREEN=42;97m"
set "COLOR.RED=41;97m"
set opcode=

:: Пути до папок робина
set RB_APPDATA=%APPDATA%\Robin Platform\2.0.0
set RB_LOCALAPPDATA=%LOCALAPPDATA%\Programs\Robin Platform\2.0.0
set RB=%USERPROFILE%\Desktop\Robin

:: Пути для поиска файлов-конфигов
set STD_PATH=%RB_LOCALAPPDATA%\Studio
set PLR_PATH=%RB_LOCALAPPDATA%\RobotPlayer
set EXEC_PATH=%RB_LOCALAPPDATA%\Executor
set NET_PATH=%EXEC_PATH%\Net
set JAVA_PATH=%EXEC_PATH%\Java

:: Команда срёт в errorlevel код ошибки, если 1 - нет админских прав, 0 - права есть
whoami /priv | find /i "SeChangeNotifyPrivilege                   Bypass traverse checking                                           Enabled" > nul 2> nul
if %errorlevel%==1 (
    :: Вызвать этот же скрипт от имени админа
    :: https://bitbucket.org/WindowsAddict/microsoft-activation-scripts/raw/0884271c4fcdc72d95bce7c5c7bdf77ef4a9bcef/MAS/All-In-One-Version/MAS_AIO-CRC32_31F7FD1E.cmd
    %PS% "start %0 -verb runas"
    exit /b
)

:cycle
    call :menu

    if %opcode%==1 call :full_install
    if %opcode%==2 call :install
    if %opcode%==3 call :deploy_3rd_party
    if %opcode%==4 call :logging
    if %opcode%==5 call :clearing
    if %opcode%==6 call :write "%COLOR.RED%" "Функция не реализована"
    if %opcode%==7 call :write "%COLOR.RED%" "Функция не реализована"
    if %opcode%==8 call :write "%COLOR.RED%" "Функция не реализована"

goto :exit

:: Вывод меню батника
:menu
    cls
    title Robin Wizard
    mode 76, 30
    echo: 
    echo: 
    echo: 
    echo: 
    echo:       ______________________________________________________________
    echo: 
    echo:                           ДОСТУПНЫЕ ДЕЙСТВИЯ 
    echo: 
    :: echo:             [1] Полная установка с нуля
    :: echo:             [2] Установка Robin Platform
    echo:             [3] Установка дополнительного софта
    echo:             [4] Настройка логов платформы
    echo:             [5] Очистка логов платформы
    echo:             __________________________________________________
    echo: 
    :: echo:             [6] 
    :: echo:             [7] 
    :: echo:             [8] 
    echo:             [9] Выход 
    echo:       ______________________________________________________________
    echo: 
    call :write "%COLOR.GREEN%" "             Введите значение в диапазоне [1,2,3,4,5,6,7,8,9]             "
    choice /C:1234567890 /N
    
    set opcode=%errorlevel%
    if %opcode%==9 (
        exit
    )
    cls
exit /b

:: Полное развёртывание платформы
:full_install
    call :deploy_3rd_party
    call :install
    call :logging
    call :clearing
exit /b

:: Установка платформы
:install
    if exist "%RB_LOCALAPPDATA%\Uninstall\unins000.exe" (
        call :write "%COLOR.RED%" "Платформа ранее была установлена!"
        echo.
        : Строки ниже не работают
        : set /p ch="Желаете переустановить платформу? [Y/N]: "
        : if %ch%==N goto exit /b
        call :log "Удаление платформы..."
        start /wait "" "%RB_LOCALAPPDATA%\Uninstall\unins000.exe" /VERYSILENT /SUPPRESSMSGBOXES
    )

    call :log "Развёртывание Robin Cloud 2.0.0..."
    
    set tmp=
    dir "%RB%" /a:a /s /b | find /i "cloud.exe" > "%RB%\o.txt"
    for /f "tokens=*" %%f in ('find /i "cloud.exe" "%RB%\o.txt"') do set tmp=%%f
    del /s /q "%RB%\o.txt" > nul
    start /wait "" "%tmp%" /VERYSILENT /SUPPRESSMSGBOXES /CURRENTUSER /LOADINF="%RB%\install.ini" /LOG=log.txt /ClientToken="" --RobinServer="" --LogStashHttpUri="" --RabbitUriScheme=amqps --RabbitPort=5673 --RabbitLogin=agent --RabbitPassword=""

    if exist "C:\filebeat\Uninstall\unins000.exe" (
        echo.
        call :write "%COLOR.RED%" "FileBeat ранее был установлен!"
        echo.
        : set /p ch="Желаете переустановить FileBeat? [Y/N]: "
        : if %ch%==N goto exit /b
        call :log "Удаление FileBeat..."
        start /wait "" "C:\filebeat\Uninstall\unins000.exe" /VERYSILENT /SUPPRESSMSGBOXES
    )

    call :log "Развёртывание FileBeat..."
    start /wait "" "%RB_LOCALAPPDATA%\Utils\FilebeatInstaller\SetupFilebeatService.exe" /VERYSILENT /SUPPRESSMSGBOXES /LogstashHost="" /LogstashPort="5045"

    echo.
    call :write "%COLOR.GREEN%" "Установка ОФР завершена"
exit /b

:: Развёртывание всего прочего необходимого
:deploy_3rd_party
    call :log "Развёртывание QRes..."
    copy /y "%RB%\qres.exe" "C:\Windows\System32\" > nul 2> nul

    call :log "Развёртывание .NET Framework 4.8..."
    start "" /wait "%RB%\ndp48-x86-x64-allos-enu.exe" /q /norestart /AcceptEULA

    call :log "Развёртывание .NET SDK 6.0..."
    start "" /wait "%RB%\dotnet-sdk-6.0.415-win-x64.exe" /q /norestart /AcceptEULA

    call :log "Инъекция отключения лишних раскладок по RDP..."
    %WINDIR%\regedit.exe /s "%RB%\Disable.Useless.Keyboard.Layout.RDP.reg"

    call :log "Копирование ярлыков..."
    copy /y "%RB%\Robin Wizard.lnk" > nul 2> nul
    copy /y "%RB%\Robin Agent.lnk" > nul 2> nul
    copy /y "%RB%\Kill Agent.lnk" > nul 2> nul
    copy /y "%RB%\Agent Debug.lnk" > nul 2> nul
    copy /y "%RB%\Restart Agent.lnk" > nul 2> nul
    copy /y "%RB%\Console Mode.lnk" > nul 2> nul

    echo.
    call :write "%COLOR.GREEN%" "Установка 3rd party завершена"
exit /b

:logging
    del /q /s Studio.exe.config      > nul 2> nul
    del /q /s RobotPlayer.exe.config > nul 2> nul
    del /q /s NetExecutor.exe.config > nul 2> nul
    del /q /s logback.xml            > nul 2> nul

    call :log "Остановка платформы полностью..."
    taskkill /f /im java*   > nul 2> nul
    taskkill /f /im net*    > nul 2> nul
    taskkill /f /im robin*  > nul 2> nul
    taskkill /f /im robot*  > nul 2> nul
    taskkill /f /im studio* > nul 2> nul
    start "" "%RB_LOCALAPPDATA%\Agent\Kill.Robin.Agent.exe" > nul

    call :log "Генерация правильных конфигов..."
    (
        echo ^<?xml version="1.0" encoding="utf-8"?^>
        echo ^<configuration^>
        echo   ^<configSections^>
        echo     ^<section name="modules" type="Prism.Modularity.ModulesConfigurationSection, Prism.Wpf" /^>
        echo     ^<section name="log4net" type="log4net.Config.Log4NetConfigurationSectionHandler,log4net" /^>
        echo     ^<sectionGroup name="userSettings" type="System.Configuration.UserSettingsGroup, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"^>
        echo       ^<section name="Robin.Studio.Core.DiagramPrimitives.Properties.Settings" type="System.Configuration.ClientSettingsSection, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" allowExeDefinition="MachineToLocalUser" requirePermission="false" /^>
        echo     ^</sectionGroup^>
        echo   ^</configSections^>
        echo   ^<log4net^>
        echo     ^<appender name="LogAppender" type="log4net.Appender.RollingFileAppender"^>
        echo       ^<file type="log4net.Util.PatternString" value="${USERPROFILE}\AppData\Roaming\Robin Platform\2.0.0\Studio\Logs\log.log" /^>
        echo       ^<preserveLogFileNameExtension value="true" /^>
        echo       ^<rollingStyle value="Composite" /^>
        echo       ^<appendToFile value="false" /^>
        echo       ^<encoding value="utf-8" /^>
        echo       ^<maximumFileSize value="5MB" /^>
        echo       ^<maxSizeRollBackups value="5" /^>
        echo       ^<lockingModel type="log4net.Appender.FileAppender+MinimalLock" /^>
        echo       ^<layout type="log4net.Layout.PatternLayout"^>
        echo         ^<conversionPattern value="%%date{MMM dd hh:mm:ss}%%property{tab}%%property{log4net:HostName}%%property{tab}&lt;%%level&gt;%%property{tab}%%message%%newline" /^>
        echo       ^</layout^>
        echo     ^</appender^>
        echo     ^<root^>
        echo       ^<level value="ALL" /^>
        echo       ^<appender-ref ref="LogAppender" /^>
        echo     ^</root^>
        echo     ^<logger name="LOGGER"^>
        echo       ^<level value="ALL" /^>
        echo     ^</logger^>
        echo   ^</log4net^>
        echo   ^<modules^>
        echo     ^<module assemblyFile="Robin.Studio.Modules.ConfigurationModule" moduleType="Robin.Studio.Modules.ConfigurationModule.ConfigurationModuleInitialization, Robin.Studio.Modules.ConfigurationModule, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" moduleName="ConfigurationModule" startupLoaded="True" /^>
        echo     ^<module assemblyFile="Robin.Studio.Modules.LdapModule" moduleType="Robin.Studio.Modules.LdapModule.LdapModuleInitialization, Robin.Studio.Modules.LdapModule, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" moduleName="LdapModule" startupLoaded="True" /^>
        echo     ^<module assemblyFile="Robin.Studio.Modules.PluginLoaderModule" moduleType="Robin.Studio.Modules.PluginLoaderModule.PluginLoaderInitialization, Robin.Studio.Modules.PluginLoaderModule, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" moduleName="Plugins" startupLoaded="True" /^>
        echo     ^<module assemblyFile="Robin.Studio.Modules.ProjectLoaderModule.dll" moduleType="Robin.Studio.Modules.ProjectLoaderModule.ProjectLoaderModuleInitialization, Robin.Studio.Modules.ProjectLoaderModule, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" moduleName="ProjectLoaderModule" startupLoaded="False" /^>
        echo     ^<module assemblyFile="Robin.Studio.Modules.StartScreenModule" moduleType="Robin.Studio.Modules.StartScreenModule.StartScreenModuleInitialization, Robin.Studio.Modules.StartScreenModule, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" moduleName="StartScreenModule" startupLoaded="False" /^>
        echo     ^<module assemblyFile="Robin.Studio.Modules.ApplicationModule.dll" moduleType="Robin.Studio.Modules.ApplicationModule.ApplicationModuleInitialization, Robin.Studio.Modules.ApplicationModule, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" moduleName="ApplicationModule" startupLoaded="False" /^>
        echo     ^<module assemblyFile="Robin.Studio.Modules.PanelLoaderModule.dll" moduleType="Robin.Studio.Modules.PanelLoaderModule.PanelLoaderModuleInitialization, Robin.Studio.Modules.PanelLoaderModule, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" moduleName="PanelLoaderModule" startupLoaded="False" /^>
        echo   ^</modules^>
        echo   ^<startup^>
        echo     ^<supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.8" /^>
        echo   ^</startup^>
        echo   ^<userSettings^>
        echo     ^<Robin.Studio.Core.DiagramPrimitives.Properties.Settings^>
        echo       ^<setting name="NetEngineVersion" serializeAs="String"^>
        echo         ^<value^>2.0.2^</value^>
        echo       ^</setting^>
        echo       ^<setting name="JavaEngineVersion" serializeAs="String"^>
        echo         ^<value^>1.0.7^</value^>
        echo       ^</setting^>
        echo       ^<setting name="PythonEngineVersion" serializeAs="String"^>
        echo         ^<value^>1.0.0^</value^>
        echo       ^</setting^>
        echo     ^</Robin.Studio.Core.DiagramPrimitives.Properties.Settings^>
        echo   ^</userSettings^>
        echo   ^<runtime^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="System.Collections.Immutable" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-1.2.1.0" newVersion="1.2.1.0" /^>
        echo       ^</dependentAssembly^>
        echo       ^<probing privatePath="Plugins" /^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="DryIoc" publicKeyToken="dfbf2bd50fcf7768" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-4.8.0.0" newVersion="4.8.0.0" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="Microsoft.Extensions.Logging.Abstractions" publicKeyToken="adb9793829ddae60" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-2.2.0.0" newVersion="2.2.0.0" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="Newtonsoft.Json" publicKeyToken="30ad4fe6b2a6aeed" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-13.0.0.0" newVersion="13.0.0.0" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="System.Memory" publicKeyToken="cc7b13ffcd2ddd51" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-4.0.1.1" newVersion="4.0.1.1" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="System.Threading.Tasks.Extensions" publicKeyToken="cc7b13ffcd2ddd51" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-4.2.0.1" newVersion="4.2.0.1" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="EntityFramework" publicKeyToken="b77a5c561934e089" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-6.0.0.0" newVersion="6.0.0.0" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo   ^</runtime^>
        echo ^</configuration^>
    ) >> Studio.exe.config

    (
        echo ^<?xml version="1.0" encoding="utf-8"?^>
        echo ^<configuration^>
        echo   ^<configSections^>
        echo     ^<section name="log4net" type="log4net.Config.Log4NetConfigurationSectionHandler,log4net" /^>
        echo   ^</configSections^>
        echo   ^<log4net^>
        echo     ^<appender name="LogAppender" type="log4net.Appender.RollingFileAppender"^>
        echo       ^<file type="log4net.Util.PatternString" value="${USERPROFILE}\AppData\Roaming\Robin Platform\2.0.0\RobotPlayer\Logs\PlayerLog.log" /^>
        echo       ^<preserveLogFileNameExtension value="true" /^>
        echo       ^<rollingStyle value="Composite" /^>
        echo       ^<appendToFile value="false" /^>
        echo       ^<encoding value="utf-8" /^>
        echo       ^<maximumFileSize value="5MB" /^>
        echo       ^<maxSizeRollBackups value="5" /^>
        echo       ^<lockingModel type="log4net.Appender.FileAppender+MinimalLock" /^>
        echo       ^<layout type="log4net.Layout.PatternLayout"^>
        echo         ^<conversionPattern value="%%date{MMM dd hh:mm:ss}%%property{tab}%%property{log4net:HostName}%%property{tab}&lt;%%level&gt;%%property{tab}%%message%%newline" /^>
        echo       ^</layout^>
        echo     ^</appender^>
        echo     ^<root^>
        echo       ^<level value="ALL" /^>
        echo       ^<appender-ref ref="LogAppender" /^>
        echo     ^</root^>
        echo     ^<logger name="LOGGER"^>
        echo       ^<level value="ALL" /^>
        echo     ^</logger^>
        echo   ^</log4net^>
        echo   ^<runtime^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="BouncyCastle.Crypto" publicKeyToken="0e99375e54769942" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-1.8.9.0" newVersion="1.8.9.0" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="Google.Protobuf" publicKeyToken="a7d26565bac4d604" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-3.15.6.0" newVersion="3.15.6.0" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="Newtonsoft.Json" publicKeyToken="30ad4fe6b2a6aeed" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-12.0.0.0" newVersion="12.0.0.0" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="Robin.Schema.ActionScheme" publicKeyToken="e85b33dc387ce47c" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-1.2.5.0" newVersion="1.2.5.0" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="System.Threading.Tasks.Extensions" publicKeyToken="cc7b13ffcd2ddd51" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-4.2.0.1" newVersion="4.2.0.1" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="EntityFramework" publicKeyToken="b77a5c561934e089" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-6.0.0.0" newVersion="6.0.0.0" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo   ^</runtime^>
        echo ^</configuration^>
    ) >> RobotPlayer.exe.config

    (
        echo ^<?xml version="1.0" encoding="utf-8"?^>
        echo ^<configuration^>
        echo   ^<configSections^>
        echo     ^<section name="log4net" type="log4net.Config.Log4NetConfigurationSectionHandler,log4net" /^>
        echo   ^</configSections^>
        echo   ^<log4net^>
        echo     ^<appender name="LogAppender" type="log4net.Appender.RollingFileAppender"^>
        echo       ^<file type="log4net.Util.PatternString" value="${APPDATA}\Robin Platform\2.0.0\Executor\Logs\netExecutorLog.log" /^>
        echo       ^<preserveLogFileNameExtension value="true" /^>
        echo       ^<rollingStyle value="Composite" /^>
        echo       ^<appendToFile value="false" /^>
        echo       ^<encoding value="utf-8" /^>
        echo       ^<maximumFileSize value="5MB" /^>
        echo       ^<maxSizeRollBackups value="5" /^>
        echo       ^<lockingModel type="log4net.Appender.FileAppender+MinimalLock" /^>
        echo       ^<layout type="log4net.Layout.PatternLayout"^>
        echo         ^<conversionPattern value="%%date{MMM dd hh:mm:ss}%%property{tab}%%property{log4net:HostName}%%property{tab}&lt;%%level&gt;%%property{tab}%%message%%newline" /^>
        echo       ^</layout^>
        echo     ^</appender^>
        echo     ^<root^>
        echo       ^<level value="ALL" /^>
        echo       ^<appender-ref ref="LogAppender" /^>
        echo     ^</root^>
        echo   ^</log4net^>
        echo   ^<startup^>
        echo     ^<supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.8" /^>
        echo   ^</startup^>
        echo   ^<appSettings^>
        echo     ^<add key="ClientSettingsProvider.ServiceUri" value="" /^>
        echo   ^</appSettings^>
        echo   ^<system.web^>
        echo     ^<membership defaultProvider="ClientAuthenticationMembershipProvider"^>
        echo       ^<providers^>
        echo         ^<add name="ClientAuthenticationMembershipProvider" type="System.Web.ClientServices.Providers.ClientFormsAuthenticationMembershipProvider, System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" serviceUri="" /^>
        echo       ^</providers^>
        echo     ^</membership^>
        echo     ^<roleManager defaultProvider="ClientRoleProvider" enabled="true"^>
        echo       ^<providers^>
        echo         ^<add name="ClientRoleProvider" type="System.Web.ClientServices.Providers.ClientRoleProvider, System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" serviceUri="" cacheTimeout="86400" /^>
        echo       ^</providers^>
        echo     ^</roleManager^>
        echo   ^</system.web^>
        echo   ^<runtime^>
        echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^>
        echo       ^<dependentAssembly^>
        echo         ^<assemblyIdentity name="System.Threading.Tasks.Extensions" publicKeyToken="cc7b13ffcd2ddd51" culture="neutral" /^>
        echo         ^<bindingRedirect oldVersion="0.0.0.0-4.2.0.1" newVersion="4.2.0.1" /^>
        echo       ^</dependentAssembly^>
        echo     ^</assemblyBinding^>
        echo   ^</runtime^>
        echo ^</configuration^>
    ) >> NetExecutor.exe.config

    (
        echo ^<?xml version="1.0" encoding="UTF-8"?^>
        echo ^<configuration^>
        echo    ^<appender name="CONSOLE"
        echo        class="ch.qos.logback.core.ConsoleAppender"^>
        echo        ^<encoder class="ch.qos.logback.core.encoder.LayoutWrappingEncoder"^>
        echo            ^<charset^>UTF-8^</charset^>
        echo            ^<layout class="ru.robin.logging.RobinJsonLayout"^>
        echo                ^<dateFormat^>MMMM dd HH:mm:ss^</dateFormat^>
        echo                ^<hostName^>${HOSTNAME}^</hostName^>
        echo                ^<printLogLevel^>true^</printLogLevel^>
        echo                ^<stackTraceLength^>short^</stackTraceLength^>
        echo            ^</layout^>
        echo        ^</encoder^>
        echo    ^</appender^>
        echo    ^<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender"^>
        echo        ^<file^>${APPDATA}/Robin Platform/2.0.0/Executor/Logs/javaExecutorLog.log^</file^>
        echo        ^<!-- Если число файлов логов больше 10, то они начинают удаляться, начиная с самого старого --^>
        echo        ^<rollingPolicy 
        echo            class="ch.qos.logback.core.rolling.FixedWindowRollingPolicy"^>
        echo            ^<fileNamePattern^>${APPDATA}/Robin Platform/2.0.0/Executor/Logs/javaExecutorLog.%i.log^</fileNamePattern^>
        echo            ^<minIndex^>1^</minIndex^>
        echo            ^<maxIndex^>5^</maxIndex^>
        echo        ^</rollingPolicy^>
        echo        ^<!-- Если файл лога превышает 20MB, то он архивируется с названием java.1.log, и создаётся новый лог-файл java.log --^>
        echo        ^<triggeringPolicy 
        echo            class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy"^>
        echo            ^<maxFileSize^>5MB^</maxFileSize^>
        echo        ^</triggeringPolicy^>
        echo        ^<encoder class="ch.qos.logback.core.encoder.LayoutWrappingEncoder"^>
        echo            ^<charset^>UTF-8^</charset^>
        echo            ^<layout class="ru.robin.logging.RobinJsonLayout"^>
        echo                ^<dateFormat^>MMMM dd HH:mm:ss^</dateFormat^>
        echo                ^<hostName^>${HOSTNAME}^</hostName^>
        echo                ^<printLogLevel^>true^</printLogLevel^>
        echo                ^<stackTraceLength^>short^</stackTraceLength^>
        echo            ^</layout^>
        echo        ^</encoder^>
        echo    ^</appender^>
        echo    ^<root level="INFO"^>
        echo        ^<appender-ref ref="CONSOLE" /^>
        echo        ^<appender-ref ref="FILE" /^>
        echo    ^</root^>
        echo    ^<!--Для совместимости с библиотекой логирования 1.0.4--^>
        echo    ^<appender name="CONSOLE-OLD"
        echo              class="ch.qos.logback.core.ConsoleAppender"^>
        echo        ^<encoder^>
        echo            ^<charset^>UTF-8^</charset^>
        echo            ^<pattern^>%%d{MMMM dd HH:mm:ss} ${HOSTNAME} %%-5level %%m%%n^</pattern^>
        echo        ^</encoder^>
        echo    ^</appender^>
        echo    ^<!--Для совместимости с библиотекой логирования 1.0.4--^>
        echo    ^<appender name="FILE-OLD" class="ch.qos.logback.core.rolling.RollingFileAppender"^>
        echo        ^<file^>${APPDATA}/Robin Platform/2.0.0/Executor/Logs/java.log^</file^>
        echo        ^<!-- Если число файлов логов больше 10, то они начинают удаляться, начиная с самого старого --^>
        echo        ^<rollingPolicy
        echo                class="ch.qos.logback.core.rolling.FixedWindowRollingPolicy"^>
        echo            ^<fileNamePattern^>${APPDATA}/Robin Platform/2.0.0/Executor/Logs/java.%%i.log^</fileNamePattern^>
        echo            ^<minIndex^>1^</minIndex^>
        echo            ^<maxIndex^>5^</maxIndex^>
        echo        ^</rollingPolicy^>
        echo        ^<!-- Если файл лога превышает 20MB, то он архивируется с названием java.1.log, и создаётся новый лог-файл java.log --^>
        echo        ^<triggeringPolicy
        echo                class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy"^>
        echo            ^<maxFileSize^>5MB^</maxFileSize^>
        echo        ^</triggeringPolicy^>
        echo        ^<encoder^>
        echo            ^<charset^>UTF-8^</charset^>
        echo            ^<pattern^>%%d{MMMM dd HH:mm:ss} ${HOSTNAME} %%-5level %%m%%n^</pattern^>
        echo        ^</encoder^>
        echo    ^</appender^>
        echo    ^<!--Для совместимости с библиотекой логирования 1.0.4--^>
        echo    ^<logger name="ru.robin.logging.RobinLogger" level="INFO"^>
        echo        ^<appender-ref ref="CONSOLE-OLD" /^>
        echo        ^<appender-ref ref="FILE-OLD" /^>
        echo    ^</logger^>
        echo ^</configuration^>
    ) >> logback.xml

    call :log "Замена конфигов..."
    timeout /t 5 > nul
    move /y "Studio.exe.config"      "%STD_PATH%\Studio.exe.config"      > nul
    move /y "RobotPlayer.exe.config" "%PLR_PATH%\RobotPlayer.exe.config" > nul
    move /y "NetExecutor.exe.config" "%NET_PATH%\NetExecutor.exe.config" > nul
    move /y "logback.xml"            "%JAVA_PATH%\logback.xml"           > nul

    call :log "Запуск платформы..."
    start "" "%RB_LOCALAPPDATA%\Agent\Robin.Agent.exe"
    start "" "%RB_LOCALAPPDATA%\RobotPlayer\RobotPlayer.exe"

    echo.
    call :write "%COLOR.GREEN%" "Логи платформы успешно настроены"
exit /b

:kill
    call :log "Закрытие процессов платформы..."
    taskkill /f /im java*   > nul 2> nul
    taskkill /f /im net*    > nul 2> nul
    taskkill /f /im robin*  > nul 2> nul
    taskkill /f /im robot*  > nul 2> nul
    start "" "%RB_LOCALAPPDATA%\Agent\Kill.Robin.Agent.exe"
exit /b

:start
    call :log "Запуск агента..."
    start "" "%RB_LOCALAPPDATA%\Agent\Robin.Agent.exe"
    call :log "Запуск плеера..."
    start "" "%RB_LOCALAPPDATA%\RobotPlayer\RobotPlayer.exe"
exit /b

:: Удаление всех логов робин
:clearing
    mode 170, 30
    call :clear_folder "%RB_APPDATA%"
    call :clear_folder "%RB_LOCALAPPDATA%"
    echo.

    call :write "%color.green%" "Папки логов очищены"
exit /b

:: Удаление логов в папке
:clear_folder
    call :log "Удаление логов в %~1..."
    for /f "tokens=*" %%f in ('dir "%~1\*.log" /a:a /s /b') do del /f /q "%%f" > nul 2> nul
    call :log "Удаление логов в %~1 завершено"
exit /b

:: Использовать всегда в больших блоках для установки таймстампов сообщений
:log
    echo [%date% -- %time:~0,-3%] %~1
exit /b

:: Вывод текста на экран с колоризацией
:: https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
:write
    echo [%~1%~2[0m
exit /b

:: Вывод через powershell не использовать, т.к. меняет шрифт в терминале
:pswrite
    %ps% Write-Host %~3 -back %~1 -fore %~2
exit /b

:exit
    echo.
    echo Нажмите Enter, чтобы выйти из программы...
    timeout /t 60 > nul

:eof
