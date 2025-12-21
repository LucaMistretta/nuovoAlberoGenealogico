<template>
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
            <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>
            {{ t('import.gedcom_import') }}
        </h3>

        <div class="space-y-4">
            <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                    {{ t('import.select_file') }}
                </label>
                <input
                    ref="fileInput"
                    type="file"
                    @change="handleFileSelect"
                    accept=".ged,.txt"
                    class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
                <p v-if="selectedFile" class="mt-1 text-xs text-gray-500 dark:text-gray-400">
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
                    @click="reset"
                    class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 transition-colors"
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
</template>

<script setup>
import { ref } from 'vue';
import { useLocaleStore } from '../../stores/locale';
import axios from 'axios';

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

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

        // Emetti evento import completato
        if (response.data.success) {
            emit('imported');
        }

        // Reset dopo 3 secondi
        setTimeout(() => {
            reset();
        }, 3000);
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

const reset = () => {
    selectedFile.value = null;
    risultato.value = null;
    progress.value = 0;
    if (fileInput.value) {
        fileInput.value.value = '';
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

