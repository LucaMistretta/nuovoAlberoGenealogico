@echo off
echo Avvio server Laravel e Vite con XAMPP...
echo.

REM Verifica se PHP di XAMPP esiste
if exist "C:\xampp\php\php.exe" (
    set PHP_PATH=C:\xampp\php\php.exe
) else (
    echo ERRORE: PHP non trovato in C:\xampp\php\php.exe
    echo Verifica che XAMPP sia installato o modifica lo script con il percorso corretto.
    pause
    exit /b 1
)

REM Avvia Laravel sulla porta 8000 in una nuova finestra
start "Laravel Server" cmd /k "%PHP_PATH% artisan serve --port=8000"

REM Attendi 2 secondi prima di avviare Vite
timeout /t 2 /nobreak >nul

REM Avvia Vite in una nuova finestra
start "Vite Dev Server" cmd /k "npm run dev"

echo.
echo Server avviati!
echo - Laravel: http://localhost:8000
echo - Vite: http://localhost:5173
echo.
echo Premi un tasto per chiudere questa finestra...
pause >nul

