@echo off
setlocal
cd /d "%~dp0" || exit /b 1

set "PYTHON=.venv\Scripts\python.exe"
if not exist "%PYTHON%" (
    echo Python virtual environment not found. Create it with: python -m venv .venv 1>&2
    exit /b 1
)

"%PYTHON%" -m pip install -r requirements.txt
if errorlevel 1 exit /b 1

"%PYTHON%" -m pytest
if errorlevel 1 exit /b 1

exit /b 0
