<template>
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-base font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {{ t('eventi.timeline') }}
            </h3>
            <button
                v-if="!showForm"
                @click="showForm = true; editingEvento = null"
                class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
            >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
                {{ t('eventi.add') }}
            </button>
        </div>

        <!-- Form Evento -->
        <div v-if="showForm" class="mb-4 p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600">
            <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-3">
                {{ editingEvento ? t('eventi.edit_event') : t('eventi.new_event') }}
            </h4>
            <div class="space-y-3">
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('eventi.event_type') }} *
                    </label>
                    <select
                        v-model="form.tipo_evento"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    >
                        <option value="">{{ t('eventi.select_type') }}</option>
                        <option value="nascita">{{ t('eventi.birth') }}</option>
                        <option value="battesimo">{{ t('eventi.baptism') }}</option>
                        <option value="comunione">{{ t('eventi.communion') }}</option>
                        <option value="cresima">{{ t('eventi.confirmation') }}</option>
                        <option value="matrimonio">{{ t('eventi.marriage') }}</option>
                        <option value="divorzio">{{ t('eventi.divorce') }}</option>
                        <option value="morte">{{ t('eventi.death') }}</option>
                        <option value="sepoltura">{{ t('eventi.burial') }}</option>
                        <option value="laurea">{{ t('eventi.graduation') }}</option>
                        <option value="lavoro">{{ t('eventi.work') }}</option>
                        <option value="pensione">{{ t('eventi.retirement') }}</option>
                        <option value="altro">{{ t('eventi.other') }}</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('eventi.title') }} *
                    </label>
                    <input
                        v-model="form.titolo"
                        type="text"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        :placeholder="t('eventi.title_placeholder')"
                    />
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('eventi.description') }}
                    </label>
                    <textarea
                        v-model="form.descrizione"
                        rows="2"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        :placeholder="t('eventi.description_placeholder')"
                    ></textarea>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                            {{ t('eventi.date') }}
                        </label>
                        <input
                            v-model="form.data_evento"
                            type="date"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        />
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                            {{ t('eventi.place') }}
                        </label>
                        <input
                            v-model="form.luogo"
                            type="text"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                            :placeholder="t('eventi.place_placeholder')"
                        />
                    </div>
                </div>
                <div>
                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                        {{ t('eventi.notes') }}
                    </label>
                    <textarea
                        v-model="form.note"
                        rows="2"
                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        :placeholder="t('eventi.notes_placeholder')"
                    ></textarea>
                </div>
                <div class="flex gap-2">
                    <button
                        @click="handleSave"
                        :disabled="!form.tipo_evento || !form.titolo || saving"
                        class="flex-1 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                        <span v-if="!saving">{{ t('common.save') }}</span>
                        <span v-else class="flex items-center justify-center gap-2">
                            <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            {{ t('common.loading') }}
                        </span>
                    </button>
                    <button
                        @click="cancelForm"
                        class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-700 transition-colors"
                    >
                        {{ t('common.cancel') }}
                    </button>
                </div>
            </div>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="flex items-center justify-center py-8">
            <div class="text-center">
                <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mb-2"></div>
                <p class="text-sm text-gray-600 dark:text-gray-400">{{ t('common.loading') }}</p>
            </div>
        </div>

        <!-- Timeline -->
        <div v-else-if="eventi.length === 0" class="text-center py-8">
            <svg class="w-12 h-12 text-gray-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('eventi.no_events') }}</p>
        </div>

        <div v-else class="relative">
            <!-- Linea verticale -->
            <div class="absolute left-4 top-0 bottom-0 w-0.5 bg-gray-300 dark:bg-gray-600"></div>
            
            <div class="space-y-4">
                <div
                    v-for="evento in sortedEventi"
                    :key="evento.id"
                    class="relative pl-10"
                >
                    <!-- Punto sulla timeline -->
                    <div class="absolute left-2 top-2 w-4 h-4 bg-blue-600 rounded-full border-2 border-white dark:border-gray-800"></div>
                    
                    <!-- Card evento -->
                    <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3 border border-gray-200 dark:border-gray-600 hover:border-blue-500 dark:hover:border-blue-500 transition-colors">
                        <div class="flex items-start justify-between">
                            <div class="flex-1">
                                <div class="flex items-center gap-2 mb-1">
                                    <span class="text-xs font-semibold px-2 py-0.5 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded">
                                        {{ getEventTypeLabel(evento.tipo_evento) }}
                                    </span>
                                    <span v-if="evento.data_evento" class="text-xs text-gray-500 dark:text-gray-400">
                                        {{ formatDate(evento.data_evento) }}
                                    </span>
                                </div>
                                <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                                    {{ evento.titolo }}
                                </h4>
                                <p v-if="evento.descrizione" class="text-xs text-gray-600 dark:text-gray-400 mb-1">
                                    {{ evento.descrizione }}
                                </p>
                                <div v-if="evento.luogo" class="flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400 mb-1">
                                    <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                                    </svg>
                                    {{ evento.luogo }}
                                </div>
                                <p v-if="evento.note" class="text-xs text-gray-500 dark:text-gray-400 italic">
                                    {{ evento.note }}
                                </p>
                            </div>
                            <div class="flex gap-1 ml-2">
                                <button
                                    @click="editEvento(evento)"
                                    class="p-1 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-900/30 rounded transition-colors"
                                    :title="t('common.edit')"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                    </svg>
                                </button>
                                <button
                                    @click="deleteEvento(evento)"
                                    class="p-1 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded transition-colors"
                                    :title="t('common.delete')"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                    </svg>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { eventoService } from '../../services/eventoService';
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

