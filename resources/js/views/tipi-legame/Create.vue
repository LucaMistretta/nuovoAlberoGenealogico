<template>
    <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Crea Tipo di Legame</h1>
        
        <form @submit.prevent="handleSubmit" class="max-w-2xl space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Nome</label>
                <input
                    v-model="form.nome"
                    type="text"
                    required
                    class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Descrizione</label>
                <textarea
                    v-model="form.descrizione"
                    rows="3"
                    class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                ></textarea>
            </div>

            <div class="flex space-x-4">
                <button
                    type="submit"
                    :disabled="loading"
                    class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                >
                    {{ loading ? 'Salvataggio...' : 'Salva' }}
                </button>
                <router-link
                    to="/tipi-legame"
                    class="px-4 py-2 bg-gray-300 dark:bg-gray-600 text-gray-900 dark:text-white rounded-lg hover:bg-gray-400 dark:hover:bg-gray-700"
                >
                    Annulla
                </router-link>
            </div>
        </form>
    </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useTipiLegameStore } from '../../stores/tipiLegame';

const router = useRouter();
const store = useTipiLegameStore();

const form = ref({
    nome: '',
    descrizione: '',
});

const loading = ref(false);

const handleSubmit = async () => {
    loading.value = true;
    const result = await store.createTipoLegame(form.value);
    
    if (result.success) {
        router.push('/tipi-legame');
    }
    
    loading.value = false;
};
</script>

