Write-Host "Preparing environment for Windows..." -ForegroundColor Cyan

# Function to clone if not exists
function Clone-If-Not-Exists {
    param (
        [string]$repoUrl,
        [string]$folderName
    )
    if (-not (Test-Path $folderName)) {
        Write-Host "Cloning $folderName..." -ForegroundColor Green
        git clone $repoUrl $folderName
    } else {
        Write-Host "$folderName directory already exists, skipping clone." -ForegroundColor Yellow
    }
}

Clone-If-Not-Exists "https://github.com/agb4455/ProyectoIntermodularDamBackend.git" "db_back"
Clone-If-Not-Exists "https://github.com/agb4455/ProyectoIntermodularDamFrontend.git" "front"
Clone-If-Not-Exists "https://github.com/adriangb46/ProyectoIntermodularDamServidorIntermedio.git" "middle_server"

Write-Host "`nInstalling dependencies for frontend..." -ForegroundColor Cyan
if (Test-Path "front") {
    Push-Location front
    npm install
    Pop-Location
}

Write-Host "`nInstalling dependencies for middle_server..." -ForegroundColor Cyan
if (Test-Path "middle_server") {
    Push-Location middle_server
    npm install
    Pop-Location
}

Write-Host "`nEnvironment preparation complete." -ForegroundColor Green
Read-Host "Press Enter to exit"