const eventi = ref([]);
const loading = ref(false);
const showForm = ref(false);
const editingEvento = ref(null);
const saving = ref(false);

const form = ref({
    tipo_evento: '',
    titolo: '',
    descrizione: '',
    data_evento: '',
    luogo: '',
    note: '',
});

const sortedEventi = computed(() => {
    return [...eventi.value].sort((a, b) => {
        if (!a.data_evento && !b.data_evento) return 0;
        if (!a.data_evento) return 1;
        if (!b.data_evento) return -1;
        return new Date(b.data_evento) - new Date(a.data_evento);
    });
});

const loadEventi = async () => {
    loading.value = true;
    try {
        const response = await eventoService.getByPersona(props.personaId);
        eventi.value = response.data || [];
    } catch (error) {
        console.error('Errore nel caricamento degli eventi:', error);
    } finally {
        loading.value = false;
    }
};

const handleSave = async () => {
    if (!form.value.tipo_evento || !form.value.titolo) return;

    saving.value = true;
    try {
        if (editingEvento.value) {
            await eventoService.update(props.personaId, editingEvento.value.id, form.value);
        } else {
            await eventoService.create(props.personaId, form.value);
        }
        await loadEventi();
        cancelForm();
    } catch (error) {
        console.error('Errore nel salvataggio dell\'evento:', error);
        const errorMessage = t('eventi.save_error') || 'Errore nel salvataggio dell\'evento';
        alert(errorMessage);
    } finally {
        saving.value = false;
    }
};

const editEvento = (evento) => {
    editingEvento.value = evento;
    form.value = {
        tipo_evento: evento.tipo_evento,
        titolo: evento.titolo,
        descrizione: evento.descrizione || '',
        data_evento: evento.data_evento || '',
        luogo: evento.luogo || '',
        note: evento.note || '',
    };
    showForm.value = true;
};

const deleteEvento = async (evento) => {
    const confirmMessage = t('eventi.delete_confirm') || 'Sei sicuro di voler eliminare questo evento?';
    if (!confirm(confirmMessage)) {
        return;
    }

    try {
        await eventoService.delete(props.personaId, evento.id);
        await loadEventi();
    } catch (error) {
        console.error('Errore nell\'eliminazione dell\'evento:', error);
        const errorMessage = t('eventi.delete_error') || 'Errore nell\'eliminazione dell\'evento';
        alert(errorMessage);
    }
};

const cancelForm = () => {
    showForm.value = false;
    editingEvento.value = null;
    form.value = {
        tipo_evento: '',
        titolo: '',
        descrizione: '',
        data_evento: '',
        luogo: '',
        note: '',
    };
};

const formatDate = (dateString) => {
    if (!dateString) return '';
    try {
        const date = new Date(dateString);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    } catch (e) {
        return dateString;
    }
};

const getEventTypeLabel = (tipo) => {
    const labels = {
        nascita: t('eventi.birth'),
        battesimo: t('eventi.baptism'),
        comunione: t('eventi.communion'),
        cresima: t('eventi.confirmation'),
        matrimonio: t('eventi.marriage'),
        divorzio: t('eventi.divorce'),
        morte: t('eventi.death'),
        sepoltura: t('eventi.burial'),
        laurea: t('eventi.graduation'),
        lavoro: t('eventi.work'),
        pensione: t('eventi.retirement'),
        altro: t('eventi.other'),
    };
    return labels[tipo] || tipo;
};

onMounted(() => {
    loadEventi();
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});

watch(() => props.personaId, () => {
    loadEventi();
});
</script>

