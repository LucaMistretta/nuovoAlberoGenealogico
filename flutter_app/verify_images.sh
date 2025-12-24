#!/bin/bash

# Script per verificare che le immagini siano incluse nell'APK

echo "Verifica immagini nell'APK..."
echo ""

APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"

if [ ! -f "$APK_PATH" ]; then
    echo "ERRORE: APK non trovato. Compila prima l'app con: flutter build apk --debug"
    exit 1
fi

echo "Controllo immagini nell'APK..."
echo ""

# Conta le immagini nell'APK
IMAGE_COUNT=$(unzip -l "$APK_PATH" 2>/dev/null | grep -E "assets/images.*\.(jpg|jpeg|png)" | wc -l)

echo "Immagini trovate nell'APK: $IMAGE_COUNT"
echo ""

# Mostra alcune immagini come esempio
echo "Prime 10 immagini nell'APK:"
unzip -l "$APK_PATH" 2>/dev/null | grep -E "assets/images.*\.(jpg|jpeg|png)" | head -10

echo ""
echo "Verifica completata!"

