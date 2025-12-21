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
                    <div class="flex gap-2">
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
                        <button 
                            @click="showImportDialog = true"
                            class="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors text-sm flex items-center gap-1"
                        >
                            {{ t('nav.import') }}
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                            </svg>
                        </button>
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

    <!-- Dialog Import GEDCOM -->
    <div v-if="showImportDialog" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" @click.self="closeImportDialog">
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-md w-full mx-4 p-6">
            <div class="flex justify-between items-center mb-4">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                    <svg class="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                    </svg>
                    {{ t('import.gedcom_import') }}
                </h3>
                <button @click="closeImportDialog" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <div class="space-y-4">
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        {{ t('import.select_file') }}
                    </label>
                    <input
                        ref="fileInput"
                        type="file"
                        @change="handleFileSelect"
                        accept=".ged,.txt"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    />
                    <p v-if="selectedFile" class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                        {{ selectedFile.name }} ({{ formatFileSize(selectedFile.size) }})
                    </p>
                </div>

                <div class="flex gap-2">
                    <button
                        @click="handleImport"
                        :disabled="!selectedFile || importing"
                        class="flex-1 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                        <span v-if="!importing">{{ t('import.import') }}</span>
                        <span v-else class="flex items-center justify-center gap-2">
                            <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            {{ t('import.importing') }}
                        </span>
                    </button>
                    <button
                        @click="closeImportDialog"
                        class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-700 transition-colors"
                    >
                        {{ t('common.cancel') }}
                    </button>
                </div>

                <!-- Progress Bar -->
                <div v-if="importing" class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div class="bg-blue-600 h-2 rounded-full transition-all duration-300" :style="{ width: progress + '%' }"></div>
                </div>

                <!-- Risultati -->
                <div v-if="risultato" class="p-4 rounded-lg" :class="risultato.success ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800' : 'bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800'">
                    <p class="text-sm font-semibold" :class="risultato.success ? 'text-green-800 dark:text-green-300' : 'text-red-800 dark:text-red-300'">
                        {{ risultato.message }}
                    </p>
                    <p v-if="risultato.data" class="text-xs mt-2" :class="risultato.success ? 'text-green-700 dark:text-green-400' : 'text-red-700 dark:text-red-400'">
                        {{ t('import.imported') }}: {{ risultato.data.importate || 0 }}
                        <span v-if="risultato.data.errori?.length > 0">
                            | {{ t('import.errors') }}: {{ risultato.data.errori.length }}
                        </span>
                    </p>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useAuthStore } from '../../stores/auth';
import { useLocaleStore } from '../../stores/locale';
import { useRouter } from 'vue-router';
import ThemeToggle from './ThemeToggle.vue';
import LanguageSwitcher from './LanguageSwitcher.vue';
import axios from 'axios';

const authStore = useAuthStore();
const localeStore = useLocaleStore();
const router = useRouter();

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

// Import GEDCOM Dialog
const showImportDialog = ref(false);
const fileInput = ref(null);
const selectedFile = ref(null);
const importing = ref(false);
const progress = ref(0);
const risultato = ref(null);

const handleFileSelect = (event) => {
    selectedFile.value = event.target.files[0];
    risultato.value = null;
};

const handleImport = async () => {
    if (!selectedFile.value) return;

    importing.value = true;
    progress.value = 0;
    risultato.value = null;

    try {
        const formData = new FormData();
        formData.append('file', selectedFile.value);

        // Simula progresso
        const progressInterval = setInterval(() => {
            if (progress.value < 90) {
                progress.value += 10;
            }
        }, 200);

        const response = await axios.post('/api/import/gedcom', formData, {
            headers: {
                'Content-Type': 'multipart/form-data',
            },
        });

        clearInterval(progressInterval);
        progress.value = 100;

        risultato.value = {
            success: response.data.success,
            message: response.data.message || t('import.import_complete'),
            data: response.data.data,
        };

        // Ricarica la pagina dopo 2 secondi se l'import è riuscito
        if (response.data.success) {
            setTimeout(() => {
                window.location.reload();
            }, 2000);
        }
    } catch (error) {
        progress.value = 0;
        risultato.value = {
            success: false,
            message: error.response?.data?.message || t('import.import_error'),
        };
    } finally {
        importing.value = false;
    }
};

const closeImportDialog = () => {
    if (!importing.value) {
        showImportDialog.value = false;
        selectedFile.value = null;
        risultato.value = null;
        progress.value = 0;
        if (fileInput.value) {
            fileInput.value.value = '';
        }
    }
};

const formatFileSize = (bytes) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
};
</script>

