@echo off
setlocal

REM Set variables
set SCRIPT_DIR=%~dp0
set PACKAGE_NAME=ConditionalDisplayers

REM --- Increment version ---
echo Running version increment...
set PWSH_SCRIPT=%SCRIPT_DIR%tools\increment-version.ps1
for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%PWSH_SCRIPT%" -ProjectRoot "%SCRIPT_DIR:~0,-1%"') do set "RAW_VERSION=%%i"

REM Clean up any potential whitespace from powershell output
for /f "tokens=*" %%a in ("%RAW_VERSION%") do set PACKAGE_VERSION=%%a

if not defined PACKAGE_VERSION (
    echo ERROR: Could not determine new package version.
    goto :error
)
echo New package version: %PACKAGE_VERSION%


set OUT_DIR=dist
set OUT_ZIP=%OUT_DIR%\%PACKAGE_NAME%-V8-%PACKAGE_VERSION%.zip
set TEMP_DIR=temp
set SRC_DIR=src

REM Clean up previous builds
if exist "%OUT_DIR%" rmdir /s /q "%OUT_DIR%"
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"

mkdir "%OUT_DIR%"
mkdir "%TEMP_DIR%"
mkdir "%TEMP_DIR%\App_Plugins\ConditionalDisplayers"
mkdir "%TEMP_DIR%\bin"


REM Restore nuget packages
call nuget restore "%SRC_DIR%\ConditionalDisplayers.sln"
if errorlevel 1 goto :error

REM Build the project for Release
call msbuild "%SRC_DIR%\ConditionalDisplayers.sln" /p:Configuration=Release /p:Platform="Any CPU"
if errorlevel 1 goto :error

REM Copy App_Plugins
xcopy /E /I /Y "%SRC_DIR%\App_Plugins\ConditionalDisplayers" "%TEMP_DIR%\App_Plugins\ConditionalDisplayers"

REM Copy DLL
copy "%SRC_DIR%\bin\Release\Our.Umbraco.ConditionalDisplayers.dll" "%TEMP_DIR%\bin\Our.Umbraco.ConditionalDisplayers.dll" /Y

REM Copy package.xml
copy "%SRC_DIR%\package.xml" "%TEMP_DIR%\package.xml" /Y

REM Create the zip
pushd %TEMP_DIR%
powershell -Command "Compress-Archive -Path * -DestinationPath ..\%OUT_ZIP% -Force"
popd

REM Clean up temp
rmdir /s /q "%TEMP_DIR%"

echo.
echo Package created: %OUT_ZIP%
echo.
goto :eof

:error
echo.
echo Build failed. Package not created.
echo.
endlocal
exit /b 1 