<template>
    <div class="bg-gray-200 dark:bg-gray-900">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">{{ t('report.title') }}</h1>

            <div v-if="loading" class="flex items-center justify-center py-12">
                <div class="text-center">
                    <div class="inline-block animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mb-3"></div>
                    <p class="text-gray-600 dark:text-gray-400">{{ t('common.loading') }}</p>
                </div>
            </div>

            <div v-else class="space-y-6">
                <!-- Statistiche Generali -->
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('report.total_people') }}</p>
                                <p class="text-3xl font-bold text-gray-900 dark:text-white">{{ statistiche.totale_persone || 0 }}</p>
                            </div>
                            <div class="w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                                <svg class="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                                </svg>
                            </div>
                        </div>
                    </div>

                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('report.living') }}</p>
                                <p class="text-3xl font-bold text-green-600 dark:text-green-400">{{ statistiche.viventi || 0 }}</p>
                            </div>
                            <div class="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                                <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                            </div>
                        </div>
                    </div>

                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('report.deceased') }}</p>
                                <p class="text-3xl font-bold text-red-600 dark:text-red-400">{{ statistiche.deceduti || 0 }}</p>
                            </div>
                            <div class="w-12 h-12 bg-red-100 dark:bg-red-900/30 rounded-lg flex items-center justify-center">
                                <svg class="w-6 h-6 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                            </div>
                        </div>
                    </div>

                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('report.generations') }}</p>
                                <p class="text-3xl font-bold text-purple-600 dark:text-purple-400">{{ statistiche.generazioni || 0 }}</p>
                            </div>
                            <div class="w-12 h-12 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center">
                                <svg class="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                </svg>
                            </div>
                        </div>
                    </div>

                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('report.with_parents') }}</p>
                                <p class="text-3xl font-bold text-blue-600 dark:text-blue-400">{{ statistiche.con_genitori || 0 }}</p>
                            </div>
                        </div>
                    </div>

                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('report.with_children') }}</p>
                                <p class="text-3xl font-bold text-green-600 dark:text-green-400">{{ statistiche.con_figli || 0 }}</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Grafici -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <!-- Distribuzione Età -->
                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">{{ t('report.age_distribution') }}</h3>
                        <div class="h-64">
                            <BarChart v-if="distribuzioneEta" :data="distribuzioneEta" />
                        </div>
                    </div>

                    <!-- Luoghi di Nascita - Lista -->
                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">{{ t('report.birth_places') }}</h3>
                        <div class="space-y-2 max-h-64 overflow-y-auto">
                            <div
                                v-for="luogo in luoghiNascita"
                                :key="luogo.nato_a"
                                class="flex items-center justify-between p-2 bg-gray-50 dark:bg-gray-700/50 rounded"
                            >
                                <span class="text-sm text-gray-900 dark:text-white">{{ luogo.nato_a }}</span>
                                <span class="text-sm font-semibold text-blue-600 dark:text-blue-400">{{ luogo.totale }}</span>
                            </div>
                            <p v-if="luoghiNascita.length === 0" class="text-sm text-gray-500 dark:text-gray-400 text-center py-4">
                                {{ t('report.no_birth_places') }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Mappa Luoghi di Nascita -->
                <div v-if="luoghiNascita.length > 0" class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">{{ t('report.birth_places_map') }}</h3>
                    <div class="w-full aspect-square max-w-4xl mx-auto">
                        <div class="h-full w-full">
                            <MapView :luoghi="mapLuoghiNascita" :no-wrapper="true" />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useLocaleStore } from '../../stores/locale';
import BarChart from '../../components/charts/BarChart.vue';
import MapView from '../../components/maps/MapView.vue';
import api from '../../services/api';

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

const loading = ref(false);
const statistiche = ref({});
const distribuzioneEta = ref(null);
const luoghiNascita = ref([]);

// Trasforma i luoghi di nascita nel formato atteso da MapView
const mapLuoghiNascita = computed(() => {
    return luoghiNascita.value
        .filter(luogo => luogo.nato_a && luogo.nato_a !== '0' && luogo.nato_a !== '')
        .map(luogo => ({
            luogo: luogo.nato_a,
            nome: luogo.nato_a,
            descrizione: `${luogo.totale} ${luogo.totale === 1 ? 'persona' : 'persone'}`,
            tipo: 'nascita'
        }));
});

const loadData = async () => {
    loading.value = true;
    try {
        const [statsRes, etaRes, luoghiRes] = await Promise.all([
            api.get('/report/statistiche'),
            api.get('/report/distribuzione-eta'),
            api.get('/report/luoghi-nascita'),
        ]);

        statistiche.value = statsRes.data.data || {};
        distribuzioneEta.value = etaRes.data.data || {};
        luoghiNascita.value = luoghiRes.data.data || [];
    } catch (error) {
        console.error('Errore nel caricamento dei report:', error);
        console.error('Dettagli errore:', error.response?.data || error.message);
    } finally {
        loading.value = false;
    }
};

onMounted(() => {
    loadData();
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});
</script>

