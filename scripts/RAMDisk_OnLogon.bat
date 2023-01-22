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

set RAMDiskPersistent=FALSE
set RAMDiskLetter=B:
set RAMDiskSize=2G

setlocal enabledelayedexpansion

call :get-ini %STARTDIR%settings.ini settings persistent result

:: Trick to save %result% after the command "endlocal"
(
  endlocal
  set "RAMDiskPersistent=%result%"
)

setlocal enabledelayedexpansion

call :get-ini %STARTDIR%settings.ini ramdisk letter localLetter

:: Trick to save %result% after the command "endlocal"
(
  endlocal
  set "RAMDiskLetter=%localLetter%"
)

setlocal enabledelayedexpansion

call :get-ini %STARTDIR%settings.ini ramdisk size localSize

:: Trick to save %result% after the command "endlocal"
(
  endlocal
  set "RAMDiskSize=%localSize%"
)

:: @ECHO.
:: @ECHO Persistent %RAMDiskPersistent%
:: @ECHO Letter     %RAMDiskLetter%
:: @ECHO Size       %RAMDiskSize%
:: @ECHO.
:: timeout /t 10 /nobreak

:: -------------------------------
:: Create RAMDisk
:: -------------------------------

:CREATE_RAMDISK

@ECHO.
@ECHO %ESC%[101;93m%ESC%[3L%ESC%[0m
@ECHO %ESC%[101;93m  Creating RAMDisk on %RAMDiskLetter%\  %ESC%[0m
@ECHO.

::"C:\Program Files\OSFMount\OSFMount.com" -a -t vm -s 2G -m B: -o rw,format:ntfs:"RAMDisk"

"C:\Program Files\OSFMount\OSFMount.com" -a -t vm -s %RAMDiskSize% -m %RAMDiskLetter% -o rw,format:ntfs:"RAMDisk"

:: OFSMount could not load driver..
:: wait for Windows SCM (Service Control Manager)
IF %ERRORLEVEL% equ 4 (
  timeout /T 1 /nobreak >nul
  GOTO :CREATE_RAMDISK
)

timeout /T 1 /NOBREAK >NUL

:: -------------------------------
:: Create Symbolic Links
::    and copy Persistent Data
:: -------------------------------
::
:: APPDATA     =%USERPROFILE%\AppData\Roaming
:: LOCALAPPDATA=%USERPROFILE%\AppData\Local
::
:: -------------------------------
::
:: Change the cache size. In bytes; the example below is 200MB.
::
:: AppData\Local\Google\Chrome\Application\chrome.exe --disk-cache-dir="G:/" --disk-cache-size=209715200
::
:: -------------------------------

IF EXIST "%LOCALAPPDATA%\Google\Chrome\User Data\Default\" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] Google Chrome %ESC%[0m
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"           "%RAMDiskLetter%\Cache\Chrome\Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache"      "%RAMDiskLetter%\Cache\Chrome\Code Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome\User Data\Default\GPUCache"        "%RAMDiskLetter%\Cache\Chrome\GPUCache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Service Worker"  "%RAMDiskLetter%\Cache\Chrome\Service Worker"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Session Storage" "%RAMDiskLetter%\Cache\Chrome\Session Storage"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome\User Data\Default\WebStorage"      "%RAMDiskLetter%\Cache\Chrome\WebStorage"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome\User Data\ShaderCache"             "%RAMDiskLetter%\Cache\Chrome\ShaderCache"
  if /i "%RAMDiskPersistent%"=="TRUE" (
    CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Network"           "%RAMDiskLetter%\Cache\Chrome\Network"
    CALL :CopyPersistentDataFromTo "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Chrome\Network" "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Network"
  )
)

IF EXIST "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] Google Chrome Beta %ESC%[0m
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\Cache"           "%RAMDiskLetter%\Cache\Chrome Beta\Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\Code Cache"      "%RAMDiskLetter%\Cache\Chrome Beta\Code Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\GPUCache"        "%RAMDiskLetter%\Cache\Chrome Beta\GPUCache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\Service Worker"  "%RAMDiskLetter%\Cache\Chrome Beta\Service Worker"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\Session Storage" "%RAMDiskLetter%\Cache\Chrome Beta\Session Storage"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\WebStorage"      "%RAMDiskLetter%\Cache\Chrome Beta\WebStorage"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Beta\User Data\ShaderCache"             "%RAMDiskLetter%\Cache\Chrome Beta\ShaderCache"
  if /i "%RAMDiskPersistent%"=="TRUE" (
    CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\Network"           "%RAMDiskLetter%\Cache\Chrome Beta\Network"
    CALL :CopyPersistentDataFromTo "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Chrome Beta\Network" "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\Network"
  )
)

IF EXIST "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] Google Chrome Dev %ESC%[0m
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\Cache"           "%RAMDiskLetter%\Cache\Chrome Dev\Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\Code Cache"      "%RAMDiskLetter%\Cache\Chrome Dev\Code Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\GPUCache"        "%RAMDiskLetter%\Cache\Chrome Dev\GPUCache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\Service Worker"  "%RAMDiskLetter%\Cache\Chrome Dev\Service Worker"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\Session Storage" "%RAMDiskLetter%\Cache\Chrome Dev\Session Storage"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\WebStorage"      "%RAMDiskLetter%\Cache\Chrome Dev\WebStorage"
  CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Dev\User Data\ShaderCache"             "%RAMDiskLetter%\Cache\Chrome Dev\ShaderCache"
  if /i "%RAMDiskPersistent%"=="TRUE" (
    CALL :CreateSymLink "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\Network"           "%RAMDiskLetter%\Cache\Chrome Dev\Network"
    CALL :CopyPersistentDataFromTo "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Chrome Dev\Network" "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\Network"
  )
)

IF EXIST "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] Microsoft Edge %ESC%[0m
  CALL :CreateSymLink "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"           "%RAMDiskLetter%\Cache\Edge\Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache"      "%RAMDiskLetter%\Cache\Edge\Code Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\GPUCache"        "%RAMDiskLetter%\Cache\Edge\GPUCache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Service Worker"  "%RAMDiskLetter%\Cache\Edge\Service Worker"
  CALL :CreateSymLink "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Session Storage" "%RAMDiskLetter%\Cache\Edge\Session Storage"
  CALL :CreateSymLink "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\WebStorage"      "%RAMDiskLetter%\Cache\Edge\WebStorage"
  CALL :CreateSymLink "%LOCALAPPDATA%\Microsoft\Edge\User Data\ShaderCache"             "%RAMDiskLetter%\Cache\Edge\ShaderCache"
  if /i "%RAMDiskPersistent%"=="TRUE" (
    CALL :CreateSymLink "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Network"        "%RAMDiskLetter%\Cache\Edge\Network"
    CALL :CopyPersistentDataFromTo "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Edge\Network" "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Network"
  )
)

IF EXIST "%LOCALAPPDATA%\Opera Software\Opera Stable" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] Opera %ESC%[0m
  CALL :CreateSymLink "%LOCALAPPDATA%\Opera Software\Opera Stable\Cache"        "%RAMDiskLetter%\Cache\Opera\Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Opera Software\Opera Stable\System Cache" "%RAMDiskLetter%\Cache\Opera\System Cache"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera Stable\Code Cache"        "%RAMDiskLetter%\Cache\Opera\Code Cache"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera Stable\GPUCache"          "%RAMDiskLetter%\Cache\Opera\GPUCache"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera Stable\Service Worker"    "%RAMDiskLetter%\Cache\Opera\Service Worker"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera Stable\Session Storage"   "%RAMDiskLetter%\Cache\Opera\Session Storage"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera Stable\WebStorage"        "%RAMDiskLetter%\Cache\Opera\WebStorage"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera Stable\ShaderCache"       "%RAMDiskLetter%\Cache\Opera\ShaderCache"
  if /i "%RAMDiskPersistent%"=="TRUE" (
    CALL :CreateSymLink "%APPDATA%\Opera Software\Opera Stable\Network"                   "%RAMDiskLetter%\Cache\Opera\Network"
    CALL :CopyPersistentDataFromTo "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Opera\Network" "%APPDATA%\Opera Software\Opera Stable\Network"
  )
)

