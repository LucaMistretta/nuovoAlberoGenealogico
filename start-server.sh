#!/bin/bash

# Script per pulire tutte le cache e avviare il server Laravel
# su agene.localhost.local:8000

echo "🧹 Pulizia cache Laravel..."

# Pulisci tutte le cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan optimize:clear

echo "✅ Cache pulite!"

echo "🔨 Ricompilazione asset frontend..."
rm -rf public/build
npm run build

echo "✅ Asset ricompilati!"

echo "🚀 Avvio server su 0.0.0.0:8000 (accessibile dalla rete locale)..."
echo "   Accessibile su: http://localhost:8000"
echo "   Accessibile su: http://192.168.1.6:8000 (dalla rete locale)"
php artisan serve --host=0.0.0.0 --port=8000

