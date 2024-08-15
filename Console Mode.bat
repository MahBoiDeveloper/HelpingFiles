@echo off

::pause
for /f "skip=1 tokens=3" %%s in ('query user %USERNAME%') do tscon %%s /dest:console
qres /x:1920 /y:1080

:exit
