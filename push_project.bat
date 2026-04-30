@echo off
setlocal

rem Push the current project to GitHub.
rem Usage:
rem   push_project.bat
rem   push_project.bat "Your commit message"

set "REMOTE_URL=https://github.com/Quincysss/ProjectEscape.git"
set "BRANCH=main"

cd /d "%~dp0"

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo Error: This folder is not a Git repository.
    exit /b 1
)

git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo Adding origin remote: %REMOTE_URL%
    git remote add origin "%REMOTE_URL%"
) else (
    echo Updating origin remote: %REMOTE_URL%
    git remote set-url origin "%REMOTE_URL%"
)

for /f "delims=" %%B in ('git branch --show-current') do set "CURRENT_BRANCH=%%B"
if not "%CURRENT_BRANCH%"=="%BRANCH%" (
    echo Switching to branch: %BRANCH%
    git checkout -B "%BRANCH%"
    if errorlevel 1 exit /b 1
)

git add -A
if errorlevel 1 exit /b 1

git diff --cached --quiet
if errorlevel 1 (
    if "%~1"=="" (
        git commit -m "Capture current ProjectEscape workspace" ^
            -m "The workspace is being published to the project GitHub repository for remote backup and collaboration." ^
            -m "Constraint: Use the configured GitHub repository URL supplied by the project owner." ^
            -m "Confidence: high" ^
            -m "Scope-risk: narrow" ^
            -m "Tested: git add and commit path through this script" ^
            -m "Not-tested: Remote authentication and GitHub push permissions"
    ) else (
        git commit -m "%~1"
    )
    if errorlevel 1 exit /b 1
) else (
    echo No staged changes to commit.
)

echo Pushing to %REMOTE_URL% on branch %BRANCH%...
git push -u origin "%BRANCH%"
if errorlevel 1 exit /b 1

echo Done.
endlocal
