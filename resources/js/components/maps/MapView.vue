<template>
    <div v-if="!noWrapper" class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4 flex flex-col h-full w-full" :style="{ maxHeight: maxHeight }">
        <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2 flex-shrink-0">
            <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            {{ t('maps.title') }}
            <span v-if="loading" class="text-xs text-gray-500 dark:text-gray-400 ml-2">
                ({{ processedCount }}/{{ totalCount }})
            </span>
        </h3>
        <div v-if="loading" class="mb-2 flex-shrink-0">
            <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div 
                    class="bg-blue-600 h-2 rounded-full transition-all duration-300" 
                    :style="{ width: progressPercentage + '%' }"
                ></div>
            </div>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">
                Geocodifica luoghi in corso... {{ processedCount }} di {{ totalCount }}
            </p>
        </div>
        <div v-if="errorMessage || failedLuoghi.length > 0" class="mb-2 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg flex-shrink-0">
            <p v-if="errorMessage" class="text-sm font-semibold text-red-800 dark:text-red-300 mb-2">{{ errorMessage }}</p>
            <div v-if="failedLuoghi.length > 0">
                <p class="text-sm font-semibold text-red-800 dark:text-red-300 mb-1">
                    Luoghi non trovati ({{ failedLuoghi.length }}):
                </p>
                <ul class="text-xs text-red-700 dark:text-red-400 space-y-1">
                    <li v-for="(luogo, index) in failedLuoghi" :key="index" class="flex items-start gap-2">
                        <span class="font-medium">•</span>
                        <span>
                            <strong>{{ luogo.nome || luogo.luogo }}</strong>
                            <span v-if="luogo.motivo" class="text-red-600 dark:text-red-500"> - {{ luogo.motivo }}</span>
                        </span>
                    </li>
                </ul>
            </div>
        </div>
        <div v-if="!mapInitialized && !errorMessage" class="mb-2 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg flex-shrink-0">
            <p class="text-sm text-blue-800 dark:text-blue-300">Inizializzazione mappa in corso...</p>
        </div>
        <div ref="mapContainer" class="w-full flex-1 min-h-0 rounded-lg border border-gray-200 dark:border-gray-600"></div>
    </div>
    <div v-else class="h-full w-full flex flex-col">
        <div v-if="loading" class="mb-2 flex-shrink-0">
            <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div 
                    class="bg-blue-600 h-2 rounded-full transition-all duration-300" 
                    :style="{ width: progressPercentage + '%' }"
                ></div>
            </div>
            <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">
                Geocodifica luoghi in corso... {{ processedCount }} di {{ totalCount }}
            </p>
        </div>
        <div v-if="errorMessage || failedLuoghi.length > 0" class="mb-2 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg flex-shrink-0">
            <p v-if="errorMessage" class="text-sm font-semibold text-red-800 dark:text-red-300 mb-2">{{ errorMessage }}</p>
            <div v-if="failedLuoghi.length > 0">
                <p class="text-sm font-semibold text-red-800 dark:text-red-300 mb-1">
                    Luoghi non trovati ({{ failedLuoghi.length }}):
                </p>
                <ul class="text-xs text-red-700 dark:text-red-400 space-y-1">
                    <li v-for="(luogo, index) in failedLuoghi" :key="index" class="flex items-start gap-2">
                        <span class="font-medium">•</span>
                        <span>
                            <strong>{{ luogo.nome || luogo.luogo }}</strong>
                            <span v-if="luogo.motivo" class="text-red-600 dark:text-red-500"> - {{ luogo.motivo }}</span>
                        </span>
                    </li>
                </ul>
            </div>
        </div>
        <div v-if="!mapInitialized && !errorMessage" class="mb-2 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg flex-shrink-0">
            <p class="text-sm text-blue-800 dark:text-blue-300">Inizializzazione mappa in corso...</p>
        </div>
        <div ref="mapContainer" class="w-full flex-1 min-h-0 rounded-lg border border-gray-200 dark:border-gray-600"></div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch, nextTick } from 'vue';
import { useLocaleStore } from '../../stores/locale';
import api from '../../services/api';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const props = defineProps({
    luoghi: {
        type: Array,
        default: () => [],
    },
    maxHeight: {
        type: String,
        default: '680px',
    },
    noWrapper: {
        type: Boolean,
        default: false,
    },
});

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

