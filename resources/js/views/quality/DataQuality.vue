<template>
    <div class="bg-gray-200 dark:bg-gray-900">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
            <div class="flex items-center justify-between mb-6">
                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">{{ t('quality.title') }}</h1>
                <button
                    @click="runChecks"
                    :disabled="loading"
                    class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
                >
                    {{ t('quality.run_checks') }}
                </button>
            </div>

            <div v-if="loading" class="flex items-center justify-center py-12">
                <div class="text-center">
                    <div class="inline-block animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mb-3"></div>
                    <p class="text-gray-600 dark:text-gray-400">{{ t('common.loading') }}</p>
                </div>
            </div>

            <div v-else-if="problemi.totale_problemi === 0" class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6 text-center">
                <svg class="w-16 h-16 text-green-600 dark:text-green-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p class="text-lg font-semibold text-green-800 dark:text-green-300">{{ t('quality.no_issues') }}</p>
            </div>

            <div v-else class="space-y-6">
                <!-- Riepilogo -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                    <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">{{ t('quality.summary') }}</h2>
                    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div class="text-center p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
                            <p class="text-3xl font-bold text-red-600 dark:text-red-400">{{ problemi.totale_problemi }}</p>
                            <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ t('quality.total_issues') }}</p>
                        </div>
                        <div class="text-center p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
                            <p class="text-3xl font-bold text-yellow-600 dark:text-yellow-400">{{ problemi.problemi_date?.length || 0 }}</p>
                            <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ t('quality.date_issues') }}</p>
                        </div>
                        <div class="text-center p-4 bg-orange-50 dark:bg-orange-900/20 rounded-lg">
                            <p class="text-3xl font-bold text-orange-600 dark:text-orange-400">{{ problemi.problemi_duplicati?.length || 0 }}</p>
                            <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ t('quality.duplicate_issues') }}</p>
                        </div>
                        <div class="text-center p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg">
                            <p class="text-3xl font-bold text-purple-600 dark:text-purple-400">{{ problemi.problemi_relazioni?.length || 0 }}</p>
                            <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ t('quality.relationship_issues') }}</p>
                        </div>
                    </div>
                </div>

                <!-- Problemi Date -->
                <div v-if="problemi.problemi_date?.length > 0" class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                        <span class="w-2 h-2 bg-yellow-500 rounded-full"></span>
                        {{ t('quality.date_issues') }} ({{ problemi.problemi_date.length }})
                    </h3>
                    <div class="space-y-2">
                        <div
                            v-for="problema in problemi.problemi_date"
                            :key="`date-${problema.persona_id}`"
                            class="p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800"
                        >
                            <div class="flex items-start justify-between">
                                <div class="flex-1">
                                    <router-link
                                        :to="`/persone/${problema.persona_id}`"
                                        class="font-semibold text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400"
                                    >
                                        {{ problema.persona_nome }}
                                    </router-link>
                                    <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ problema.messaggio }}</p>
                                </div>
                                <span class="px-2 py-1 text-xs font-medium rounded" :class="getSeverityClass(problema.severita)">
                                    {{ problema.severita }}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Problemi Duplicati -->
                <div v-if="problemi.problemi_duplicati?.length > 0" class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                        <span class="w-2 h-2 bg-orange-500 rounded-full"></span>
                        {{ t('quality.duplicate_issues') }} ({{ problemi.problemi_duplicati.length }})
                    </h3>
                    <div class="space-y-2">
                        <div
                            v-for="problema in problemi.problemi_duplicati"
                            :key="`dup-${problema.persona_id}`"
                            class="p-3 bg-orange-50 dark:bg-orange-900/20 rounded-lg border border-orange-200 dark:border-orange-800"
                        >
                            <div class="flex items-start justify-between">
                                <div class="flex-1">
                                    <router-link
                                        :to="`/persone/${problema.persona_id}`"
                                        class="font-semibold text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400"
                                    >
                                        {{ problema.persona_nome }}
                                    </router-link>
                                    <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ problema.messaggio }}</p>
                                </div>
                                <span class="px-2 py-1 text-xs font-medium rounded" :class="getSeverityClass(problema.severita)">
                                    {{ problema.severita }}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Problemi Relazioni -->
                <div v-if="problemi.problemi_relazioni?.length > 0" class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                        <span class="w-2 h-2 bg-purple-500 rounded-full"></span>
                        {{ t('quality.relationship_issues') }} ({{ problemi.problemi_relazioni.length }})
                    </h3>
                    <div class="space-y-2">
                        <div
                            v-for="problema in problemi.problemi_relazioni"
                            :key="`rel-${problema.persona_id}`"
                            class="p-3 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800"
                        >
                            <div class="flex items-start justify-between">
                                <div class="flex-1">
                                    <router-link
                                        :to="`/persone/${problema.persona_id}`"
                                        class="font-semibold text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400"
                                    >
                                        {{ problema.persona_nome }}
                                    </router-link>
                                    <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ problema.messaggio }}</p>
                                </div>
                                <span class="px-2 py-1 text-xs font-medium rounded" :class="getSeverityClass(problema.severita)">
                                    {{ problema.severita }}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useLocaleStore } from '../../stores/locale';
import axios from 'axios';

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

const loading = ref(false);
const problemi = ref({
    totale_problemi: 0,
    problemi_date: [],
    problemi_duplicati: [],
    problemi_relazioni: [],
});

const runChecks = async () => {
    loading.value = true;
    try {
        const response = await axios.get('/api/data-quality/check');
        problemi.value = {
            totale_problemi: response.data.data.totale_problemi || 0,
            problemi_date: response.data.data.problemi_date || [],
            problemi_duplicati: response.data.data.problemi_duplicati || [],
            problemi_relazioni: response.data.data.problemi_relazioni || [],
        };
    } catch (error) {
        console.error('Errore nel controllo qualità dati:', error);
    } finally {
        loading.value = false;
    }
};

const getSeverityClass = (severita) => {
    const classes = {
        alta: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
        media: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300',
        bassa: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
    };
    return classes[severita] || classes.media;
};

onMounted(() => {
    runChecks();
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});
</script>

