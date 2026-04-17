@echo off
echo Preparing environment for Windows...

:: Clone db_back
if not exist "db_back\" (
    echo Cloning db_back...
    git clone https://github.com/agb4455/ProyectoIntermodularDamBackend.git db_back
) else (
    echo db_back directory already exists, skipping clone.
)

:: Clone front
if not exist "front\" (
    echo Cloning frontend...
    git clone https://github.com/agb4455/ProyectoIntermodularDamFrontend.git front
) else (
    echo front directory already exists, skipping clone.
)

:: Clone middle_server
if not exist "middle_server\" (
    echo Cloning middle_server...
    git clone https://github.com/adriangb46/ProyectoIntermodularDamServidorIntermedio.git middle_server
) else (
    echo middle_server directory already exists, skipping clone.
)

echo.
echo Installing dependencies for frontend...
cd front
call npm install
cd ..

echo.
echo Installing dependencies for middle_server...
cd middle_server
call npm install
cd ..

echo.
echo Environment preparation complete.
pause
