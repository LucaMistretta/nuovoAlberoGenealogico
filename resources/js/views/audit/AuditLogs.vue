<template>
    <div class="bg-gray-200 dark:bg-gray-900">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">{{ t('audit.title') }}</h1>

            <!-- Filtri -->
            <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4 mb-4">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                            {{ t('audit.model_type') }}
                        </label>
                        <select
                            v-model="filters.model_type"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        >
                            <option value="">{{ t('audit.all') }}</option>
                            <option value="App\Models\Persona">Persona</option>
                            <option value="App\Models\Evento">Evento</option>
                            <option value="App\Models\Media">Media</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                            {{ t('audit.action') }}
                        </label>
                        <select
                            v-model="filters.action"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        >
                            <option value="">{{ t('audit.all') }}</option>
                            <option value="created">{{ t('audit.created') }}</option>
                            <option value="updated">{{ t('audit.updated') }}</option>
                            <option value="deleted">{{ t('audit.deleted') }}</option>
                        </select>
                    </div>
                    <div class="flex items-end">
                        <button
                            @click="loadLogs"
                            class="w-full px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
                        >
                            {{ t('search.search') }}
                        </button>
                    </div>
                </div>
            </div>

            <!-- Lista Log -->
            <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
                <div v-if="loading" class="flex items-center justify-center py-12">
                    <div class="text-center">
                        <div class="inline-block animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mb-3"></div>
                        <p class="text-gray-600 dark:text-gray-400">{{ t('common.loading') }}</p>
                    </div>
                </div>

                <div v-else-if="logs.length === 0" class="text-center py-12">
                    <p class="text-gray-600 dark:text-gray-400">{{ t('audit.no_logs') }}</p>
                </div>

                <div v-else class="divide-y divide-gray-200 dark:divide-gray-700">
                    <div
                        v-for="log in logs"
                        :key="log.id"
                        class="p-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
                    >
                        <div class="flex items-start justify-between">
                            <div class="flex-1">
                                <div class="flex items-center gap-2 mb-2">
                                    <span class="px-2 py-1 text-xs font-medium rounded" :class="getActionClass(log.action)">
                                        {{ getActionLabel(log.action) }}
                                    </span>
                                    <span class="text-sm text-gray-600 dark:text-gray-400">{{ log.model_type }}</span>
                                    <span class="text-sm text-gray-500 dark:text-gray-500">#{{ log.model_id }}</span>
                                </div>
                                <p class="text-sm text-gray-600 dark:text-gray-400">
                                    {{ log.user?.name || t('audit.system') }} - {{ formatDate(log.created_at) }}
                                </p>
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
import api from '../../services/api';

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

const loading = ref(false);
const logs = ref([]);
const filters = ref({
    model_type: '',
    action: '',
});

const loadLogs = async () => {
    loading.value = true;
    try {
        const params = new URLSearchParams();
        if (filters.value.model_type) params.append('model_type', filters.value.model_type);
        if (filters.value.action) params.append('action', filters.value.action);

        const response = await api.get(`/audit-logs?${params.toString()}`);
        logs.value = response.data.data?.data || [];
    } catch (error) {
        console.error('Errore nel caricamento dei log:', error);
    } finally {
        loading.value = false;
    }
};

const getActionClass = (action) => {
    const classes = {
        created: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
        updated: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
        deleted: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
    };
    return classes[action] || 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300';
};

const getActionLabel = (action) => {
    const labels = {
        created: t('audit.created'),
        updated: t('audit.updated'),
        deleted: t('audit.deleted'),
    };
    return labels[action] || action;
};

const formatDate = (dateString) => {
    if (!dateString) return '';
    try {
        const date = new Date(dateString);
        return date.toLocaleString('it-IT');
    } catch (e) {
        return dateString;
    }
};

onMounted(() => {
    loadLogs();
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});
</script>


