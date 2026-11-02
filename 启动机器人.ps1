$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$exitCode = 0

try {
    Set-Location $projectPath
    $venvPython = Join-Path $projectPath '.venv\Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $venvPython)) {
        $systemPython = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'
        if (-not (Test-Path -LiteralPath $systemPython)) {
            throw 'Python 3.12 was not found. Install Python 3.10 or later first.'
        }
        & $systemPython -m venv (Join-Path $projectPath '.venv')
        if ($LASTEXITCODE -ne 0) {
            throw "Creating the Python virtual environment failed. Exit code: $LASTEXITCODE"
        }
        & $venvPython -m pip install -r (Join-Path $projectPath 'requirements.txt')
        if ($LASTEXITCODE -ne 0) {
            throw "Installing dependencies failed. Exit code: $LASTEXITCODE"
        }
    }

    Write-Host 'Starting the QQ bot...' -ForegroundColor Cyan
    & $venvPython (Join-Path $projectPath 'main.py')
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        Write-Host "The bot stopped with exit code: $exitCode" -ForegroundColor Red
    } else {
        Write-Host 'The bot stopped.' -ForegroundColor Yellow
    }
} catch {
    $exitCode = 1
    Write-Host "Startup failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Write-Host ''
    Read-Host 'Press Enter to close this window' | Out-Null
}

exit $exitCode
