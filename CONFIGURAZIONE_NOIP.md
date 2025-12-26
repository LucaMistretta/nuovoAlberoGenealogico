# Configurazione No-IP per Accesso Remoto

## Prerequisiti
1. Account No-IP creato su https://my.noip.com/
2. Hostname dinamico creato (es. `tuonome.ddns.net`)
3. Router con supporto Dynamic DNS

## Passi per Configurazione Router

### 1. Accedi al Router
- Indirizzo tipico: `http://192.168.1.1` o `http://192.168.0.1`
- Credenziali: solitamente su etichetta router o manuale

### 2. Configura Dynamic DNS
Cerca una sezione chiamata:
- **Dynamic DNS** o **DDNS**
- **No-IP** nelle opzioni provider

Inserisci:
- **Service Provider**: No-IP
- **Hostname**: `tuonome.ddns.net` (il tuo hostname No-IP)
- **Username**: Il tuo username No-IP
- **Password**: La tua password No-IP (o DDNS Key se disponibile)
- **Abilita**: Attiva il servizio

### 3. Configura Port Forwarding
Cerca sezione:
- **Port Forwarding** o **Virtual Server** o **NAT**

Crea nuova regola:
- **Nome**: Laravel Server
- **Porta Esterna**: 8000
- **Porta Interna**: 8000
- **IP Interno**: `192.168.1.6` (IP del PC con Laravel)
- **Protocollo**: TCP
- **Abilita**: Sì

### 4. Assegna IP Statico al PC
Nel router, sezione **DHCP Reservation** o **Static IP**:
- MAC Address del PC: (trovalo con `ipconfig /all` su Windows o `ip addr` su Linux)
- IP: `192.168.1.6`
- Salva

### 5. Verifica Firewall
Sul PC con Laravel:
- Windows: Apri porta 8000 nel Firewall di Windows
- Linux: `sudo ufw allow 8000/tcp`

## Test Configurazione

Dopo 5-10 minuti, prova:
```bash
# Da un dispositivo fuori dalla rete locale
curl http://tuonome.ddns.net:8000/api/sync/status
```

## Modelli Router Comuni

### TP-Link
1. Advanced → NAT Forwarding → Dynamic DNS
2. Seleziona No-IP
3. Inserisci credenziali

### Netgear
1. Advanced → Dynamic DNS
2. Seleziona No-IP
3. Inserisci credenziali

### ASUS
1. WAN → DDNS
2. Server: No-IP
3. Inserisci credenziali

### D-Link
1. Advanced → Dynamic DNS
2. Provider: No-IP
3. Inserisci credenziali

## Aggiornamento Manuale (se router non supporta DDNS)

Se il router non supporta DDNS, puoi usare il client No-IP:
1. Scarica No-IP DUC (Dynamic Update Client) da https://www.noip.com/download
2. Installa sul PC con Laravel
3. Configura con le tue credenziali No-IP

## Sicurezza

⚠️ **IMPORTANTE**: Per produzione:
- Usa HTTPS con certificato SSL
- Non esporre direttamente `php artisan serve`
- Usa un reverse proxy (nginx/Apache)
- Considera autenticazione aggiuntiva

## Troubleshooting

### Hostname non si aggiorna
- Verifica credenziali No-IP
- Controlla che il router supporti No-IP
- Prova con client DUC sul PC

### Porta non raggiungibile
- Verifica Port Forwarding
- Controlla firewall PC
- Verifica che Laravel sia in ascolto su `0.0.0.0:8000`

### IP cambia spesso
- Configura IP statico locale per il PC
- Verifica che DHCP reservation sia attiva

