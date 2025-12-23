<template>
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <div class="flex items-start justify-between mb-3">
            <div>
                <h3 class="text-base font-semibold text-gray-900 dark:text-white flex items-center gap-2 mb-1">
                    <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                    </svg>
                    {{ t('tag.tags') }}
                </h3>
                <p class="text-xs text-gray-500 dark:text-gray-400">
                    {{ t('tag.description') }}
                </p>
            </div>
        </div>

        <!-- Form per aggiungere tag esistente o crearne uno nuovo -->
        <div v-if="showAddTag" class="mb-4 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600">
            <div class="mb-3">
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                    {{ t('tag.select_existing') }}
                </label>
                <select
                    v-model="selectedTagId"
                    class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                >
                    <option value="">{{ t('tag.select_tag') }}</option>
                    <option
                        v-for="tag in availableTags"
                        :key="tag.id"
                        :value="tag.id"
                        :disabled="personaTags.some(pt => pt.id === tag.id)"
                    >
                        {{ tag.nome }}
                    </option>
                </select>
            </div>

            <div class="mb-3 border-t border-gray-300 dark:border-gray-600 pt-3">
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                    {{ t('tag.or_create_new') }}
                </label>
                <div class="flex gap-2">
                    <input
                        v-model="newTagName"
                        type="text"
                        :placeholder="t('tag.new_tag_placeholder')"
                        class="flex-1 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        @keyup.enter="createAndAddTag"
                    />
                    <input
                        v-model="newTagColor"
                        type="color"
                        class="w-12 h-10 border border-gray-300 dark:border-gray-600 rounded-lg cursor-pointer"
                        title="{{ t('tag.color') }}"
                    />
                </div>
            </div>

            <div class="flex gap-2">
                <button
                    v-if="selectedTagId"
                    @click="addTag"
                    class="flex-1 px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
                >
                    {{ t('tag.add') }}
                </button>
                <button
                    v-else-if="newTagName"
                    @click="createAndAddTag"
                    :disabled="creatingTag"
                    class="flex-1 px-3 py-1.5 text-sm font-medium text-white bg-green-600 rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors"
                >
                    <span v-if="!creatingTag">{{ t('tag.create_and_add') }}</span>
                    <span v-else class="flex items-center justify-center gap-2">
                        <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        {{ t('common.loading') }}
                    </span>
                </button>
                <button
                    @click="cancelAddTag"
                    class="px-3 py-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 transition-colors"
                >
                    {{ t('common.cancel') }}
                </button>
            </div>

            <div v-if="availableTags.length === 0 && !newTagName" class="mt-2 text-xs text-gray-500 dark:text-gray-400 text-center">
                {{ t('tag.no_tags_available') }}
            </div>
        </div>

        <button
            v-else
            @click="showAddTagForm"
            class="w-full mb-4 px-3 py-2 text-sm font-medium text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors"
        >
            + {{ t('tag.add_tag') }}
        </button>

        <div v-if="personaTags.length === 0" class="text-center py-4 text-sm text-gray-500 dark:text-gray-400">
            {{ t('tag.no_tags') }}
        </div>

        <div v-else class="flex flex-wrap gap-2">
            <span
                v-for="tag in personaTags"
                :key="tag.id"
                class="inline-flex items-center gap-1.5 px-3 py-1 text-xs font-medium rounded-full"
                :style="{ backgroundColor: (tag.colore || '#3b82f6') + '20', color: tag.colore || '#3b82f6', borderColor: tag.colore || '#3b82f6' }"
                style="border: 1px solid;"
            >
                {{ tag.nome }}
                <button
                    @click="removeTag(tag)"
                    class="hover:opacity-70 transition-opacity"
                    :title="t('tag.remove')"
                >
                    <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </span>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { tagService } from '../../services/tagService';
import { useLocaleStore } from '../../stores/locale';

const props = defineProps({
    personaId: {
        type: Number,
        required: true,
    },
    personaTags: {
        type: Array,
        default: () => [],
    },
});

const emit = defineEmits(['tags-updated']);

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

const showAddTag = ref(false);
const selectedTagId = ref('');
const availableTags = ref([]);
const newTagName = ref('');
const newTagColor = ref('#3b82f6');
const creatingTag = ref(false);

const showAddTagForm = async () => {
    showAddTag.value = true;
    await loadTags();
};

const cancelAddTag = () => {
    showAddTag.value = false;
    selectedTagId.value = '';
    newTagName.value = '';
    newTagColor.value = '#3b82f6';
};

const loadTags = async () => {
    try {
        const response = await tagService.getAll();
        availableTags.value = response.data || [];
    } catch (error) {
        console.error('Errore nel caricamento dei tag:', error);
    }
};

const addTag = async () => {
    if (!selectedTagId.value) return;
    try {
        await tagService.attachToPersona(props.personaId, selectedTagId.value);
        emit('tags-updated');
        cancelAddTag();
    } catch (error) {
        console.error('Errore nell\'aggiunta del tag:', error);
        alert(t('tag.add_error') || 'Errore nell\'aggiunta del tag');
    }
};

const createAndAddTag = async () => {
    if (!newTagName.value.trim()) return;
    
    creatingTag.value = true;
    try {
        // Crea il nuovo tag
        const createResponse = await tagService.create({
            nome: newTagName.value.trim(),
            colore: newTagColor.value
        });
        
        const newTag = createResponse.data;
        
        // Aggiungi il tag alla persona
        await tagService.attachToPersona(props.personaId, newTag.id);
        
        // Ricarica i tag disponibili
        await loadTags();
        
        emit('tags-updated');
        cancelAddTag();
    } catch (error) {
        console.error('Errore nella creazione del tag:', error);
        const errorMessage = error.response?.data?.message || error.response?.data?.errors?.nome?.[0] || t('tag.create_error') || 'Errore nella creazione del tag';
        alert(errorMessage);
    } finally {
        creatingTag.value = false;
    }
};

const removeTag = async (tag) => {
    if (!confirm(t('tag.remove_confirm') || `Rimuovere il tag "${tag.nome}"?`)) {
        return;
    }
    
    try {
        await tagService.detachFromPersona(props.personaId, tag.id);
        emit('tags-updated');
    } catch (error) {
        console.error('Errore nella rimozione del tag:', error);
        alert(t('tag.remove_error') || 'Errore nella rimozione del tag');
    }
};

onMounted(() => {
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});
</script>


