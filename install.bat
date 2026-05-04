@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  One-Click DeepSeek Reverse API Installer - Windows
::  https://github.com/chirag-gamer/one-click-deepseek-reverse
:: ============================================================
title One-Click DeepSeek Reverse API Installer

:: ANSI Colors for Windows 10+
for /f "tokens=2 delims==" %%a in ('wmic os get version /value ^| find "="') do set WIN_VER=%%a
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "CYAN=[96m"
set "BLUE=[94m"
set "RESET=[0m"
set "BOLD=[1m"

echo.
echo %CYAN%============================================================%RESET%
echo %BOLD%%CYAN%   One-Click DeepSeek Reverse API Installer (Windows)%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %YELLOW%This script will:%RESET%
echo   %GREEN%1.%RESET% Check/install Python 3.8+
echo   %GREEN%2.%RESET% Clone the DeepSeek Reverse API
echo   %GREEN%3.%RESET% Install all Python dependencies
echo   %GREEN%4.%RESET% Configure your DeepSeek account(s)
echo   %GREEN%5.%RESET% Start the local API server
echo.

:: ============================================================
:: CHECK ADMIN PRIVILEGES
:: ============================================================
set "ADMIN=0"
net session >nul 2>&1
if %errorlevel% equ 0 set "ADMIN=1"

if "%ADMIN%"=="0" (
    echo %YELLOW%[!] Not running as Administrator.%RESET%
    echo %YELLOW%[!] Python installation may require admin rights.%RESET%
    echo %YELLOW%[!] If Python is not found, please re-run as Administrator.%RESET%
    echo.
)

:: ============================================================
:: STEP 1: FIND OR INSTALL PYTHON
:: ============================================================
echo %BLUE%[Step 1/5] Checking Python installation...%RESET%

set "PYTHON_CMD="
set "PIP_CMD="
set "NEED_PYTHON=0"

:: Try python3 first, then python
where python3 >nul 2>&1
if %errorlevel% equ 0 (
    set "PYTHON_CMD=python3"
    set "PIP_CMD=pip3"
) else (
    where python >nul 2>&1
    if %errorlevel% equ 0 (
        set "PYTHON_CMD=python"
        set "PIP_CMD=pip"
    ) else (
        set "NEED_PYTHON=1"
    )
)

if "%NEED_PYTHON%"=="0" (
    :: Verify Python version >= 3.8
    for /f "tokens=2" %%v in ('%PYTHON_CMD% --version 2^>^&1') do set "PY_VER=%%v"
    for /f "tokens=1,2 delims=." %%a in ("!PY_VER!") do (
        set "PY_MAJOR=%%a"
        set "PY_MINOR=%%b"
    )
    if !PY_MAJOR! lss 3 (
        set "NEED_PYTHON=1"
    ) else if !PY_MAJOR! equ 3 (
        if !PY_MINOR! lss 8 set "NEED_PYTHON=1"
    )

    if "!NEED_PYTHON!"=="0" (
        echo %GREEN%[v] Python !PY_VER! found at: !PYTHON_CMD!%RESET%

        :: Verify pip
        !PYTHON_CMD! -m pip --version >nul 2>&1
        if !errorlevel! neq 0 (
            echo %YELLOW%[!] pip not found, attempting to install...%RESET%
            !PYTHON_CMD! -m ensurepip --upgrade 2>nul
            if !errorlevel! neq 0 (
                echo %RED%[X] Failed to install pip. Please install Python manually from https://python.org%RESET%
                pause
                exit /b 1
            )
        )
        echo %GREEN%[v] pip is available%RESET%
    ) else (
        echo %YELLOW%[!] Python version !PY_VER! is too old (need 3.8+)%RESET%
        set "NEED_PYTHON=1"
    )
)

