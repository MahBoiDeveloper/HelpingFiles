#https://www.outsidethebox.ms/21899
#Параметры задания
$taskname = 'RunAsTI'
$execute = 'powershell'
#Запись в раздел реестра, которым владеет TI (предотвращение установки Teams), и вывод whoami в текстовый файл
$argument = '-ExecutionPolicy Bypass -Noprofile -Command "& {
    taskill /f /im CompatTelRunner.exe
    del ‪C:\Windows\System32\CompatTelRunner.exe
}"'
$action = New-ScheduledTaskAction -Execute $execute -Argument $argument
#Создание задание в планировщике
Register-ScheduledTask -TaskName $taskname -Action $action
#Запуск задания от имени TrustedInstaller
$svc = New-Object -ComObject 'Schedule.Service'
$svc.Connect()
$user = 'NT SERVICE\TrustedInstaller'
$folder = $svc.GetFolder('\')
$task = $folder.GetTask('RunAsTI')
$task.RunEx($null, 0, 0, $user)
#Удаление задания
Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
