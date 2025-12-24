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

echo "🚀 Avvio server su agene.localhost.local:8000..."
php artisan serve --host=agene.localhost.local --port=8000

