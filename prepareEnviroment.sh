#!/bin/bash

echo "Preparing environment..."

# Clone repositories if they don't exist
if [ ! -d "db_back" ]; then
    echo "Cloning db_back..."
    git clone https://github.com/agb4455/ProyectoIntermodularDamBackend.git db_back
else
    echo "db_back directory already exists, skipping clone."
fi

if [ ! -d "front" ]; then
    echo "Cloning front..."
    git clone https://github.com/agb4455/ProyectoIntermodularDamFrontend.git front
else
    echo "front directory already exists, skipping clone."
fi

if [ ! -d "middle_server" ]; then
    echo "Cloning middle_server..."
    git clone https://github.com/adriangb46/ProyectoIntermodularDamServidorIntermedio.git middle_server
else
    echo "middle_server directory already exists, skipping clone."
fi

echo ""
echo "Installing dependencies for frontend..."
cd front && npm install && cd ..

echo ""
echo "Installing dependencies for middle_server..."
cd middle_server && npm install && cd ..

echo ""
echo "Environment preparation complete."