const mapContainer = ref(null);
let map = null;
let markers = [];
let resizeHandler = null;
const loading = ref(false);
const processedCount = ref(0);
const totalCount = ref(0);
const errorMessage = ref('');
const mapInitialized = ref(false);
const failedLuoghi = ref([]);

const progressPercentage = computed(() => {
    if (totalCount.value === 0) return 0;
    return Math.round((processedCount.value / totalCount.value) * 100);
});

// Fix per icone Leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
});

const initMap = () => {
    if (!mapContainer.value) {
        errorMessage.value = 'Container mappa non trovato';
        return;
    }
    
    if (map) {
        return; // Mappa già inizializzata
    }

    try {
        errorMessage.value = '';
        
        // Inizializza la mappa con OpenStreetMap
        map = L.map(mapContainer.value).setView([41.9028, 12.4964], 6); // Centrato sull'Italia

        // Aggiungi il layer di OpenStreetMap
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            maxZoom: 19,
            tileSize: 256,
            zoomOffset: 0,
        }).addTo(map);

        mapInitialized.value = true;

        // Aggiorna i marker dopo che la mappa è inizializzata e la mappa si è ridimensionata
        setTimeout(() => {
            if (map) {
                map.invalidateSize(); // Forza il ridimensionamento della mappa
            }
            updateMarkers();
        }, 200);
    } catch (error) {
        console.error('Errore nell\'inizializzazione della mappa:', error);
        errorMessage.value = `Errore nell'inizializzazione della mappa: ${error.message}`;
        mapInitialized.value = false;
    }
};

const formatDate = (dateString) => {
    if (!dateString) return '';
    try {
        const date = new Date(dateString);
        if (isNaN(date.getTime())) return dateString;
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    } catch (e) {
        return dateString;
    }
};

