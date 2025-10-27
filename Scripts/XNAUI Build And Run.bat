@echo off

cd ..
call BuildAll.bat
call PackAll.bat
taskkill /f /im dot*

cd bin
for /f "tokens=*" %%d in ('dir "%cd%" /a:d /b') do (
    for /f "tokens=*" %%f in ('dir "%%d" /a:a /b') do (
        echo %%d\%%f 
        copy /y %%d\%%f %%f
        )
    )

copy /y WindowsDXDebug\net48\Rampastring.XNAUI.WindowsDX.Debug.dll Rampastring.XNAUI.WindowsDX.Debug.dll
copy /y WindowsDXDebug\net48\Rampastring.XNAUI.WindowsDX.Debug.pdb Rampastring.XNAUI.WindowsDX.Debug.pdb
copy /y WindowsDXDebug\net48\Rampastring.XNAUI.WindowsDX.Debug.xml Rampastring.XNAUI.WindowsDX.Debug.xml

copy /y WindowsDXDebug\net48\Rampastring.XNAUI.WindowsDX.Debug.dll D:\_Github\_Clients\_XNAClient\DXMainClient\bin\Debug\WindowsDX\net48\Rampastring.XNAUI.WindowsDX.Debug.dll
copy /y WindowsDXDebug\net48\Rampastring.XNAUI.WindowsDX.Debug.pdb D:\_Github\_Clients\_XNAClient\DXMainClient\bin\Debug\WindowsDX\net48\Rampastring.XNAUI.WindowsDX.Debug.pdb
copy /y WindowsDXDebug\net48\Rampastring.XNAUI.WindowsDX.Debug.xml D:\_Github\_Clients\_XNAClient\DXMainClient\bin\Debug\WindowsDX\net48\Rampastring.XNAUI.WindowsDX.Debug.xml

cd D:\_Github\_Clients\_XNAClient\DXMainClient\bin\Debug\WindowsDX\net48\
start clientdx.exe

timeout /t 30
