<template>
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
        <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
            <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
            </svg>
            {{ t('tag.tags') }}
        </h3>

        <div v-if="showAddTag" class="mb-4 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600">
            <select
                v-model="selectedTagId"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white mb-2"
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
            <div class="flex gap-2">
                <button
                    @click="addTag"
                    :disabled="!selectedTagId"
                    class="px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
                >
                    {{ t('tag.add') }}
                </button>
                <button
                    @click="showAddTag = false"
                    class="px-3 py-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 transition-colors"
                >
                    {{ t('common.cancel') }}
                </button>
            </div>
        </div>

        <button
            v-else
            @click="showAddTag = true; loadTags()"
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
                :style="{ backgroundColor: tag.colore + '20', color: tag.colore, borderColor: tag.colore }"
                style="border: 1px solid;"
            >
                {{ tag.nome }}
                <button
                    @click="removeTag(tag)"
                    class="hover:opacity-70 transition-opacity"
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
        showAddTag.value = false;
        selectedTagId.value = '';
    } catch (error) {
        console.error('Errore nell\'aggiunta del tag:', error);
    }
};

const removeTag = async (tag) => {
    try {
        await tagService.detachFromPersona(props.personaId, tag.id);
        emit('tags-updated');
    } catch (error) {
        console.error('Errore nella rimozione del tag:', error);
    }
};

onMounted(() => {
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});
</script>

