@echo off
setlocal

REM Set variables
set PACKAGE_NAME=ConditionalDisplayers
set PACKAGE_VERSION=3.0.1
set OUT_ZIP=%PACKAGE_NAME%-V8-%PACKAGE_VERSION%.zip
set TEMP_DIR=V8_PackageTemp
set ROOT_DIR=%~dp0..\

REM Clean up any previous temp
rmdir /s /q %TEMP_DIR% 2>nul
mkdir %TEMP_DIR%\App_Plugins\ConditionalDisplayers
mkdir %TEMP_DIR%\bin

REM Build the project for net472
call dotnet build "%ROOT_DIR%ConditionalDisplayers\ConditionalDisplayers.csproj" --configuration Release --framework net472
if errorlevel 1 goto :error

REM Copy App_Plugins
xcopy /E /I /Y "%ROOT_DIR%ConditionalDisplayers\App_Plugins\ConditionalDisplayers" "%TEMP_DIR%\App_Plugins\ConditionalDisplayers"

REM Copy DLL
copy "%ROOT_DIR%ConditionalDisplayers\bin\Release\net472\Our.Umbraco.ConditionalDisplayers.dll" "%TEMP_DIR%\bin\Our.Umbraco.ConditionalDisplayers.dll" /Y

REM Copy package-v8.xml as package.xml
copy "%ROOT_DIR%package-v8.xml" "%TEMP_DIR%\package.xml" /Y

REM Create the zip
pushd %TEMP_DIR%
if exist "..\..\%OUT_ZIP%" del "..\..\%OUT_ZIP%"
powershell -Command "Compress-Archive -Path * -DestinationPath ..\..\%OUT_ZIP% -Force"
popd

REM Clean up temp
rmdir /s /q %TEMP_DIR%

echo Package created: %OUT_ZIP%
goto :eof

:error
echo Build failed. Package not created.
endlocal
exit /b 1 