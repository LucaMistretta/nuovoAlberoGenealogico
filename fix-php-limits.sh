#!/bin/bash

# Script per aumentare i limiti di upload PHP

PHP_INI_CLI="/etc/php/8.3/cli/php.ini"
PHP_INI_FPM="/etc/php/8.3/fpm/php.ini"

echo "Aumento dei limiti di upload PHP..."

# Funzione per modificare un php.ini
modify_php_ini() {
    local php_ini=$1
    if [ ! -f "$php_ini" ]; then
        echo "File $php_ini non trovato, salto..."
        return
    fi
    
    echo "Modifico $php_ini..."
    
    # Backup del file originale
    sudo cp "$php_ini" "${php_ini}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Modifica upload_max_filesize
    sudo sed -i 's/^upload_max_filesize\s*=.*/upload_max_filesize = 20M/' "$php_ini"
    
    # Modifica post_max_size (deve essere maggiore di upload_max_filesize)
    sudo sed -i 's/^post_max_size\s*=.*/post_max_size = 25M/' "$php_ini"
    
    # Modifica memory_limit se necessario
    sudo sed -i 's/^memory_limit\s*=.*/memory_limit = 256M/' "$php_ini"
    
    # Verifica se le modifiche sono state applicate
    if grep -q "^upload_max_filesize = 20M" "$php_ini"; then
        echo "✓ $php_ini modificato con successo"
    else
        echo "⚠ Potrebbe essere necessario aggiungere manualmente le righe in $php_ini:"
        echo "  upload_max_filesize = 20M"
        echo "  post_max_size = 25M"
        echo "  memory_limit = 256M"
    fi
}

# Modifica php.ini CLI (usato da php artisan serve)
modify_php_ini "$PHP_INI_CLI"

# Modifica php.ini FPM (se esiste, usato da Nginx/Apache con PHP-FPM)
if [ -f "$PHP_INI_FPM" ]; then
    modify_php_ini "$PHP_INI_FPM"
fi

echo ""
echo "Modifiche completate!"
echo ""
echo "Per applicare le modifiche:"
echo "  - Se usi 'php artisan serve': riavvia il comando artisan"
echo "  - Se usi Apache: sudo systemctl restart apache2"
echo "  - Se usi Nginx con PHP-FPM: sudo systemctl restart php8.3-fpm"
echo ""
echo "Verifica i limiti con: php -i | grep -E 'upload_max_filesize|post_max_size'"


