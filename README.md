# Nuovo Albero Genealogico

Sistema di gestione genealogica completo sviluppato con Laravel e Vue.js 3.

## Caratteristiche Principali

### 👥 Gestione Persone
- **CRUD completo** per la gestione delle persone
- **Relazioni familiari** (padre, madre, coniugi, figli)
- **Ricerca avanzata** con filtri multipli
- **Ordinamento** per tutte le colonne
- **Visualizzazione albero genealogico** interattivo con D3.js
- **Grafico familiare** con zoom e pan

### 📸 Media Management
- Upload e gestione di **foto e documenti** associati alle persone
- Supporto per immagini, PDF e documenti
- Galleria multimediale integrata

### 📅 Timeline Eventi
- **Gestione eventi** della vita delle persone
- Tipi di evento predefiniti (nascita, battesimo, matrimonio, morte, ecc.)
- Timeline visuale con date e luoghi
- Note e descrizioni dettagliate

### 📝 Note e Tag
- **Note personalizzate** per ogni persona
- **Sistema di tag** per organizzare le persone
- Tag colorati per facile identificazione

### 🗺️ Mappe
- **Visualizzazione geografica** dei luoghi di nascita e morte
- Integrazione con OpenStreetMap
- Marker interattivi sulla mappa

### 📊 Report e Statistiche
- **Statistiche generali** sulla genealogia
- **Distribuzione per età**
- **Luoghi di nascita** più frequenti
- Grafici interattivi con Chart.js

### 🔍 Controllo Qualità Dati
- **Validazione automatica** dei dati
- Rilevamento di inconsistenze (date, relazioni)
- Report di qualità con dettagli degli errori

### 📤 Export/Import
- **Export GEDCOM** (formato standard genealogico)
- **Export CSV** per analisi dati
- **Export PDF** per documentazione
- **Import GEDCOM** per importare dati esistenti

### 👤 Sistema Multi-Utente
- **Gestione utenti** con ruoli (admin/user)
- **Autenticazione** con Laravel Sanctum
- **Permessi** basati sui ruoli

### 📋 Audit Log
- **Tracciamento** di tutte le modifiche
- Log delle operazioni CRUD
- Informazioni su utente, data e modifiche

### 💾 Backup Automatico
- **Backup automatico** del database
- Schedulazione giornaliera
- Comando Artisan per backup manuale

### 🌍 Internazionalizzazione
- Supporto per **6 lingue**: Italiano, Inglese, Francese, Tedesco, Spagnolo, Portoghese
- Traduzione completa dell'interfaccia
- Cambio lingua in tempo reale

## Tecnologie Utilizzate

### Backend
- **Laravel 12** - Framework PHP
- **SQLite** - Database
- **Laravel Sanctum** - Autenticazione API
- **D3.js** - Visualizzazione albero genealogico
- **Leaflet.js** - Mappe interattive

### Frontend
- **Vue.js 3.5** - Framework JavaScript
- **Vue Router** - Routing
- **Pinia** - State management
- **Tailwind CSS 4** - Styling
- **Chart.js** - Grafici e statistiche
- **Vite** - Build tool

## Installazione

### Prerequisiti
- PHP 8.2+
- Composer
- Node.js 18+
- npm o yarn

### Passi di Installazione

1. **Clona il repository**
```bash
git clone https://github.com/LucaMistretta/nuovoAlberoGenealogico.git
cd nuovoAlberoGenealogico
```

2. **Installa le dipendenze PHP**
```bash
composer install
```

3. **Installa le dipendenze JavaScript**
```bash
npm install
```

4. **Configura l'ambiente**
```bash
cp .env.example .env
php artisan key:generate
```

5. **Esegui le migrazioni e i seeder**
```bash
php artisan migrate
php artisan db:seed
```

6. **Crea il link simbolico per lo storage**
```bash
php artisan storage:link
```

7. **Compila gli asset**
```bash
npm run build
# oppure per sviluppo
npm run dev
```

8. **Avvia il server**
```bash
php artisan serve
```

L'applicazione sarà disponibile su `http://localhost:8000`

## Credenziali di Default

Dopo l'installazione, puoi accedere con:

**Utente Admin:**
- Email: `admin@example.com`
- Password: `password`

**Utente Normale:**
- Email: `user@example.com`
- Password: `password`

