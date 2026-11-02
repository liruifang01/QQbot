$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$exitCode = 0

try {
    Set-Location $projectPath
    $venvPython = Join-Path $projectPath '.venv\Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $venvPython)) {
        $pythonLauncher = Get-Command 'py' -ErrorAction SilentlyContinue
        if ($pythonLauncher) {
            $pythonCommand = $pythonLauncher.Source
            $pythonArguments = @('-3')
        } else {
            $pythonExecutable = Get-Command 'python' -ErrorAction SilentlyContinue
            if (-not $pythonExecutable) {
                throw 'Python was not found. Install Python 3.10 or later and enable the Python Launcher or add Python to PATH.'
            }
            $pythonCommand = $pythonExecutable.Source
            $pythonArguments = @()
        }
        & $pythonCommand @pythonArguments -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)"
        if ($LASTEXITCODE -ne 0) {
            throw 'Python 3.10 or later is required. Install Python 3.12 (recommended) and try again.'
        }
        & $pythonCommand @pythonArguments -m venv (Join-Path $projectPath '.venv')
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
