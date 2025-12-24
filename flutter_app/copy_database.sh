#!/bin/bash

# Script per copiare il database SQLite e le immagini nell'app Flutter

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Percorsi
LARAVEL_DIR="../nuovoAlberoGenealogoco"
DB_SOURCE="$LARAVEL_DIR/database/agene.sqlite"
IMAGES_SOURCE="$LARAVEL_DIR/storage/app/public"
FLUTTER_ASSETS_DIR="assets/database"
FLUTTER_IMAGES_DIR="assets/images"

echo -e "${YELLOW}Copia database e immagini per Flutter app...${NC}"
echo ""

# Verifica che il database sorgente esista
if [ ! -f "$DB_SOURCE" ]; then
    echo -e "${RED}ERRORE: Database non trovato in $DB_SOURCE${NC}"
    exit 1
fi

# Crea le directory se non esistono
mkdir -p "$FLUTTER_ASSETS_DIR"
mkdir -p "$FLUTTER_IMAGES_DIR"

# Copia il database
echo -e "${GREEN}Copia database...${NC}"
cp "$DB_SOURCE" "$FLUTTER_ASSETS_DIR/agene.sqlite"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database copiato con successo${NC}"
else
    echo -e "${RED}✗ Errore nella copia del database${NC}"
    exit 1
fi

# Copia le immagini se la directory esiste
if [ -d "$IMAGES_SOURCE" ]; then
    echo -e "${GREEN}Copia immagini...${NC}"
    cp -r "$IMAGES_SOURCE"/* "$FLUTTER_IMAGES_DIR/" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Immagini copiate con successo${NC}"
    else
        echo -e "${YELLOW}⚠ Alcune immagini potrebbero non essere state copiate${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Directory immagini non trovata: $IMAGES_SOURCE${NC}"
fi

echo ""
echo -e "${GREEN}Completato!${NC}"
echo ""
echo "Prossimi passi:"
echo "1. Esegui 'flutter pub get' per installare le dipendenze"
echo "2. Esegui 'flutter run' per avviare l'app"

