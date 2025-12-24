# aGene - App Flutter Albero Genealogico

App Flutter per la gestione dell'albero genealogico, sincronizzata con l'applicazione web Laravel.

## Caratteristiche

- ✅ Autenticazione biometrica (impronte digitali)
- ✅ Database SQLite locale
- ✅ Lista persone con ricerca e filtri
- ✅ Gestione immagini locale
- ✅ Sincronizzazione opzionale con server Laravel (futura)

## Struttura del Progetto

```
flutter_app/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── core/                        # Core functionality
│   │   ├── database/                # Database SQLite helper
│   │   ├── api/                     # API client (futuro)
│   │   ├── auth/                    # Autenticazione
│   │   └── utils/                   # Utility
│   ├── data/                        # Data layer
│   │   ├── models/                  # Modelli dati
│   │   ├── repositories/            # Repository pattern
│   │   └── local/                   # DAO per SQLite
│   ├── domain/                      # Domain layer
│   │   └── entities/                # Entità di dominio
│   ├── presentation/                # UI layer
│   │   ├── screens/                 # Schermate
│   │   ├── widgets/                 # Widget riutilizzabili
│   │   └── providers/               # State management (Provider)
│   └── services/                    # Servizi
│       ├── biometric_service.dart   # Autenticazione biometrica
│       ├── sync_service.dart        # Sincronizzazione (futuro)
│       └── image_service.dart       # Gestione immagini
├── assets/
│   ├── database/                    # Database SQLite (da copiare)
│   └── images/                      # Immagini (da copiare)
└── android/                         # Configurazione Android
```

## Installazione

### Prerequisiti

- Flutter SDK (ultima versione stabile)
- Android Studio o VS Code con estensioni Flutter
- Database SQLite dal progetto Laravel

### Setup

1. **Installa le dipendenze:**
   ```bash
   flutter pub get
   ```

2. **Copia il database SQLite:**
   ```bash
   ./copy_database.sh
   ```
   
   Oppure manualmente:
   ```bash
   cp ../nuovoAlberoGenealogoco/database/agene.sqlite assets/database/
   cp -r ../nuovoAlberoGenealogoco/storage/app/public/* assets/images/
   ```

3. **Esegui l'app:**
   ```bash
   flutter run
   ```

## Configurazione Database

Il database SQLite viene copiato automaticamente dagli assets alla directory dell'app al primo avvio. Se il database non è presente negli assets, l'app cercherà di scaricarlo dal server (funzionalità futura).

## Autenticazione Biometrica

L'app supporta l'autenticazione tramite impronte digitali. Al primo login, viene chiesto se abilitare l'autenticazione biometrica per accessi futuri più rapidi.

## Sviluppo

### Aggiungere nuove funzionalità

1. **Nuova schermata:**
   - Crea il file in `lib/presentation/screens/`
   - Aggiungi il provider se necessario in `lib/presentation/providers/`

2. **Nuovo modello:**
   - Crea il file in `lib/data/models/`
   - Crea il DAO corrispondente in `lib/data/local/`
   - Aggiungi il repository in `lib/data/repositories/`

3. **Nuovo servizio:**
   - Crea il file in `lib/services/`

## Note

- L'app funziona principalmente in modalità offline
- La sincronizzazione con il server Laravel è pianificata per una versione futura
- Le immagini vengono copiate localmente per accesso offline

## Licenza

Questo progetto è parte del sistema aGene per la gestione dell'albero genealogico.