if "%NEED_PYTHON%"=="1" (
    echo %YELLOW%[!] Python 3.8+ not found. Attempting to install...%RESET%

    :: Try winget first
    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        echo %CYAN%[*] Installing Python via winget...%RESET%
        winget install --id Python.Python.3.11 -e --accept-source-agreements --accept-package-agreements --silent
        if !errorlevel! equ 0 (
            echo %GREEN%[v] Python installed via winget.%RESET%
            echo %YELLOW%[!] You may need to restart this script or open a new terminal for PATH changes.%RESET%
            echo %YELLOW%[!] Please close and re-open this script, or run: refrenv%RESET%
        ) else (
            echo %RED%[X] winget install failed.%RESET%
            goto :manual_python
        )

        :: Try to find python after winget install
        where python >nul 2>&1
        if !errorlevel! equ 0 (
            set "PYTHON_CMD=python"
            set "PIP_CMD=pip"
        ) else (
            where python3 >nul 2>&1
            if !errorlevel! equ 0 (
                set "PYTHON_CMD=python3"
                set "PIP_CMD=pip3"
            ) else (
                echo %RED%[X] Python not found after install. Trying common paths...%RESET%
                for %%p in (
                    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
                    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
                    "C:\Python311\python.exe"
                    "C:\Python312\python.exe"
                    "%ProgramFiles%\Python311\python.exe"
                    "%ProgramFiles%\Python312\python.exe"
                ) do (
                    if exist %%p (
                        set "PYTHON_CMD=%%p"
                        set "PIP_CMD=%%p -m pip"
                        goto :found_python
                    )
                )
                goto :manual_python
            )
        )
        goto :found_python
    ) else (
        :manual_python
        echo.
        echo %RED%========================================%RESET%
        echo %RED%  Python could not be installed automatically.%RESET%
        echo %RED%  Please install Python manually:%RESET%
        echo %RED%  1. Go to: https://python.org/downloads/%RESET%
        echo %RED%  2. Download Python 3.11 or newer%RESET%
        echo %RED%  3. CHECK "Add Python to PATH" during install%RESET%
        echo %RED%  4. Re-run this script after installation%RESET%
        echo %RED%========================================%RESET%
        echo.
        pause
        exit /b 1
    )
)

:found_python
echo.

:: ============================================================
:: STEP 2: CLONE REPOSITORY
:: ============================================================
echo %BLUE%[Step 2/5] Cloning DeepSeek Reverse API...%RESET%

set "REPO_DIR=%~dp0deepseek-reverse-api"

if exist "%REPO_DIR%\.git" (
    echo %GREEN%[v] Repository already exists, skipping clone.%RESET%
) else if exist "%REPO_DIR%" (
    echo %YELLOW%[!] Directory exists but not a git repo. Removing...%RESET%
    rmdir /s /q "%REPO_DIR%" 2>nul
    goto :clone_repo
) else (
    :clone_repo
    where git >nul 2>&1
    if !errorlevel! equ 0 (
        echo %CYAN%[*] Cloning with git...%RESET%
        git clone https://github.com/Wu-jiyan/deepseek-reverse-api.git "%REPO_DIR%"
        if !errorlevel! neq 0 (
            echo %RED%[X] Git clone failed. Trying curl fallback...%RESET%
            goto :curl_fallback
        )
    ) else (
        :curl_fallback
        echo %CYAN%[*] Git not found. Downloading with PowerShell...%RESET%
        powershell -Command "Invoke-WebRequest -Uri https://github.com/Wu-jiyan/deepseek-reverse-api/archive/refs/heads/main.zip -OutFile '%TEMP%\deepseek-main.zip'" 2>nul
        if exist "%TEMP%\deepseek-main.zip" (
            echo %CYAN%[*] Extracting...%RESET%
            powershell -Command "Expand-Archive -Path '%TEMP%\deepseek-main.zip' -DestinationPath '%TEMP%\deepseek-extract' -Force" 2>nul
            if exist "%TEMP%\deepseek-extract\deepseek-reverse-api-main" (
                move "%TEMP%\deepseek-extract\deepseek-reverse-api-main" "%REPO_DIR%" >nul 2>&1
                del "%TEMP%\deepseek-main.zip" 2>nul
                rmdir /s /q "%TEMP%\deepseek-extract" 2>nul
            ) else (
                echo %RED%[X] Download/Extract failed. Please install git and try again.%RESET%
                pause
                exit /b 1
            )
        ) else (
            echo %RED%[X] Download failed. Check your internet connection.%RESET%
            pause
            exit /b 1
        )
    )
)
echo %GREEN%[v] Repository ready.%RESET%
echo.

:: ============================================================
:: STEP 3: INSTALL PYTHON DEPENDENCIES
:: ============================================================
echo %BLUE%[Step 3/5] Installing Python dependencies...%RESET%

cd /d "%REPO_DIR%"

if not exist "%REPO_DIR%\requirements.txt" (
    echo %RED%[X] requirements.txt not found! Repository may be incomplete.%RESET%
    pause
    exit /b 1
)

echo %CYAN%[*] Installing packages (this may take a few minutes)...%RESET%
%PYTHON_CMD% -m pip install --upgrade pip >nul 2>&1
%PYTHON_CMD% -m pip install -r requirements.txt

if !errorlevel! neq 0 (
    echo %RED%[X] Dependency installation failed!%RESET%
    echo %YELLOW%[!] Try running: %PYTHON_CMD% -m pip install -r requirements.txt%RESET%
    pause
    exit /b 1
)
echo %GREEN%[v] All dependencies installed successfully.%RESET%
echo.

