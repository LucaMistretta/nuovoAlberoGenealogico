<template>
    <aside class="w-64 bg-gray-300 dark:bg-gray-800 min-h-screen p-4">
        <nav class="space-y-2 bg-gray-300 dark:bg-gray-800">
            <router-link
                to="/persone"
                class="block px-4 py-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                :class="{ 'bg-blue-500 text-white': isPersoneActive }"
            >
                {{ t('menu.persone') }}
            </router-link>
            <router-link
                to="/tipi-legame"
                class="block px-4 py-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                :class="{ 'bg-blue-500 text-white': isTipiLegameActive }"
            >
                {{ t('menu.tipi_legame') }}
            </router-link>
        </nav>
    </aside>
</template>

<script setup>
import { computed, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useLocaleStore } from '../../stores/locale';

const route = useRoute();
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

const isPersoneActive = computed(() => {
    return route.path.startsWith('/persone');
});

const isTipiLegameActive = computed(() => {
    return route.path.startsWith('/tipi-legame');
});
</script>

