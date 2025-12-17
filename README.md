# Nuovo Albero Genealogico

Applicazione web completa per la gestione di alberi genealogici, sviluppata con Laravel (ultima versione stabile) e Vue.js 3.5.

## Caratteristiche

- **Database ristrutturato**: Struttura normalizzata con tabelle `persone`, `tipi_di_legame` e `persona_legami`
- **Sistema temi**: Tema scuro (default) e chiaro con persistenza
- **Internazionalizzazione**: Supporto per 6 lingue (IT, EN, FR, DE, ES, PT)
- **CRUD completo**: Gestione completa di persone e tipi di legame
- **Autenticazione**: Sistema di login/logout con Laravel Sanctum
- **Visualizzazione albero**: Componente per visualizzare l'albero genealogico

## Requisiti

- PHP 8.2+
- Composer
- Node.js 18+ e npm
- SQLite (o altro database supportato da Laravel)

## Installazione

1. **Installa dipendenze PHP:**
   ```bash
   composer install
   ```

2. **Installa dipendenze Node.js:**
   ```bash
   npm install
   ```

3. **Configura ambiente:**
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

4. **Esegui migration:**
   ```bash
   php artisan migrate
   ```

5. **Popola tipi di legame:**
   ```bash
   php artisan db:seed --class=TipiDiLegameSeeder
   ```

6. **Importa dati dal vecchio database (opzionale):**
   ```bash
   # Copia il file agene.sqlite dal vecchio progetto in database/agene.sqlite
   php artisan db:import-agene
   ```

7. **Crea utente admin:**
   ```bash
   php artisan tinker
   >>> \App\Models\User::create(['name' => 'Admin', 'email' => 'admin@example.com', 'password' => \Illuminate\Support\Facades\Hash::make('password')]);
   ```

8. **Avvia server:**
   ```bash
   # Terminal 1
   php artisan serve

   # Terminal 2
   npm run dev
   ```

## Accesso

- **URL**: http://localhost:8000
- **Email**: admin@example.com
- **Password**: password

## Struttura Database

### Tabelle

- **persone**: id, nome, cognome, nato_a, nato_il, deceduto_a, deceduto_il
- **tipi_di_legame**: id, nome, descrizione
- **persona_legami**: id, persona_id, persona_collegata_id, tipo_legame_id

## Tecnologie

- **Backend**: Laravel 11/12
- **Frontend**: Vue.js 3.5, Vue Router, Pinia
- **Styling**: Tailwind CSS 4
- **Build**: Vite
- **Autenticazione**: Laravel Sanctum

## Note

Il sistema di traduzioni è implementato in modo semplificato. Per un sistema più completo, considerare l'uso di vue-i18n.

