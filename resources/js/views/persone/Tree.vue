<template>
    <div class="bg-gray-50 dark:bg-gray-900 py-8">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <!-- Header -->
            <div class="mb-6 flex justify-between items-center">
                <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Albero Genealogico</h1>
                <button
                    @click="$router.push('/persone')"
                    class="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
                >
                    Torna alla Lista
                </button>
            </div>

            <!-- Loading -->
            <div v-if="loading" class="text-center py-12">
                <p class="text-gray-600 dark:text-gray-400">Caricamento albero genealogico...</p>
            </div>

            <!-- Error -->
            <div v-else-if="error" class="bg-red-100 dark:bg-red-900 border border-red-400 text-red-700 dark:text-red-300 px-4 py-3 rounded">
                {{ error }}
            </div>

            <!-- Tree -->
            <div v-else-if="albero" class="overflow-x-auto">
                <div class="inline-block min-w-full">
                    <div class="flex flex-col items-center py-8">
                        <TreeNode :node="albero" :level="0" @navigate="navigateToPersona" />
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { personaService } from '../../services/personaService';
import TreeNode from '../../components/persone/TreeNode.vue';

const route = useRoute();
const router = useRouter();

const loading = ref(true);
const error = ref(null);
const albero = ref(null);

const loadTree = async () => {
    loading.value = true;
    error.value = null;

    try {
        let personaRadice = null;

        // Se c'è un ID nella route, usa quello
        if (route.params.id) {
            const personaById = await personaService.getById(route.params.id);
            personaRadice = personaById.data;
        } else {
            // Cerca "MISTRETTA GIUSEPPE sen." per nome
            const response = await personaService.getAllPeople();
            
            // Laravel Resource Collection restituisce { data: [...] }
            let persone = response.data;
            
            // Se non è un array, prova a estrarre da data.data
            if (!Array.isArray(persone)) {
                persone = persone?.data || [];
            }
            
            // Assicurati che sia un array
            if (!Array.isArray(persone)) {
                console.warn('Risposta API non valida:', response);
                persone = [];
            }
            
            // Trova la persona radice "MISTRETTA GIUSEPPE sen."
            personaRadice = persone.find(p => {
                if (!p) return false;
                const cognome = (p.cognome || '').toLowerCase();
                const nome = (p.nome || '').toLowerCase();
                const nomeCompleto = (p.nome_completo || '').toLowerCase();
                
                return (cognome.includes('mistretta') && nome.includes('giuseppe')) ||
                       nomeCompleto.includes('mistretta giuseppe');
            });

            // Se non trovata, usa la prima persona senza genitori
            if (!personaRadice) {
                const treeResponse = await personaService.getAllForTree();
                personaRadice = treeResponse.data?.radice || null;
            }
        }

        if (!personaRadice || !personaRadice.id) {
            throw new Error('Persona radice non trovata. Verifica che "MISTRETTA GIUSEPPE sen." esista nel database.');
        }

        // Carica l'albero partendo dalla persona radice
        const treeResponse = await personaService.getTreeFromPerson(personaRadice.id);
        albero.value = treeResponse.data;
    } catch (err) {
        error.value = err.response?.data?.message || err.message || 'Errore nel caricamento dell\'albero genealogico';
        console.error('Errore:', err);
    } finally {
        loading.value = false;
    }
};

const navigateToPersona = (id) => {
    router.push(`/persone/${id}`);
};

onMounted(() => {
    loadTree();
});
</script>

