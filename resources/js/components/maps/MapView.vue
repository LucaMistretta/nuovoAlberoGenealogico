<template>
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
            <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            {{ t('maps.title') }}
        </h3>
        <div ref="mapContainer" class="w-full h-96 rounded-lg border border-gray-200 dark:border-gray-600"></div>
    </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useLocaleStore } from '../../stores/locale';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const props = defineProps({
    luoghi: {
        type: Array,
        default: () => [],
    },
});

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

const mapContainer = ref(null);
let map = null;
let markers = [];

// Fix per icone Leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
});

const initMap = () => {
    if (!mapContainer.value) return;

    map = L.map(mapContainer.value).setView([41.9028, 12.4964], 6); // Centrato sull'Italia

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19,
    }).addTo(map);

    updateMarkers();
};

const updateMarkers = async () => {
    if (!map) return;

    // Rimuovi marker esistenti
    markers.forEach(marker => map.removeLayer(marker));
    markers = [];

    // Geocodifica i luoghi e aggiungi marker
    const bounds = [];
    for (const luogo of props.luoghi) {
        if (!luogo.luogo || luogo.luogo === '0' || luogo.luogo === '') continue;
        
        try {
            // Usa Nominatim per geocodificare il luogo
            const response = await fetch(`https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(luogo.luogo)}&format=json&limit=1`);
            const data = await response.json();
            
            if (data && data.length > 0) {
                const lat = parseFloat(data[0].lat);
                const lng = parseFloat(data[0].lon);
                const marker = L.marker([lat, lng])
                    .addTo(map)
                    .bindPopup(`<b>${luogo.nome || luogo.luogo}</b><br>${luogo.luogo}`);
                markers.push(marker);
                bounds.push([lat, lng]);
            }
        } catch (error) {
            console.error(`Errore nel geocoding di ${luogo.luogo}:`, error);
        }
    }

    // Aggiusta il viewport se ci sono marker
    if (bounds.length > 0) {
        map.fitBounds(bounds, { padding: [50, 50] });
    }
};

onMounted(() => {
    initMap();
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});

watch(() => props.luoghi, () => {
    updateMarkers();
}, { deep: true });
</script>

