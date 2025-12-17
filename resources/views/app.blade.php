<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ config('app.name', 'Nuovo Albero Genealogico') }}</title>
    
    <!-- Script inline per applicare il tema PRIMA del caricamento del CSS -->
    <script>
        (function() {
            const theme = localStorage.getItem('theme');
            const html = document.documentElement;
            
            // Se il tema salvato è 'light', rimuovi la classe dark
            // Se è 'dark' o non esiste, aggiungi la classe dark (default)
            if (theme === 'light') {
                html.classList.remove('dark');
                html.removeAttribute('data-theme');
            } else {
                html.classList.add('dark');
                html.setAttribute('data-theme', 'dark');
            }
        })();
    </script>
    
    @vite(['resources/js/app.js'])
</head>
<body>
    <div id="app"></div>
</body>
</html>

