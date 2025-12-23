# Installazione Estensione PHP GD per Compressione Immagini

Per abilitare la compressione automatica delle immagini, è necessario installare l'estensione PHP GD.

## Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install php-gd
# Per PHP 8.3 specificamente:
sudo apt-get install php8.3-gd
```

**Riavvio del server:**
- Se usi `php artisan serve`: **NON serve riavviare**, basta riavviare il comando artisan
- Se usi Apache: `sudo systemctl restart apache2`
- Se usi Nginx con PHP-FPM: `sudo systemctl restart php-fpm` o `sudo systemctl restart php8.3-fpm`
- Se usi XAMPP: riavvia XAMPP dal pannello di controllo

## CentOS/RHEL

```bash
sudo yum install php-gd
# Riavvia il server web appropriato
```

## Verifica Installazione

Dopo l'installazione, verifica che GD sia disponibile:

```bash
php -m | grep -i gd
```

Oppure:

```bash
php -r "echo extension_loaded('gd') ? 'GD disponibile' : 'GD non disponibile';"
```

Per verificare le funzionalità supportate:

```bash
php -r "\$info = gd_info(); print_r(\$info);"
```

## Funzionalità

Una volta installata l'estensione GD, il sistema comprimerà automaticamente le immagini caricate che superano i 2MB, mantenendo una buona qualità visiva.

- **Limite upload**: 10MB
- **Compressione automatica**: fino a 2MB (limite PHP)
- **Formati supportati**: JPEG, PNG, GIF, WebP
- **Ridimensionamento automatico**: max 1920x1920px (mantiene proporzioni)