## Struttura del Progetto

```
nuovoAlberoGenealogico/
├── app/
│   ├── Console/Commands/      # Comandi Artisan
│   ├── Http/
│   │   ├── Controllers/API/  # Controller API
│   │   └── Resources/        # API Resources
│   ├── Models/               # Modelli Eloquent
│   ├── Services/              # Servizi business logic
│   └── Traits/                # Traits riutilizzabili
├── database/
│   ├── migrations/            # Migrazioni database
│   └── seeders/               # Seeder database
├── resources/
│   ├── js/
│   │   ├── components/       # Componenti Vue
│   │   ├── services/         # Servizi frontend
│   │   ├── stores/           # Store Pinia
│   │   └── views/            # Viste Vue
│   └── lang/                  # File di traduzione
└── routes/
    └── api.php                # Route API
```

## API Endpoints

### Autenticazione
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout (protetto)
- `GET /api/auth/user` - Utente corrente (protetto)

### Persone
- `GET /api/persone` - Lista persone (protetto)
- `GET /api/persone/{id}` - Dettaglio persona (protetto)
- `POST /api/persone` - Crea persona (protetto)
- `PUT /api/persone/{id}` - Aggiorna persona (protetto)
- `DELETE /api/persone/{id}` - Elimina persona (protetto)
- `GET /api/persone/{id}/family` - Famiglia persona (protetto)
- `GET /api/persone/tree` - Albero completo (protetto)

### Media
- `GET /api/persone/{personaId}/media` - Lista media (pubblico)
- `POST /api/persone/{personaId}/media` - Upload media (protetto)
- `DELETE /api/persone/{personaId}/media/{mediaId}` - Elimina media (protetto)

### Eventi
- `GET /api/persone/{personaId}/eventi` - Lista eventi (pubblico)
- `POST /api/persone/{personaId}/eventi` - Crea evento (protetto)
- `PUT /api/persone/{personaId}/eventi/{eventoId}` - Aggiorna evento (protetto)
- `DELETE /api/persone/{personaId}/eventi/{eventoId}` - Elimina evento (protetto)

### Note
- `GET /api/persone/{personaId}/note` - Lista note (pubblico)
- `POST /api/persone/{personaId}/note` - Crea nota (protetto)
- `PUT /api/persone/{personaId}/note/{notaId}` - Aggiorna nota (protetto)
- `DELETE /api/persone/{personaId}/note/{notaId}` - Elimina nota (protetto)

### Tag
- `GET /api/tags` - Lista tag (protetto)
- `POST /api/tags` - Crea tag (protetto)
- `POST /api/persone/{personaId}/tags` - Associa tag (protetto)
- `DELETE /api/persone/{personaId}/tags/{tagId}` - Rimuovi tag (protetto)

### Export/Import
- `GET /api/export/gedcom` - Export GEDCOM completo (protetto)
- `GET /api/export/gedcom/{personaId}` - Export GEDCOM persona (protetto)
- `GET /api/export/csv` - Export CSV (protetto)
- `POST /api/import/gedcom` - Import GEDCOM (protetto)

### Report
- `GET /api/report/statistiche` - Statistiche generali (protetto)
- `GET /api/report/distribuzione-eta` - Distribuzione età (protetto)
- `GET /api/report/luoghi-nascita` - Luoghi di nascita (protetto)

### Qualità Dati
- `GET /api/data-quality/check` - Controllo qualità (protetto)

### Utenti (solo admin)
- `GET /api/users` - Lista utenti
- `POST /api/users` - Crea utente
- `PUT /api/users/{id}` - Aggiorna utente
- `DELETE /api/users/{id}` - Elimina utente

### Audit Log (solo admin)
- `GET /api/audit-logs` - Lista log
- `GET /api/audit-logs/{id}` - Dettaglio log

## Comandi Utili

### Backup Database
```bash
php artisan db:backup
```

### Sviluppo
```bash
# Avvia server Laravel
php artisan serve

# Compila asset in modalità sviluppo
npm run dev

# Compila asset per produzione
npm run build
```

## Licenza

Questo progetto è open source e disponibile sotto la licenza MIT.

## Autore

Luca Mistretta

## Contributi

I contributi sono benvenuti! Per favore apri una issue o una pull request per suggerimenti o miglioramenti.
