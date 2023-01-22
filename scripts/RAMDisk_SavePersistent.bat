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
::CLS

:: -------------------------------
:: Global Variable declarations
:: -------------------------------

set STARTDIR=%~dp0

:: FIX escape character \

set "STARTDIR=%STARTDIR:\=/%"

:: -------------------------------
:: Check settings.ini
:: -------------------------------

set RAMDiskAutoSave=FALSE
set RAMDiskPersistent=FALSE

setlocal enabledelayedexpansion

call :get-ini %STARTDIR%settings.ini settings persistent result

:: Trick to save %result% after the command "endlocal"
(
  endlocal
  set "RAMDiskPersistent=%result%"
)

setlocal enabledelayedexpansion

call :get-ini %STARTDIR%settings.ini settings autosave result

:: Trick to save %result% after the command "endlocal"
(
  endlocal
  set "RAMDiskAutoSave=%result%"
)

:: -------------------------------
:: Save Persistent Data from RAMDisk to SSD
:: -------------------------------

:: DEBUG
::echo RAMDiskAutoSave=%RAMDiskAutoSave%
::echo RAMDiskPersistent=%RAMDiskPersistent%
::timeout /t 1

IF /i "%RAMDiskAutoSave%"=="TRUE" ( CALL :CopyToPersistent )

IF /i "%RAMDiskPersistent%"=="TRUE" ( CALL :CopyToPersistent ) ELSE (
  @ECHO %ESC%[101;93m%ESC%[1L [RAMDisk] Save Persistent is disabled! %ESC%[0m
)

GOTO :EOF

:: -------------------------------
:: APPs
:: -------------------------------

:CopyToPersistent

@ECHO.

IF EXIST "%LOCALAPPDATA%\Google\Chrome\User Data\Default\" (
  @ECHO %ESC%[101;93m%ESC%[1L [Google Chrome] Copying persistent data.. %ESC%[0m
  CALL :CopyPersistentDataFromTo "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Network" "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Chrome\Network" >NUL
)

IF EXIST "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\" (
  @ECHO %ESC%[101;93m%ESC%[1L [Google Chrome Beta] Copying persistent data.. %ESC%[0m
  CALL :CopyPersistentDataFromTo "%LOCALAPPDATA%\Google\Chrome Beta\User Data\Default\Network" "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Chrome Beta\Network" >NUL
)

IF EXIST "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\" (
  @ECHO %ESC%[101;93m%ESC%[1L [Google Chrome Dev] Copying persistent data.. %ESC%[0m
  CALL :CopyPersistentDataFromTo "%LOCALAPPDATA%\Google\Chrome Dev\User Data\Default\Network" "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Chrome Dev\Network" >NUL
)

IF EXIST "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\" (
  @ECHO %ESC%[101;93m%ESC%[1L [Microsoft Edge] Copying persistent data.. %ESC%[0m
  CALL :CopyPersistentDataFromTo "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Network" "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Edge\Network" >NUL
)

IF EXIST "%LOCALAPPDATA%\Opera Software\Opera Stable" (
  @ECHO %ESC%[101;93m%ESC%[1L [Opera] Copying persistent data.. %ESC%[0m
  CALL :CopyPersistentDataFromTo "%APPDATA%\Opera Software\Opera Stable\Network" "%LOCALAPPDATA:\=/%/WRamdisk/persistent\Opera\Network" >NUL
)

IF EXIST "%LOCALAPPDATA%\Opera Software\Opera GX Stable" (
  @ECHO %ESC%[101;93m%ESC%[1L [Opera GX] Copying persistent data.. %ESC%[0m
  CALL :CopyPersistentDataFromTo "%APPDATA%\Opera Software\Opera GX Stable\Network" "%LOCALAPPDATA:\=/%/WRamdisk/persistent\OperaGX\Network" >NUL
)

IF EXIST "%LOCALAPPDATA%\Mozilla\Firefox\Profiles" (
  @ECHO %ESC%[101;93m%ESC%[1L [Mozilla Firefox] Copying persistent data.. %ESC%[0m
  REM  Nothing?
)

IF EXIST "%APPDATA%\Code" (
  REM @ECHO %ESC%[101;93m%ESC%[1L [VSCode] Copying persistent data.. %ESC%[0m
  REM  Nothing?
)

IF EXIST "%APPDATA%\discord" (
  REM @ECHO %ESC%[101;93m%ESC%[1L [Discord] Copying persistent data.. %ESC%[0m
  REM  Nothing?
)

@ECHO.

:: DEBUG
::timeout /T 10

GOTO :EOF

:: -------------------------------
:: Functions
:: -------------------------------

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

:EOF
EXIT