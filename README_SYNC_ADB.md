# Sincronizzazione USB ADB

## Come funziona

La sincronizzazione USB ADB permette di sincronizzare i dati tra il server Laravel e l'app Flutter Android senza bisogno di una connessione di rete, utilizzando solo il cavo USB.

## Prerequisiti

1. **ADB installato**: Android SDK Platform Tools devono essere installati sul server
2. **Dispositivo connesso**: Il dispositivo Android deve essere connesso via USB con il debug USB abilitato
3. **jq installato**: Necessario per il parsing JSON (`sudo apt install jq`)

## Flusso di lavoro

### 1. Esporta dati dall'app

1. Apri l'app Flutter sul dispositivo
2. Vai alla schermata **Sincronizzazione**
3. Seleziona la modalità **USB ADB**
4. Clicca su uno dei bottoni:
   - **Calcola Differenze**: Esporta i dati per vedere le differenze
   - **Push**: Esporta i dati per inviarli al server
   - **Pull**: Prepara l'app per ricevere dati dal server
   - **Merge**: Esporta i dati per unire con quelli del server

L'app esporterà i dati in `sync_data.json` nella directory dell'app.

### 2. Esegui lo script sul server

Dalla directory del progetto, esegui:

```bash
# Calcola le differenze
./sync_via_adb.sh diff

# Push: App → Server
./sync_via_adb.sh push

# Pull: Server → App
./sync_via_adb.sh pull

# Merge: Unisce dati da entrambi i lati
./sync_via_adb.sh merge
```

### 3. Importa dati nell'app (solo per Pull e Merge)

Dopo aver eseguito `pull` o `merge`, lo script copierà i dati sul dispositivo. Per importarli:

1. Apri l'app Flutter
2. Vai alla schermata **Sincronizzazione**
3. Seleziona modalità **USB ADB**
4. Clicca su **Pull** o **Merge** (l'app rileverà automaticamente i dati da importare)

## Struttura file

- **sync_data.json**: File esportato dall'app contenente tutti i dati locali
- **sync_result.json**: File con i dati dal server da importare nell'app

Questi file vengono gestiti automaticamente dallo script e dall'app.

## Risoluzione problemi

### "File di sync non trovato"
- Assicurati di aver esportato i dati dall'app prima di eseguire lo script
- Verifica che il dispositivo sia connesso: `adb devices`

### "ADB non trovato"
- Installa Android SDK Platform Tools
- Assicurati che `adb` sia nel PATH

### "Nessun dispositivo connesso"
- Verifica che il debug USB sia abilitato sul dispositivo
- Autorizza il computer sul dispositivo quando richiesto
- Prova: `adb kill-server && adb start-server`

### "jq non trovato"
- Installa jq: `sudo apt install jq` (Ubuntu/Debian) o `brew install jq` (macOS)

