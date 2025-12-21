<template>
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
            <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
            {{ t('note.notes') }}
        </h3>

        <div v-if="showForm" class="mb-4 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600">
            <textarea
                v-model="form.contenuto"
                rows="3"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white mb-2"
                :placeholder="t('note.placeholder')"
            ></textarea>
            <div class="flex gap-2">
                <button
                    @click="handleSave"
                    :disabled="!form.contenuto.trim() || saving"
                    class="px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
                >
                    {{ t('common.save') }}
                </button>
                <button
                    @click="cancelForm"
                    class="px-3 py-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 transition-colors"
                >
                    {{ t('common.cancel') }}
                </button>
            </div>
        </div>

        <button
            v-else
            @click="showForm = true"
            class="w-full mb-4 px-3 py-2 text-sm font-medium text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors"
        >
            + {{ t('note.add_note') }}
        </button>

        <div v-if="loading" class="text-center py-4">
            <div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
        </div>

        <div v-else-if="note.length === 0" class="text-center py-4 text-sm text-gray-500 dark:text-gray-400">
            {{ t('note.no_notes') }}
        </div>

        <div v-else class="space-y-2">
            <div
                v-for="nota in note"
                :key="nota.id"
                class="p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600"
            >
                <div class="flex items-start justify-between mb-1">
                    <span v-if="nota.user" class="text-xs text-gray-500 dark:text-gray-400">
                        {{ nota.user.name }} - {{ formatDate(nota.created_at) }}
                    </span>
                    <div class="flex gap-1">
                        <button
                            @click="editNota(nota)"
                            class="p-1 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-900/30 rounded"
                        >
                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                        </button>
                        <button
                            @click="deleteNota(nota)"
                            class="p-1 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded"
                        >
                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                        </button>
                    </div>
                </div>
                <p class="text-sm text-gray-900 dark:text-white whitespace-pre-wrap">{{ nota.contenuto }}</p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { notaService } from '../../services/notaService';
import { useLocaleStore } from '../../stores/locale';

const props = defineProps({
    personaId: {
        type: Number,
        required: true,
    },
});

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

const note = ref([]);
const loading = ref(false);
const showForm = ref(false);
const saving = ref(false);
const editingNota = ref(null);

const form = ref({ contenuto: '' });

const loadNote = async () => {
    loading.value = true;
    try {
        const response = await notaService.getByPersona(props.personaId);
        note.value = response.data || [];
    } catch (error) {
        console.error('Errore nel caricamento delle note:', error);
    } finally {
        loading.value = false;
    }
};

const handleSave = async () => {
    if (!form.value.contenuto.trim()) return;
    saving.value = true;
    try {
        if (editingNota.value) {
            await notaService.update(props.personaId, editingNota.value.id, form.value.contenuto);
        } else {
            await notaService.create(props.personaId, form.value.contenuto);
        }
        await loadNote();
        cancelForm();
    } catch (error) {
        console.error('Errore nel salvataggio della nota:', error);
    } finally {
        saving.value = false;
    }
};

const editNota = (nota) => {
    editingNota.value = nota;
    form.value.contenuto = nota.contenuto;
    showForm.value = true;
};

const deleteNota = async (nota) => {
    const confirmMessage = t('note.delete_confirm') || 'Eliminare questa nota?';
    if (!confirm(confirmMessage)) return;
    try {
        await notaService.delete(props.personaId, nota.id);
        await loadNote();
    } catch (error) {
        console.error('Errore nell\'eliminazione della nota:', error);
    }
};

const cancelForm = () => {
    showForm.value = false;
    editingNota.value = null;
    form.value.contenuto = '';
};

const formatDate = (dateString) => {
    if (!dateString) return '';
    try {
        const date = new Date(dateString);
        return date.toLocaleDateString('it-IT');
    } catch (e) {
        return dateString;
    }
};

onMounted(() => {
    loadNote();
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});

watch(() => props.personaId, () => {
    loadNote();
});
</script>

