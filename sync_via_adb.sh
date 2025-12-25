#!/bin/bash

# Script per sincronizzazione bidirezionale tramite ADB
# Questo script trasferisce dati tra il server Laravel e l'app Flutter via USB ADB

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurazione
APP_PACKAGE="com.alberogenealogico.agene"
APP_DATA_DIR="/data/data/${APP_PACKAGE}/files"
SYNC_FILE_APP="/data/data/${APP_PACKAGE}/files/sync_data.json"
SYNC_FILE_SERVER="/tmp/adb_sync_data.json"
SYNC_RESULT_FILE_APP="/data/data/${APP_PACKAGE}/files/sync_result.json"
SYNC_RESULT_FILE_SERVER="/tmp/adb_sync_result.json"

# Funzione per verificare che ADB sia disponibile e il dispositivo connesso
check_adb() {
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}Errore: ADB non trovato. Installa Android SDK Platform Tools.${NC}"
        exit 1
    fi

    DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)
    if [ "$DEVICES" -eq 0 ]; then
        echo -e "${RED}Errore: Nessun dispositivo Android connesso via USB.${NC}"
        echo "Assicurati che:"
        echo "  1. Il dispositivo sia connesso via USB"
        echo "  2. Il debug USB sia abilitato"
        echo "  3. Il dispositivo sia autorizzato"
        exit 1
    fi

    echo -e "${GREEN}✓ Dispositivo Android trovato${NC}"
}

# Funzione per esportare dati dall'app
export_app_data() {
    echo -e "${YELLOW}📤 Esportazione dati dall'app...${NC}"
    
    # Verifica che il file esista sul dispositivo (l'app deve averlo creato)
    # Prova a copiare il file dal dispositivo al server
    if adb pull "${SYNC_FILE_APP}" "${SYNC_FILE_SERVER}" 2>/dev/null; then
        echo -e "${GREEN}✓ Dati esportati dall'app${NC}"
    else
        echo -e "${YELLOW}⚠ File di sync non trovato sull'app.${NC}"
        echo ""
        echo "Istruzioni:"
        echo "  1. Apri l'app Flutter sul dispositivo"
        echo "  2. Vai alla schermata Sincronizzazione"
        echo "  3. Seleziona modalità 'USB ADB'"
        echo "  4. Clicca 'Calcola Differenze' o uno dei bottoni di sincronizzazione"
        echo "  5. L'app esporterà i dati in sync_data.json"
        echo "  6. Poi esegui questo script: ./sync_via_adb.sh $1"
        echo ""
        exit 1
    fi
}

# Funzione per importare dati nell'app
import_app_data() {
    echo -e "${YELLOW}📥 Importazione dati nell'app...${NC}"
    
    if [ ! -f "$SYNC_RESULT_FILE_SERVER" ]; then
        echo -e "${RED}Errore: File di sync risultato non trovato${NC}"
        exit 1
    fi
    
    # Copia il file dal server al dispositivo
    adb push "${SYNC_RESULT_FILE_SERVER}" "${SYNC_RESULT_FILE_APP}" || {
        echo -e "${RED}Errore: Impossibile copiare dati sul dispositivo${NC}"
        exit 1
    }
    
    # Notifica l'app che i dati sono pronti
    adb shell "am broadcast -a com.alberogenealogico.agene.SYNC_DATA_READY" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Dati importati nell'app${NC}"
}

