<template>
    <nav class="bg-gray-300 dark:bg-gray-800 shadow-md">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16">
                <div class="flex items-center space-x-6">
                    <router-link to="/persone" class="text-xl font-bold text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 transition-colors">
                        {{ t('app.name') }}
                    </router-link>
                    <router-link 
                        to="/persone/tree" 
                        class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm"
                    >
                        {{ t('nav.view_tree') }}
                    </router-link>
                    <router-link 
                        to="/persone/family-chart" 
                        class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors text-sm"
                    >
                        {{ t('nav.family_chart') }}
                    </router-link>
                    <div class="relative group">
                        <button class="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors text-sm flex items-center gap-1">
                            {{ t('nav.export') }}
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                            </svg>
                        </button>
                        <div class="absolute left-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-50">
                            <div class="py-1">
                                <button @click="exportGedcom" class="w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700">
                                    {{ t('export.gedcom_all') }}
                                </button>
                                <button @click="exportCsv" class="w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700">
                                    {{ t('export.csv') }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="flex items-center space-x-4">
                    <LanguageSwitcher />
                    <ThemeToggle />
                    <button
                        @click="logout"
                        class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                    >
                        {{ t('nav.logout') }}
                    </button>
                </div>
            </div>
        </div>
    </nav>
</template>

<script setup>
import { onMounted, watch } from 'vue';
import { useAuthStore } from '../../stores/auth';
import { useLocaleStore } from '../../stores/locale';
import ThemeToggle from './ThemeToggle.vue';
import LanguageSwitcher from './LanguageSwitcher.vue';

const authStore = useAuthStore();
const localeStore = useLocaleStore();

// Helper per le traduzioni
const t = (key) => {
    return localeStore.t(key);
};

// Assicurati che le traduzioni siano caricate
onMounted(() => {
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});

// Watch per ricaricare le traduzioni quando cambia la lingua
watch(() => localeStore.locale, () => {
    localeStore.loadTranslations();
});

const logout = async () => {
    await authStore.logout();
};

const exportGedcom = () => {
    window.location.href = '/api/export/gedcom';
};

const exportCsv = () => {
    window.location.href = '/api/export/csv';
};
</script>

