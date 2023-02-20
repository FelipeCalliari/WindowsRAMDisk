:: -------------------------------
::
:: Copyright (c) by Felipe Calliari, 2022-2023
::
:: -------------------------------
::
:: APPDATA     =%USERPROFILE%\AppData\Roaming
:: LOCALAPPDATA=%USERPROFILE%\AppData\Local
::
:: -------------------------------

@setlocal DisableDelayedExpansion
@echo off
setlocal
call :setESC
CLS

:: -------------------------------
:: Global Variable declarations
:: -------------------------------

set STARTDIR=%~dp0

:: FIX escape character \

set "STARTDIR=%STARTDIR:\=/%"

:: -------------------------------
:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows
:: -------------------------------

set "_cmdf=%~f0"
for %%# in (%*) do (
  if /i "%%#"=="r1" set r1=1
  if /i "%%#"=="r2" set r2=1
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
  setlocal EnableDelayedExpansion
  start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
  exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
  setlocal EnableDelayedExpansion
  start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
  exit /b
)

::  Set Path variable, it helps if it is misconfigured in the system

set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\;%LOCALAPPDATA%\Microsoft\WindowsApps"

if exist "%SystemRoot%\Sysnative\reg.exe" (
  set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

::  Fix for the special characters limitation in path name
set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_ttemp=%temp%"

:: -------------------------------
:: Modify title, colors and size
:: -------------------------------

cls
color 07
title  RAMDisk and Symbolic Links

:: -------------------------------
:: Admin test
:: -------------------------------
IF EXIST "%Windir%\Sysnative\sppsvc.exe" SET SysPath=%Windir%\Sysnative
IF EXIST "%Windir%\System32\sppsvc.exe"  SET SysPath=%Windir%\System32

:ADMIN_TEST
ECHO ADMIN_TEST > %SysPath%\admin_test.txt
IF NOT EXIST %SysPath%\admin_test.txt GOTO:NOT_ADMIN
DEL /s /q %SysPath%\admin_test.txt >nul

:: -------------------------------
:: Install OSFMount
:: -------------------------------

if not exist "%ProgramFiles%\OSFMount\OSFMount.exe" (
  winget list OSFMount
  IF %ERRORLEVEL% equ 0 (
    @ECHO.
    @ECHO OSFMount is installed..
    @ECHO.
  ) ELSE (
    winget install OSFMount --silent
  )
)

:: -------------------------------
:: Check settings.ini
:: -------------------------------

set RAMDiskUseUserProfile=TRUE
set RAMDiskDestination=

:: RAMDiskUseUserProfile

setlocal enabledelayedexpansion

call :get-ini %STARTDIR%settings.ini install useUserProfile result

:: Trick to save %result% after the command "endlocal"
(
  endlocal
  set "RAMDiskUseUserProfile=%result%"
)

:: RAMDiskDestination

if /i "%RAMDiskUseUserProfile%"=="TRUE" (
  set RAMDiskDestination=%LOCALAPPDATA:\=/%/WRamdisk/
  GOTO :INSTALLFILES
) 

setlocal enabledelayedexpansion

call :get-ini %STARTDIR%settings.ini install folder result

:: Trick to save %result% after the command "endlocal"
(
  endlocal
  set "RAMDiskDestination=%result:\=/%"
)

:: -------------------------------
:: Install / copy files
:: -------------------------------

:INSTALLFILES

if exist "%RAMDiskDestination%" (
  :: PRINT BANNER
  ECHO %ESC%[101;93m%ESC%[5L%ESC%[0m
  ECHO.
  ECHO %ESC%[101;93m    * Already installed? Updating files..
  ECHO.
  ECHO %ESC%[0m
)

CALL :CopyFromTo "%STARTDIR%scripts" "%RAMDiskDestination%"
CALL :CopyFromTo "%STARTDIR%"        "%RAMDiskDestination%" "settings.ini"

:: -------------------------------
:: Save Persistent Data
:: -------------------------------

call "%RAMDiskDestination%RAMDisk_SavePersistent.bat"

:: -------------------------------
:: Create Tasks
:: -------------------------------

@ECHO.
@ECHO %ESC%[101;93m%ESC%[1L [Tasks] %ESC%[0m

:: SavePersistent: Every X Minutes/Hours

@ECHO %ESC%[101;93m%ESC%[1L [Tasks] RAMDisk_SavePersistentData_EveryXMin %ESC%[0m

set CMD_TO_PWSH=%RAMDiskDestination%RAMDisk_SavePersistent.bat

@powershell.exe -NoProfile "[xml]$xml = Get-Content 'tasks/TEMPLATE_SAVE_PERSISTENT_EVERYXMIN.xml' -Raw;"^
 "$xml.Task.Actions.Exec.Command=\"$env:CMD_TO_PWSH\";"^
 "$xml.Save('RAMDisk_SavePersistentData_EveryXmin.xml')"

schtasks /Query /TN "\RAMDisk\SavePersistentData_EveryXmin" >nul

IF %ERRORLEVEL% equ 0 (
  schtasks /Delete /TN "\RAMDisk\SavePersistentData_EveryXmin" /F >nul
)
schtasks /Create /TN "\RAMDisk\SavePersistentData_EveryXmin" /xml "%STARTDIR%RAMDisk_SavePersistentData_EveryXmin.xml" >nul

schtasks /Run /TN "\RAMDisk\SavePersistentData_EveryXmin" >nul

del RAMDisk_SavePersistentData_EveryXmin.xml /F >nul 2>nul

:: SavePersistent: OnLogOn/OnLogoff/OnShutdown

@ECHO %ESC%[101;93m%ESC%[1L [Tasks] RAMDisk_SavePersistentData_OnEvent %ESC%[0m

set CMD_TO_PWSH=%RAMDiskDestination%RAMDisk_SavePersistent.bat

@powershell.exe -NoProfile "[xml]$xml = Get-Content 'tasks/TEMPLATE_SAVE_PERSISTENT_ONEVENT.xml' -Raw;"^
 "$xml.Task.Actions.Exec.Command=\"$env:CMD_TO_PWSH\";"^
 "$xml.Save('RAMDisk_SavePersistentData_OnEvent.xml')"

schtasks /Query /TN "\RAMDisk\SavePersistentData_OnEvent" >nul

IF %ERRORLEVEL% equ 0 (
  schtasks /Delete /TN "\RAMDisk\SavePersistentData_OnEvent" /F >nul
)
schtasks /Create /TN "\RAMDisk\SavePersistentData_OnEvent" /xml "%STARTDIR%RAMDisk_SavePersistentData_OnEvent.xml" >nul

schtasks /Run /TN "\RAMDisk\SavePersistentData_OnEvent" >nul

del RAMDisk_SavePersistentData_OnEvent.xml /F >nul 2>nul

:: OnLogon

@ECHO %ESC%[101;93m%ESC%[1L [Tasks] RAMDisk_OnLogonStart %ESC%[0m

set CMD_TO_PWSH=%RAMDiskDestination%RAMDisk_OnLogon.bat

@powershell.exe -NoProfile "[xml]$xml = Get-Content 'tasks/TEMPLATE_ON_LOGON.xml' -Raw;"^
 "$xml.Task.Actions.Exec.Command=\"$env:CMD_TO_PWSH\";"^
 "$xml.Save('RAMDisk_OnLogonStart.xml')"

schtasks /Query /TN "\RAMDisk\OnLogonStart" >nul

IF %ERRORLEVEL% equ 0 (
  schtasks /Delete /TN "\RAMDisk\OnLogonStart" /F >nul
)

schtasks /Create /TN "\RAMDisk\OnLogonStart" /xml "%STARTDIR%RAMDisk_OnLogonStart.xml" >nul

schtasks /Run /TN "\RAMDisk\OnLogonStart" >nul

del RAMDisk_OnLogonStart.xml /F >nul 2>nul

:: PRINT BANNER
ECHO.
ECHO %ESC%[102;97m%ESC%[5L%ESC%[0m
ECHO.
ECHO %ESC%[102;97m    Windows RAMDisk installed..
ECHO.
ECHO %ESC%[0m

timeout /t 5

GOTO :EOF

:: -------------------------------
:: Functions
:: -------------------------------

:: -------------------------------
:: function setESC (colors)
:: -------------------------------

:setESC

for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /B 0
)
exit /B 0

GOTO :EOF

:: -------------------------------
:: function CopyFromTo
:: -------------------------------

:CopyFromTo <from> <to> <file>

:: Check if "original" folder exists, there is not
:: point in copying nothing to anywhere..
if not exist %1 ( 
  GOTO :EOF
)

:: Create the destination folder
if not exist %2 ( 
  :: MD %2 2>NUL
  echo.
)

:: /E   => copy subdirectories, even if empty
:: /R:5 => repetition number if copy fails = 5 tries
:: /W:1 => wait time between tries = 1 second

if "%3"=="" (
  robocopy %1 %2 /MIR /E /COPYALL /R:5 /W:1 >nul 2>nul
) else (
  robocopy %1 %2 %3 >nul 2>nul
)

GOTO :EOF

:: -------------------------------
:: function get-ini
::
::    from The Batchography book by Elias Bachaalany
:: -------------------------------

:get-ini <filename> <section> <key> <result>

set %~4=
setlocal
set insection=

for /f "usebackq eol=; tokens=*" %%a in ("%~1") do (
	set line=%%a

	rem We are inside a section, look for the right key
	if defined insection (
		rem Let's look for the right key
		for /f "tokens=1,* delims==" %%b in ("!line!") do (
			if /i "%%b"=="%3" (
				endlocal
				set %~4=%%c
				goto :eof
			)
		)
	)

	rem Is this a section?
	if "!line:~0,1!"=="[" (
		for /f "delims=[]" %%b in ("!line!") do (
			rem Is this the right section?
			if /i "%%b"=="%2" (
				set insection=1
			) else (
				rem We previously found the right section, so just exit when you encounter a new one
				endlocal
				if defined insection goto :eof
			)
		)
	)
)
endlocal

GOTO :EOF

:: -------------------------------
:: END of FILE
:: -------------------------------
:NOT_ADMIN
CLS

:: FILL SCREEN
REM @ECHO %ESC%[101;93m%ESC%[2J%ESC%[0m

:: PRINT BANNER
@ECHO %ESC%[101;93m%ESC%[5L%ESC%[0m
@ECHO.
@ECHO %ESC%[101;93m    * Run as administrator.
@ECHO %ESC%[0m

:: Run as admin
>nul fltmc || (
  setlocal EnableDelayedExpansion
  powershell.exe "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && exit /b
  ECHO This script require administrator privileges.
  ECHO To do so, right click on this script and select 'Run as administrator'.
  GOTO :EOF
)

TIMEOUT /t 3 > nul
EXIT

:EOF
EXIT