IF EXIST "%LOCALAPPDATA%\Opera Software\Opera GX Stable" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] Opera GX %ESC%[0m
  CALL :CreateSymLink "%LOCALAPPDATA%\Opera Software\Opera GX Stable\Cache"        "%RAMDiskLetter%\Cache\OperaGX\Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Opera Software\Opera GX Stable\System Cache" "%RAMDiskLetter%\Cache\OperaGX\System Cache"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera GX Stable\Code Cache"        "%RAMDiskLetter%\Cache\OperaGX\Code Cache"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera GX Stable\GPUCache"          "%RAMDiskLetter%\Cache\OperaGX\GPUCache"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera GX Stable\Service Worker"    "%RAMDiskLetter%\Cache\OperaGX\Service Worker"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera GX Stable\Session Storage"   "%RAMDiskLetter%\Cache\OperaGX\Session Storage"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera GX Stable\WebStorage"        "%RAMDiskLetter%\Cache\OperaGX\WebStorage"
  CALL :CreateSymLink "%APPDATA%\Opera Software\Opera GX Stable\ShaderCache"       "%RAMDiskLetter%\Cache\OperaGX\ShaderCache"
  if /i "%RAMDiskPersistent%"=="TRUE" (
    CALL :CreateSymLink "%APPDATA%\Opera Software\Opera GX Stable\Network"                  "%RAMDiskLetter%\Cache\OperaGX\Network"
    CALL :CopyPersistentDataFromTo "%LOCALAPPDATA:\=/%/WRamdisk/persistent\OperaGX\Network" "%APPDATA%\Opera Software\Opera GX Stable\Network"
  )
)

