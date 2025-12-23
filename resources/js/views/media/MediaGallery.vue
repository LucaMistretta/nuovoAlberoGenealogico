<template>
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-base font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                {{ t('media.gallery') }}
            </h3>
            <button
                v-if="!showUpload"
                @click="showUpload = true"
                class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
            >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
                {{ t('media.upload') }}
            </button>
        </div>

        <!-- Form Upload -->
        <div v-if="showUpload" class="mb-4 p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600">
            <div class="space-y-3">
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('media.file') }}
                    </label>
                    <input
                        ref="fileInput"
                        type="file"
                        @change="handleFileSelect"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        accept="image/*,.pdf,.doc,.docx"
                    />
                    <p v-if="selectedFile" class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        {{ selectedFile.name }} ({{ formatFileSize(selectedFile.size) }})
                    </p>
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('media.type') }}
                    </label>
                    <select
                        v-model="uploadType"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    >
                        <option value="foto">{{ t('media.photo') }}</option>
                        <option value="documento">{{ t('media.document') }}</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('media.description') }} ({{ t('common.optional') }})
                    </label>
                    <textarea
                        v-model="uploadDescription"
                        rows="2"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        :placeholder="t('media.description_placeholder')"
                    ></textarea>
                </div>
                <div class="flex gap-2">
                    <button
                        @click="handleUpload"
                        :disabled="!selectedFile || uploading"
                        class="flex-1 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                        <span v-if="!uploading">{{ t('media.upload') }}</span>
                        <span v-else class="flex items-center justify-center gap-2">
                            <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            {{ t('media.uploading') }}
                        </span>
                    </button>
                    <button
                        @click="cancelUpload"
                        class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-700 transition-colors"
                    >
                        {{ t('common.cancel') }}
                    </button>
                </div>
            </div>
        </div>

        <!-- Gallery -->
        <div v-if="loading" class="flex items-center justify-center py-8">
            <div class="text-center">
                <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mb-2"></div>
                <p class="text-sm text-gray-600 dark:text-gray-400">{{ t('common.loading') }}</p>
            </div>
        </div>

        <div v-else-if="mediaList.length === 0" class="text-center py-8">
            <svg class="w-12 h-12 text-gray-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('media.no_media') }}</p>
        </div>

        <div v-else class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            <div
                v-for="media in mediaList"
                :key="media.id"
                class="group relative bg-gray-100 dark:bg-gray-700 rounded-lg overflow-hidden border border-gray-200 dark:border-gray-600 hover:border-blue-500 dark:hover:border-blue-500 transition-colors"
            >
                <!-- Immagine o icona documento -->
                <div
                    v-if="media.tipo === 'foto' || media.mime_type?.startsWith('image/')"
                    @click="openLightbox(media)"
                    class="aspect-square cursor-pointer bg-gray-200 dark:bg-gray-800 flex items-center justify-center overflow-hidden"
                >
                    <img
                        :src="getMediaUrl(media)"
                        :alt="media.descrizione || media.nome_file"
                        class="w-full h-full object-cover group-hover:scale-105 transition-transform"
                    />
                </div>
                <div
                    v-else
                    @click="downloadMedia(media)"
                    class="aspect-square cursor-pointer bg-gray-200 dark:bg-gray-800 flex flex-col items-center justify-center p-4"
                >
                    <svg class="w-12 h-12 text-gray-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                    </svg>
                    <p class="text-xs text-gray-600 dark:text-gray-400 text-center truncate w-full">
                        {{ media.nome_file }}
                    </p>
                </div>

                <!-- Overlay con azioni -->
                <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-50 transition-all flex items-center justify-center opacity-0 group-hover:opacity-100">
                    <div class="flex gap-2">
                        <button
                            @click.stop="media.tipo === 'foto' || media.mime_type?.startsWith('image/') ? openLightbox(media) : downloadMedia(media)"
                            class="p-2 bg-white rounded-lg hover:bg-gray-100 transition-colors"
                            :title="media.tipo === 'foto' ? t('media.view') : t('media.download')"
                        >
                            <svg class="w-5 h-5 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                        </button>
                        <button
                            @click.stop="deleteMedia(media)"
                            class="p-2 bg-red-500 rounded-lg hover:bg-red-600 transition-colors"
                            :title="t('common.delete')"
                        >
                            <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                        </button>
                    </div>
                </div>

                <!-- Descrizione -->
                <div v-if="media.descrizione" class="absolute bottom-0 left-0 right-0 bg-black bg-opacity-75 text-white text-xs p-2">
                    <p class="truncate">{{ media.descrizione }}</p>
                </div>
            </div>
        </div>

        <!-- Lightbox per immagini -->
        <div
            v-if="lightboxMedia"
            @click="closeLightbox"
            class="fixed inset-0 bg-black bg-opacity-90 z-50 flex items-center justify-center p-4"
        >
            <button
                @click="closeLightbox"
                class="absolute top-4 right-4 text-white hover:text-gray-300 transition-colors"
            >
                <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>
            <img
                :src="getMediaUrl(lightboxMedia)"
                :alt="lightboxMedia.descrizione || lightboxMedia.nome_file"
                class="max-w-full max-h-full object-contain"
                @click.stop
            />
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { mediaService } from '../../services/mediaService';
import { useLocaleStore } from '../../stores/locale';

