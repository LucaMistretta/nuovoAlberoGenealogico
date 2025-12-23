# Configurazione Limiti Upload PHP

## Problema
I limiti di upload PHP di default sono troppo bassi (2MB). Questo documento spiega come aumentarli a 20MB.

## Soluzione Automatica

Esegui lo script fornito con privilegi sudo:

```bash
sudo ./fix-php-limits.sh
```

Lo script modificherà automaticamente:
- `upload_max_filesize` → 20M
- `post_max_size` → 25M  
- `memory_limit` → 256M

## Soluzione Manuale

Se preferisci modificare manualmente, apri il file php.ini:

```bash
sudo nano /etc/php/8.3/cli/php.ini
```

Cerca e modifica queste righe:

```ini
upload_max_filesize = 20M
post_max_size = 25M
memory_limit = 256M
max_execution_time = 300
```

**Nota**: Se usi anche PHP-FPM (con Apache/Nginx), modifica anche:
```bash
sudo nano /etc/php/8.3/fpm/php.ini
```

## Riavvio del Server

Dopo le modifiche, riavvia il server:

- **php artisan serve**: Interrompi (Ctrl+C) e riavvia con `php artisan serve`
- **Apache**: `sudo systemctl restart apache2`
- **Nginx + PHP-FPM**: `sudo systemctl restart php8.3-fpm`

## Verifica

Verifica che i limiti siano stati applicati:

```bash
php -i | grep -E "upload_max_filesize|post_max_size|memory_limit"
```

Dovresti vedere:
```
upload_max_filesize => 20M => 20M
post_max_size => 25M => 25M
memory_limit => 256M => 256M
```

## Modifiche Applicate nel Codice

Le seguenti modifiche sono già state applicate nel codice:

1. **bootstrap/app.php**: Aggiunti `ini_set()` per aumentare i limiti all'avvio (funziona solo se PHP lo permette)
2. **MediaController.php**: Validazione aumentata a 20MB (20480 KB)
3. **MediaGallery.vue**: Frontend aggiornato per accettare file fino a 20MB

**IMPORTANTE**: Le modifiche in `bootstrap/app.php` potrebbero non funzionare perché `upload_max_filesize` e `post_max_size` non possono essere modificati con `ini_set()` dopo l'avvio di PHP. È necessario modificare il `php.ini` del sistema.