const updateMarkers = async () => {
    if (!map || !mapContainer.value) {
        console.warn('Mappa non ancora inizializzata, in attesa...');
        // Se la mappa non è ancora inizializzata, riprova dopo un breve delay
        setTimeout(() => {
            if (map) {
                updateMarkers();
            }
        }, 500);
        return;
    }

    // Rimuovi marker esistenti
    markers.forEach(marker => map.removeLayer(marker));
    markers = [];

    if (!props.luoghi || props.luoghi.length === 0) {
        loading.value = false;
        processedCount.value = 0;
        totalCount.value = 0;
        return;
    }

    // Geocodifica i luoghi e aggiungi marker
    const bounds = [];
    const luoghiFiltrati = props.luoghi.filter(luogo => luogo.luogo && luogo.luogo !== '0' && luogo.luogo !== '');
    
    loading.value = true;
    processedCount.value = 0;
    totalCount.value = luoghiFiltrati.length;
    failedLuoghi.value = []; // Reset lista luoghi falliti
    
    // Funzione helper per fare una richiesta con retry usando l'API backend
    const geocodeWithRetry = async (luogo, retries = 2) => {
        for (let i = 0; i <= retries; i++) {
            try {
                // Aggiungi delay solo per retry (non per la prima richiesta se è in cache)
                if (i > 0) {
                    await new Promise(resolve => setTimeout(resolve, 1000 * i)); // Delay crescente per retry
                }
                
                // Usa l'API backend che gestisce il cache
                const response = await api.post('/geocoding/geocode', {
                    luogo: luogo.luogo
                });
                
                if (response.data.success) {
                    const data = response.data.data;
                    const lat = parseFloat(data.lat);
                    const lng = parseFloat(data.lng);
                    
                    if (isNaN(lat) || isNaN(lng)) {
                        console.warn(`Coordinate non valide per ${luogo.luogo}:`, data);
                        return { 
                            success: false, 
                            motivo: `Coordinate non valide ricevute dal server` 
                        };
                    }
                    
                    // Costruisci il contenuto del popup con informazioni dettagliate
                    let popupContent = `<div style="min-width: 200px;">`;
                    popupContent += `<b style="font-size: 14px; color: #1f2937;">${luogo.nome || luogo.luogo}</b>`;
                    popupContent += `<br><span style="color: #6b7280; font-size: 12px;">📍 ${luogo.luogo}</span>`;
                    
                    if (luogo.data) {
                        popupContent += `<br><span style="color: #6b7280; font-size: 12px;">📅 ${formatDate(luogo.data)}</span>`;
                    }
                    
                    if (luogo.descrizione) {
                        popupContent += `<br><span style="color: #4b5563; font-size: 12px; margin-top: 4px; display: block;">${luogo.descrizione}</span>`;
                    }
                    
                    popupContent += `</div>`;
                    
                    // Scegli un colore del marker in base al tipo di evento
                    let iconColor = '#3388ff'; // Default blu
                    if (luogo.tipo === 'nascita') iconColor = '#10b981'; // Verde
                    else if (luogo.tipo === 'morte' || luogo.tipo === 'sepoltura') iconColor = '#ef4444'; // Rosso
                    else if (luogo.tipo === 'matrimonio') iconColor = '#a855f7'; // Viola
                    else if (luogo.tipo === 'militare' || luogo.tipo === 'guerra') iconColor = '#f59e0b'; // Arancione
                    else if (['primo_giorno_scuola', 'primo_giorno_asilo', 'licenza_elementare', 'licenza_media', 'diploma_superiore', 'laurea'].includes(luogo.tipo)) iconColor = '#3b82f6'; // Blu scuro
                    
                    // Crea un marker personalizzato con colore
                    const customIcon = L.divIcon({
                        className: 'custom-marker',
                        html: `<div style="background-color: ${iconColor}; width: 20px; height: 20px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3);"></div>`,
                        iconSize: [20, 20],
                        iconAnchor: [10, 10]
                    });
                    
                    // Verifica che la mappa sia ancora inizializzata prima di aggiungere il marker
                    if (!map) {
                        console.warn(`Mappa non disponibile per ${luogo.luogo}, salto il marker`);
                        return { 
                            success: false, 
                            motivo: `Mappa non disponibile` 
                        };
                    }
                    
                    const marker = L.marker([lat, lng], { icon: customIcon })
                        .addTo(map)
                        .bindPopup(popupContent);
                    markers.push(marker);
                    bounds.push([lat, lng]);
                    
                    return { success: true, lat, lng };
                } else {
                    console.warn(`Nessun risultato trovato per: ${luogo.luogo}`);
                    return { 
                        success: false, 
                        motivo: `Nessun risultato trovato su OpenStreetMap per "${luogo.luogo}"` 
                    };
                }
            } catch (error) {
                console.error(`Errore nel geocoding di ${luogo.luogo} (tentativo ${i + 1}/${retries + 1}):`, error);
                if (i === retries) {
                    const errorMsg = error.message || 'Errore sconosciuto';
                    return { 
                        success: false, 
                        motivo: `Errore dopo ${retries + 1} tentativi: ${errorMsg}` 
                    };
                }
            }
        }
        return { 
            success: false, 
            motivo: `Tutti i tentativi di geocodifica sono falliti` 
        };
    };

    // Processa i luoghi sequenzialmente con delay per rispettare il rate limit
    let successCount = 0;
    let failCount = 0;
    
    for (let i = 0; i < luoghiFiltrati.length; i++) {
        // Verifica che la mappa sia ancora disponibile prima di continuare
        if (!map || !mapContainer.value) {
            console.warn('Mappa non più disponibile, interrompo la geocodifica');
            errorMessage.value = 'La mappa è stata distrutta durante la geocodifica. Ricarica la pagina.';
            loading.value = false;
            return;
        }
        
        const luogo = luoghiFiltrati[i];
        
        // Delay ridotto a 0.5 secondi tra le richieste (il backend gestisce il cache)
        // Solo per luoghi non in cache serve rispettare il rate limit
        if (i > 0) {
            await new Promise(resolve => setTimeout(resolve, 500));
        }
        
        // Verifica nuovamente che la mappa sia ancora disponibile dopo il delay
        if (!map || !mapContainer.value) {
            console.warn('Mappa non più disponibile dopo delay, interrompo la geocodifica');
            errorMessage.value = 'La mappa è stata distrutta durante la geocodifica. Ricarica la pagina.';
            loading.value = false;
            return;
        }
        
        const result = await geocodeWithRetry(luogo);
        if (result && result.success) {
            // Verifica ancora una volta che la mappa sia disponibile prima di aggiungere il marker
            if (map && mapContainer.value) {
                bounds.push([result.lat, result.lng]);
                successCount++;
            } else {
                failCount++;
                failedLuoghi.value.push({
                    nome: luogo.nome || luogo.luogo,
                    luogo: luogo.luogo,
                    tipo: luogo.tipo,
                    motivo: 'Mappa non più disponibile'
                });
            }
        } else {
            failCount++;
            // Aggiungi il luogo fallito alla lista con il motivo
            failedLuoghi.value.push({
                nome: luogo.nome || luogo.luogo,
                luogo: luogo.luogo,
                tipo: luogo.tipo,
                motivo: result?.motivo || 'Motivo sconosciuto'
            });
            console.warn(`Luogo non trovato: "${luogo.luogo}" - Motivo: ${result?.motivo || 'Sconosciuto'}`);
        }
        
        processedCount.value = i + 1;
    }

    loading.value = false;
    
    // Log dettagliato dei risultati
    console.log(`Geocodifica completata: ${successCount} successi, ${failCount} falliti su ${luoghiFiltrati.length} luoghi totali`);
    if (failedLuoghi.value.length > 0) {
        console.group('Luoghi non trovati:');
        failedLuoghi.value.forEach(luogo => {
            console.log(`- ${luogo.nome || luogo.luogo}: ${luogo.motivo}`);
        });
        console.groupEnd();
    }
    
    if (failCount > 0 && successCount === 0) {
        errorMessage.value = `Nessun luogo è stato geocodificato con successo. Verifica che i nomi dei luoghi siano corretti.`;
    } else if (failCount > 0) {
        errorMessage.value = `${failCount} luogo/i non sono stati trovati sulla mappa. Vedi dettagli sotto.`;
    } else {
        errorMessage.value = '';
    }

    // Aggiusta il viewport se ci sono marker con padding maggiore
    if (bounds.length > 0 && map && mapContainer.value) {
        try {
            // Crea un bounds object da Leaflet
            const boundsGroup = L.latLngBounds(bounds);
            
            // Se c'è un solo marker, usa un zoom più appropriato
            if (bounds.length === 1) {
                map.setView(bounds[0], 10);
            } else {
                // Aumenta il padding per includere meglio tutti i marker
                map.fitBounds(boundsGroup, { 
                    padding: [80, 80],
                    maxZoom: 15 // Limita lo zoom massimo per vedere meglio l'area complessiva
                });
            }
        } catch (error) {
            console.error('Errore nell\'aggiustamento del viewport:', error);
        }
    }
};