const props = defineProps({
    personaId: {
        type: Number,
        required: true,
    },
});

const localeStore = useLocaleStore();

const t = (key) => {
    return localeStore.t(key);
};

const mediaList = ref([]);
const loading = ref(false);
const showUpload = ref(false);
const selectedFile = ref(null);
const uploadType = ref('foto');
const uploadDescription = ref('');
const uploading = ref(false);
const lightboxMedia = ref(null);

const loadMedia = async () => {
    loading.value = true;
    try {
        const response = await mediaService.getByPersona(props.personaId);
        mediaList.value = response.data || [];
    } catch (error) {
        console.error('Errore nel caricamento dei media:', error);
    } finally {
        loading.value = false;
    }
};

const handleFileSelect = (event) => {
    selectedFile.value = event.target.files[0];
};

const handleUpload = async () => {
    if (!selectedFile.value) {
        alert(t('media.select_file_error') || 'Seleziona un file da caricare');
        return;
    }
    
    // Verifica dimensione file (max 20MB)
    const maxSize = 20 * 1024 * 1024; // 20MB in bytes
    if (selectedFile.value.size > maxSize) {
        alert(t('media.file_too_large') || 'Il file è troppo grande. Dimensione massima: 20MB');
        return;
    }
    
    // Verifica che il tipo sia selezionato
    if (!uploadType.value || (uploadType.value !== 'foto' && uploadType.value !== 'documento')) {
        alert(t('media.select_type_error') || 'Seleziona un tipo di media (foto o documento)');
        return;
    }

    uploading.value = true;
    try {
        // Debug: verifica che il file sia presente
        console.log('Upload file info:', {
            name: selectedFile.value.name,
            size: selectedFile.value.size,
            type: selectedFile.value.type,
            uploadType: uploadType.value,
            personaId: props.personaId
        });
        
        // Upload diretto del file (PHP ora supporta fino a 20MB)
        await mediaService.upload(
            props.personaId,
            selectedFile.value,
            uploadType.value,
            uploadDescription.value || ''
        );
        await loadMedia();
        cancelUpload();
    } catch (error) {
        console.error('Errore nel caricamento del file:', error);
        console.error('Error response:', error.response?.data);
        
        // Mostra errori di validazione dettagliati
        let errorMessage = t('media.upload_error') || 'Errore nel caricamento del file';
        if (error.response?.data?.errors) {
            const errors = error.response.data.errors;
            const errorList = Object.keys(errors).map(key => {
                const fieldErrors = Array.isArray(errors[key]) ? errors[key] : [errors[key]];
                return `${key}: ${fieldErrors.join(', ')}`;
            }).join('\n');
            errorMessage = errorMessage + '\n\n' + errorList;
            
            // Aggiungi informazioni di debug se disponibili
            if (error.response.data.debug) {
                errorMessage += '\n\nDebug:\n';
                errorMessage += `- File ricevuto: ${error.response.data.debug.has_file ? 'Sì' : 'No'}\n`;
                errorMessage += `- Dimensione file: ${error.response.data.debug.file_size ? (error.response.data.debug.file_size / 1024 / 1024).toFixed(2) + ' MB' : 'N/A'}\n`;
                errorMessage += `- post_max_size PHP: ${error.response.data.debug.post_max_size}\n`;
                errorMessage += `- upload_max_filesize PHP: ${error.response.data.debug.upload_max_filesize}`;
            }
        } else if (error.response?.data?.message) {
            errorMessage = error.response.data.message;
        }
        
        alert(errorMessage);
    } finally {
        uploading.value = false;
    }
};

const cancelUpload = () => {
    showUpload.value = false;
    selectedFile.value = null;
    uploadDescription.value = '';
    uploadType.value = 'foto';
    if (document.querySelector('input[type="file"]')) {
        document.querySelector('input[type="file"]').value = '';
    }
};

const deleteMedia = async (media) => {
    const confirmMessage = t('media.delete_confirm') || 'Sei sicuro di voler eliminare questo media?';
    if (!confirm(confirmMessage)) {
        return;
    }

    try {
        await mediaService.delete(props.personaId, media.id);
        await loadMedia();
    } catch (error) {
        console.error('Errore nell\'eliminazione del media:', error);
        const errorMessage = t('media.delete_error') || 'Errore nell\'eliminazione del media';
        alert(errorMessage);
    }
};

const getMediaUrl = (media) => {
    return `/storage/${media.percorso}`;
};

const openLightbox = (media) => {
    lightboxMedia.value = media;
};

const closeLightbox = () => {
    lightboxMedia.value = null;
};

const downloadMedia = (media) => {
    const url = getMediaUrl(media);
    const link = document.createElement('a');
    link.href = url;
    link.download = media.nome_file;
    link.click();
};

const formatFileSize = (bytes) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
};

onMounted(() => {
    loadMedia();
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});

watch(() => props.personaId, () => {
    loadMedia();
});
</script>

