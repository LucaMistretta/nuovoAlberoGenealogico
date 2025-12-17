<template>
    <div>
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Tipi di Legame</h1>
            <router-link
                to="/tipi-legame/create"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
                Crea Tipo di Legame
            </router-link>
        </div>

        <div v-if="store.loading" class="text-center py-8">
            <p class="text-gray-600 dark:text-gray-400">Caricamento...</p>
        </div>

        <div v-else-if="store.error" class="bg-red-100 dark:bg-red-900 border border-red-400 text-red-700 dark:text-red-300 px-4 py-3 rounded">
            {{ store.error }}
        </div>

        <div v-else-if="store.tipiLegame.length === 0" class="text-center py-8">
            <p class="text-gray-600 dark:text-gray-400">Nessun tipo di legame trovato</p>
        </div>

        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div
                v-for="tipo in store.tipiLegame"
                :key="tipo.id"
                class="bg-white dark:bg-gray-800 rounded-lg shadow p-4"
            >
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{{ tipo.nome }}</h3>
                <p v-if="tipo.descrizione" class="text-sm text-gray-600 dark:text-gray-400 mt-2">
                    {{ tipo.descrizione }}
                </p>
                <div class="mt-4 flex space-x-2">
                    <router-link
                        :to="`/tipi-legame/${tipo.id}/edit`"
                        class="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm"
                    >
                        Modifica
                    </router-link>
                    <button
                        @click="handleDelete(tipo.id)"
                        class="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700 text-sm"
                    >
                        Elimina
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { onMounted } from 'vue';
import { useTipiLegameStore } from '../../stores/tipiLegame';

const store = useTipiLegameStore();

onMounted(() => {
    store.fetchTipiLegame();
});

const handleDelete = async (id) => {
    if (confirm('Sei sicuro di voler eliminare questo tipo di legame?')) {
        await store.deleteTipoLegame(id);
        store.fetchTipiLegame();
    }
};
</script>

