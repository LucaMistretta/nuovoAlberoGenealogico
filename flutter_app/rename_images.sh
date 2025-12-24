#!/bin/bash

# Script per rinominare i file delle immagini negli assets
# per corrispondere ai nomi nel database

DB_PATH="assets/database/agene.sqlite"
IMAGES_DIR="assets/images/media"

echo "🔄 Inizio rinomina immagini..."

# Verifica che il database esista
if [ ! -f "$DB_PATH" ]; then
    echo "❌ Database non trovato: $DB_PATH"
    exit 1
fi

# Verifica che la directory immagini esista
if [ ! -d "$IMAGES_DIR" ]; then
    echo "❌ Directory immagini non trovata: $IMAGES_DIR"
    exit 1
fi

# Conta i file da rinominare
TOTAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM media WHERE percorso IS NOT NULL AND percorso != '';" 2>/dev/null)
echo "📊 Trovati $TOTAL media nel database"

RENAMED=0
NOT_FOUND=0
ALREADY_OK=0

# Itera su tutti i media nel database
sqlite3 "$DB_PATH" "SELECT id, persona_id, percorso, nome_file FROM media WHERE percorso IS NOT NULL AND percorso != '';" | while IFS='|' read -r id persona_id percorso nome_file; do
    # Estrai il nome file dal percorso (es. media/persona_22/1766390257_6948f9f1e7540.jpg -> 1766390257_6948f9f1e7540.jpg)
    db_filename=$(basename "$percorso")
    
    # Costruisci il percorso completo del file negli assets
    persona_dir="$IMAGES_DIR/persona_$persona_id"
    db_file_path="$persona_dir/$db_filename"
    
    # Se il file con il nome del database esiste già, è OK
    if [ -f "$db_file_path" ]; then
        ALREADY_OK=$((ALREADY_OK + 1))
        continue
    fi
    
    # Cerca il file con il nome originale (nome_file)
    original_file_path="$persona_dir/$nome_file"
    
    if [ -f "$original_file_path" ]; then
        # Rinomina il file
        echo "📝 Rinomina: $nome_file -> $db_filename (persona_$persona_id)"
        mv "$original_file_path" "$db_file_path"
        RENAMED=$((RENAMED + 1))
    else
        # Cerca anche senza estensione o con estensioni diverse
        found=false
        for ext in .jpg .jpeg .JPG .JPEG .png .PNG; do
            test_file="${original_file_path%.*}$ext"
            if [ -f "$test_file" ]; then
                echo "📝 Rinomina: $(basename "$test_file") -> $db_filename (persona_$persona_id)"
                mv "$test_file" "$db_file_path"
                RENAMED=$((RENAMED + 1))
                found=true
                break
            fi
        done
        
        if [ "$found" = false ]; then
            echo "⚠️  File non trovato per media ID $id: $nome_file (cercato in persona_$persona_id)"
            NOT_FOUND=$((NOT_FOUND + 1))
        fi
    fi
done

echo ""
echo "✅ Rinomina completata!"
echo "   - File già corretti: $ALREADY_OK"
echo "   - File rinominati: $RENAMED"
echo "   - File non trovati: $NOT_FOUND"