# Funzione per calcolare differenze
sync_diff() {
    echo -e "${YELLOW}🔍 Calcolo differenze...${NC}"
    
    # Esporta dati dall'app
    export_app_data
    
    # Chiama l'API Laravel per calcolare le differenze
    if [ -f "$SYNC_FILE_SERVER" ]; then
        # Prepara il JSON correttamente usando jq
        JSON_PAYLOAD=$(jq -n --slurpfile app_data "$SYNC_FILE_SERVER" '{app_data: $app_data[0], last_sync_timestamp: null}')
        
        RESPONSE=$(curl -s -X POST "http://localhost:8000/api/sync/diff" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$JSON_PAYLOAD")
        
        echo "$RESPONSE" | jq '.' || echo "$RESPONSE"
    else
        echo -e "${RED}Errore: File dati app non trovato${NC}"
        exit 1
    fi
}

# Funzione per push (App → Server)
sync_push() {
    echo -e "${YELLOW}⬆️  Sincronizzazione Push (App → Server)...${NC}"
    
    # Esporta dati dall'app
    export_app_data
    
    # Chiama l'API Laravel per push
    if [ -f "$SYNC_FILE_SERVER" ]; then
        # Prepara il JSON correttamente usando jq
        JSON_PAYLOAD=$(jq -n --slurpfile app_data "$SYNC_FILE_SERVER" '{app_data: $app_data[0], sync_mode: "adb"}')
        
        RESPONSE=$(curl -s -X POST "http://localhost:8000/api/sync/push-from-app" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$JSON_PAYLOAD")
        
        echo "$RESPONSE" | jq '.' || echo "$RESPONSE"
        
        if echo "$RESPONSE" | jq -e '.success == true' > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Push completato con successo${NC}"
        else
            echo -e "${RED}✗ Errore durante il push${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Errore: File dati app non trovato${NC}"
        exit 1
    fi
}

# Funzione per pull (Server → App)
sync_pull() {
    echo -e "${YELLOW}⬇️  Sincronizzazione Pull (Server → App)...${NC}"
    
    # Chiama l'API Laravel per pull
    RESPONSE=$(curl -s -X POST "http://localhost:8000/api/sync/pull-to-app" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "{\"last_sync_timestamp\": null}")
    
    # Salva la risposta in un file
    echo "$RESPONSE" | jq '.data' > "$SYNC_RESULT_FILE_SERVER" || {
        echo "$RESPONSE" > "$SYNC_RESULT_FILE_SERVER"
    }
    
    # Importa dati nell'app
    import_app_data
    
    echo -e "${GREEN}✓ Pull completato${NC}"
}

# Funzione per merge
sync_merge() {
    echo -e "${YELLOW}🔄 Sincronizzazione Merge...${NC}"
    
    # Esporta dati dall'app
    export_app_data
    
    # Chiama l'API Laravel per merge
    if [ -f "$SYNC_FILE_SERVER" ]; then
        APP_DATA=$(cat "$SYNC_FILE_SERVER")
        
        # Prepara il JSON correttamente
        JSON_PAYLOAD=$(jq -n --argjson app_data "$APP_DATA" '{app_data: $app_data, last_sync_timestamp: null}')
        
        RESPONSE=$(curl -s -X POST "http://localhost:8000/api/sync/merge" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$JSON_PAYLOAD")
        
        # Estrai i dati dal risultato e salvali
        if echo "$RESPONSE" | jq -e '.success == true' > /dev/null 2>&1; then
            echo "$RESPONSE" | jq '.data.data' > "$SYNC_RESULT_FILE_SERVER" 2>/dev/null || {
                echo "$RESPONSE" | jq '.data' > "$SYNC_RESULT_FILE_SERVER" 2>/dev/null || {
                    echo "$RESPONSE" > "$SYNC_RESULT_FILE_SERVER"
                }
            }
            
            # Importa dati nell'app
            import_app_data
            
            echo "$RESPONSE" | jq '.' || echo "$RESPONSE"
            echo -e "${GREEN}✓ Merge completato${NC}"
        else
            echo -e "${RED}✗ Errore durante il merge${NC}"
            echo "$RESPONSE" | jq '.' || echo "$RESPONSE"
            exit 1
        fi
    else
        echo -e "${RED}Errore: File dati app non trovato${NC}"
        exit 1
    fi
}

# Main
case "$1" in
    diff)
        check_adb
        sync_diff
        ;;
    push)
        check_adb
        sync_push
        ;;
    pull)
        check_adb
        sync_pull
        ;;
    merge)
        check_adb
        sync_merge
        ;;
    *)
        echo "Uso: $0 {diff|push|pull|merge}"
        echo ""
        echo "Comandi:"
        echo "  diff  - Calcola le differenze tra server e app"
        echo "  push  - Copia dati dall'app al server (App → Server)"
        echo "  pull  - Copia dati dal server all'app (Server → App)"
        echo "  merge - Unisce dati da entrambi i lati"
        exit 1
        ;;
esac