IF EXIST "%LOCALAPPDATA%\Mozilla\Firefox\Profiles" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] Mozilla Firefox %ESC%[0m
  CALL :CreateSymLink "%LOCALAPPDATA%\Mozilla\Firefox\Profiles" "%RAMDiskLetter%\Cache\Firefox"
)

IF EXIST "%APPDATA%\Code" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] VSCode %ESC%[0m
  CALL :CreateSymLink "%APPDATA%\Code\Cache"           "%RAMDiskLetter%\Cache\Code\Cache"
  CALL :CreateSymLink "%APPDATA%\Code\CachedData"      "%RAMDiskLetter%\Cache\Code\CachedData"
  CALL :CreateSymLink "%APPDATA%\Code\Code Cache"      "%RAMDiskLetter%\Cache\Code\Code Cache"
  CALL :CreateSymLink "%APPDATA%\Code\GPUCache"        "%RAMDiskLetter%\Cache\Code\GPUCache"
  CALL :CreateSymLink "%APPDATA%\Code\Service Worker"  "%RAMDiskLetter%\Cache\Code\Service Worker"  
  CALL :CreateSymLink "%APPDATA%\Code\Session Storage" "%RAMDiskLetter%\Cache\Code\Session Storage"
  CALL :CreateSymLink "%APPDATA%\Code\WebStorage"      "%RAMDiskLetter%\Cache\Code\WebStorage"
)