:: ============================================================
:: STEP 4: CONFIGURE ACCOUNTS
:: ============================================================
echo %BLUE%[Step 4/5] Configuring DeepSeek accounts...%RESET%
echo.
echo %YELLOW%Please provide your DeepSeek account credentials.%RESET%
echo %YELLOW%(Email and password used at https://chat.deepseek.com)%RESET%
echo.

set "TOKEN_LIST="
set "ACCOUNT_COUNT=0"

:ask_account
set /a ACCOUNT_COUNT+=1
echo %CYAN%============================================%RESET%
echo %CYAN%  Account #!ACCOUNT_COUNT!%RESET%
echo %CYAN%============================================%RESET%

:ask_email
set "USER_EMAIL="
set /p "USER_EMAIL=Enter DeepSeek Email: "
if "!USER_EMAIL!"=="" (
    echo %RED%[X] Email cannot be empty.%RESET%
    goto :ask_email
)

:ask_password
set "USER_PASSWORD="
powershell -Command "$pwd = Read-Host 'Enter DeepSeek Password' -AsSecureString; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd); [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)" > "%TEMP%\ds_pwd.txt" 2>nul
set /p USER_PASSWORD=<"%TEMP%\ds_pwd.txt"
del "%TEMP%\ds_pwd.txt" 2>nul

if "!USER_PASSWORD!"=="" (
    echo %RED%[X] Password cannot be empty.%RESET%
    goto :ask_password
)

echo.
echo %CYAN%[*] Logging in and fetching token...%RESET%

:: Login and capture token
set "LOGIN_SCRIPT=import sys; sys.path.insert(0, '%REPO_DIR%'); from deepseek_ai.account_register import register_account_auto; result = register_account_auto('!USER_EMAIL!', '!USER_PASSWORD!'); print(result.token if result.success else '', end=''); sys.stderr.write(result.error or '')"
set "TOKEN_FILE=%TEMP%\ds_token.txt"
%PYTHON_CMD% -c "!LOGIN_SCRIPT!" >"!TOKEN_FILE!" 2>&1
set /p NEW_TOKEN=<"!TOKEN_FILE!"
del "!TOKEN_FILE!" 2>nul

if "!NEW_TOKEN!"=="" (
    echo %RED%[X] Login failed. Check your email and password.%RESET%
    set /p "RETRY=Retry this account? (y/n): "
    if /i "!RETRY!"=="y" goto :ask_email
) else (
    echo %GREEN%[v] Token obtained successfully for !USER_EMAIL!%RESET%

    if "!TOKEN_LIST!"=="" (
        set "TOKEN_LIST=!NEW_TOKEN!"
    ) else (
        set "TOKEN_LIST=!TOKEN_LIST!,!NEW_TOKEN!"
    )
)

echo.

:: Ask if more accounts
set /p "MORE_ACCOUNTS=Add another DeepSeek account? (y/n): "
if /i "!MORE_ACCOUNTS!"=="y" goto :ask_account

if "!TOKEN_LIST!"=="" (
    echo %RED%[X] No tokens obtained. Cannot continue.%RESET%
    pause
    exit /b 1
)

echo.
echo %GREEN%[v] Successfully configured !ACCOUNT_COUNT! account(s).%RESET%

:: ============================================================
:: STEP 4b: CREATE .ENV FILE
:: ============================================================
echo %CYAN%[*] Creating .env configuration...%RESET%

> "%REPO_DIR%\.env" (
    echo # DeepSeek AI Reverse API Configuration
    echo # Generated by one-click-deepseek-reverse installer
    echo.
    echo DEEPSEEK_TOKENS=!TOKEN_LIST!
    echo.
    echo PORT=8000
    echo HOST=0.0.0.0
    echo.
    echo AUTO_DELETE_SESSION=false
    echo TOKEN_STRATEGY=round_robin
    echo.
    echo LOG_LEVEL=INFO
)
echo %GREEN%[v] .env file created.%RESET%
echo.

:: ============================================================
:: STEP 5: START SERVER
:: ============================================================
echo %BLUE%[Step 5/5] Starting the DeepSeek API server...%RESET%
echo.
echo %GREEN%============================================================%RESET%
echo %GREEN%  Server starting at http://localhost:8000%RESET%
echo %GREEN%  Health check:  http://localhost:8000/health%RESET%
echo %GREEN%  API endpoint:  http://localhost:8000/v1/chat/completions%RESET%
echo %GREEN%  Models list:  http://localhost:8000/v1/models%RESET%
echo %GREEN%============================================================%RESET%
echo.
echo %YELLOW%Press Ctrl+C to stop the server.%RESET%
echo.

cd /d "%REPO_DIR%"
%PYTHON_CMD% start_server.py

echo.
echo %YELLOW%Server stopped. Rerun the script to restart.%RESET%
pause
endlocal
