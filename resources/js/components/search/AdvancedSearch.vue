<template>
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4 mb-4">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-base font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                {{ t('search.advanced_search') }}
            </h3>
            <button
                v-if="showFilters"
                @click="showFilters = false"
                class="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
            >
                {{ t('common.close') }}
            </button>
        </div>

        <div v-if="!showFilters" class="flex gap-2">
            <input
                v-model="quickSearch"
                @keyup.enter="performQuickSearch"
                type="text"
                class="flex-1 px-4 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                :placeholder="t('search.quick_search_placeholder')"
            />
            <button
                @click="performQuickSearch"
                class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
            >
                {{ t('search.search') }}
            </button>
            <button
                @click="showFilters = true"
                class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 transition-colors"
            >
                {{ t('search.filters') }}
            </button>
        </div>

        <div v-else class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('persona.nome') }}
                    </label>
                    <input
                        v-model="filters.nome"
                        type="text"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    />
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('persona.cognome') }}
                    </label>
                    <input
                        v-model="filters.cognome"
                        type="text"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    />
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('search.birth_date_from') }}
                    </label>
                    <input
                        v-model="filters.nato_il_da"
                        type="date"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    />
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('search.birth_date_to') }}
                    </label>
                    <input
                        v-model="filters.nato_il_a"
                        type="date"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    />
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('persona.birth_place') }}
                    </label>
                    <input
                        v-model="filters.nato_a"
                        type="text"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    />
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('search.life_status') }}
                    </label>
                    <select
                        v-model="filters.stato_vita"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    >
                        <option value="">{{ t('search.all') }}</option>
                        <option value="vivente">{{ t('persona.living') }}</option>
                        <option value="deceduto">{{ t('persona.deceased') }}</option>
                    </select>
                </div>
            </div>
            <div class="flex gap-2">
                <button
                    @click="performAdvancedSearch"
                    class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
                >
                    {{ t('search.search') }}
                </button>
                <button
                    @click="resetFilters"
                    class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 transition-colors"
                >
                    {{ t('search.reset') }}
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref } from 'vue';
import { useLocaleStore } from '../../stores/locale';
import { personaService } from '../../services/personaService';

const emit = defineEmits(['search-results']);

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

const showFilters = ref(false);
const quickSearch = ref('');
const filters = ref({
    nome: '',
    cognome: '',
    nato_il_da: '',
    nato_il_a: '',
    nato_a: '',
    stato_vita: '',
});

const performQuickSearch = async () => {
    if (!quickSearch.value.trim()) return;
    
    const searchTerms = quickSearch.value.trim().split(' ');
    const searchFilters = {};
    
    if (searchTerms.length === 1) {
        searchFilters.nome = searchTerms[0];
        searchFilters.cognome = searchTerms[0];
    } else {
        searchFilters.nome = searchTerms[0];
        searchFilters.cognome = searchTerms.slice(1).join(' ');
    }
    
    await performSearch(searchFilters);
};

const performAdvancedSearch = async () => {
    const activeFilters = {};
    Object.keys(filters.value).forEach(key => {
        if (filters.value[key]) {
            activeFilters[key] = filters.value[key];
        }
    });
    
    await performSearch(activeFilters);
};

const performSearch = async (searchFilters) => {
    try {
        const params = new URLSearchParams();
        Object.keys(searchFilters).forEach(key => {
            if (searchFilters[key]) {
                params.append(key, searchFilters[key]);
            }
        });
        
        const response = await fetch(`/api/persone/search?${params.toString()}`);
        const data = await response.json();
        
        emit('search-results', data);
    } catch (error) {
        console.error('Errore nella ricerca:', error);
    }
};

const resetFilters = () => {
    filters.value = {
        nome: '',
        cognome: '',
        nato_il_da: '',
        nato_il_a: '',
        nato_a: '',
        stato_vita: '',
    };
    quickSearch.value = '';
};
</script>