IF EXIST "%APPDATA%\discord" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] Discord %ESC%[0m
  CALL :CreateSymLink "%APPDATA%\discord\Cache"           "%RAMDiskLetter%\Cache\discord\Cache"
  CALL :CreateSymLink "%APPDATA%\discord\CachedData"      "%RAMDiskLetter%\Cache\discord\CachedData"
  CALL :CreateSymLink "%APPDATA%\discord\Code Cache"      "%RAMDiskLetter%\Cache\discord\Code Cache"
  CALL :CreateSymLink "%APPDATA%\discord\GPUCache"        "%RAMDiskLetter%\Cache\discord\GPUCache"
  CALL :CreateSymLink "%APPDATA%\discord\Service Worker"  "%RAMDiskLetter%\Cache\discord\Service Worker"
  CALL :CreateSymLink "%APPDATA%\discord\Session Storage" "%RAMDiskLetter%\Cache\discord\Session Storage"
)

IF EXIST "%LOCALAPPDATA%\Steam\htmlcache" (
  @ECHO %ESC%[101;93m%ESC%[1L [Ramdisk] Steam %ESC%[0m
  CALL :CreateSymLink "%LOCALAPPDATA%\Steam\htmlcache\Cache"           "%RAMDiskLetter%\Cache\Steam\Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Steam\htmlcache\Code Cache"      "%RAMDiskLetter%\Cache\Steam\Code Cache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Steam\htmlcache\GPUCache"        "%RAMDiskLetter%\Cache\Steam\GPUCache"
  CALL :CreateSymLink "%LOCALAPPDATA%\Steam\htmlcache\Service Worker"  "%RAMDiskLetter%\Cache\Steam\Service Worker"
  CALL :CreateSymLink "%LOCALAPPDATA%\Steam\htmlcache\Session Storage" "%RAMDiskLetter%\Cache\Steam\Session Storage"
)

@ECHO.
timeout /T 10

GOTO :EOF

:: -------------------------------
:: Functions
:: -------------------------------

:: -------------------------------
:: function CreateSymLink
::
::     CreateSymLink(original folder, destination folder)
:: -------------------------------

:CreateSymLink

:: Remove both folders (the original and the destination)
RD /S /Q %1 2>NUL
RD /S /Q %2 2>NUL

:: Creates the folder and the link
MD %2 2>NUL
ECHO  - MKLINK /D %1 %2
MKLINK /D %1 %2 >NUL 2>NUL
fsutil reparsepoint query "%1" >NUL

GOTO :EOF

:: -------------------------------
:: function CopyPersistentDataFromTo
::
::     CopyPersistentDataFromTo(target folder, destination folder)
::
:: ex: %LOCALAPPDATA%/WRamdisk/persistent/APP/
:: -------------------------------

:CopyPersistentDataFromTo

:: Lets create the folders if they doesnt exist..

:: Check if "target folder" doesnt exists, then do nothing..
if not exist %1 ( 
  GOTO :EOF
)

:: Check if "destination folder" exists
if not exist %2 ( 
  MD %2 2>NUL
)

:: /E   => copiar subdiretórios, incluindo os vazios
:: /R:5 => número de Repetições em cópias com falhas = 5
:: /W:1 => tempo de espera entre as repetições = 1 segundo

robocopy %1 %2 /MIR /E /COPYALL /R:5 /W:1 >nul 2>nul

GOTO :EOF

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

ECHO.
VER|FIND "6.0">NUL&&(  ECHO   Windows Vista )
VER|FIND "6.1">NUL&&(  ECHO   Windows 7 )
VER|FIND "6.2">NUL&&(  ECHO   Windows 8 )
VER|FIND "10.0">NUL&&( ECHO   Windows 10/11 )
::@ECHO.    * Run as administrator.

:: FILL SCREEN
@ECHO %ESC%[101;93m%ESC%[2J%ESC%[0m

:: PRINT BANNER
@ECHO %ESC%[101;93m%ESC%[5L%ESC%[0m
@ECHO.
@ECHO %ESC%[101;93m    * Run as administrator.



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
PING 1.1.1.1 -n 10 -w 1000 >NUL
EXIT