onMounted(async () => {
    // Aspetta che il DOM sia completamente renderizzato
    await nextTick();
    
    // Quando noWrapper è true, aspetta un po' di più per assicurarsi che il container sia disponibile
    const delay = props.noWrapper ? 500 : 0;
    
    if (delay > 0) {
        await new Promise(resolve => setTimeout(resolve, delay));
    }
    
    // Assicurati che il container sia disponibile prima di inizializzare
    if (mapContainer.value) {
        try {
            initMap();
            // Ridimensiona la mappa dopo l'inizializzazione per assicurarsi che occupi tutto lo spazio
            setTimeout(() => {
                if (map) {
                    map.invalidateSize();
                }
            }, props.noWrapper ? 500 : 300);
        } catch (error) {
            console.error('Errore nell\'inizializzazione della mappa:', error);
        }
    } else {
        // Se il container non è ancora disponibile, riprova dopo un breve delay
        setTimeout(() => {
            if (mapContainer.value && !map) {
                try {
                    initMap();
                    setTimeout(() => {
                        if (map) {
                            map.invalidateSize();
                        }
                    }, props.noWrapper ? 500 : 300);
                } catch (error) {
                    console.error('Errore nell\'inizializzazione della mappa (retry):', error);
                }
            }
        }, props.noWrapper ? 500 : 200);
    }
    
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
    
    // Ridimensiona la mappa quando la finestra cambia dimensione
    resizeHandler = () => {
        if (map) {
            setTimeout(() => {
                map.invalidateSize();
            }, 100);
        }
    };
    
    window.addEventListener('resize', resizeHandler);
});

onBeforeUnmount(() => {
    // Rimuovi il listener di resize
    if (resizeHandler) {
        window.removeEventListener('resize', resizeHandler);
        resizeHandler = null;
    }
    
    // Pulisci la mappa quando il componente viene smontato
    if (map) {
        map.remove();
        map = null;
    }
    markers = [];
});

watch(() => props.luoghi, () => {
    if (map) {
        updateMarkers();
    }
}, { deep: true, immediate: false });
</script>

