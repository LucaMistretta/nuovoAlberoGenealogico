<template>
    <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Crea Persona</h1>
        
        <!-- Messaggio informativo se si sta creando una relazione -->
        <div v-if="relazionePersonaId && relazioneTipo" class="mb-6 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
            <div class="flex items-start gap-3">
                <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <div>
                    <p class="text-sm font-medium text-blue-900 dark:text-blue-300">
                        Stai creando un nuovo {{ relazioneTipo === 'coniuge' ? 'consorte' : 'figlio' }}
                    </p>
                    <p class="text-sm text-blue-700 dark:text-blue-400 mt-1">
                        Dopo il salvataggio, tornerai automaticamente alla pagina di modifica della persona originale e la nuova persona sarà già collegata.
                    </p>
                </div>
            </div>
        </div>
        
        <form @submit.prevent="handleSubmit" class="max-w-2xl space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Nome</label>
                <input
                    v-model="form.nome"
                    type="text"
                    class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Cognome</label>
                <input
                    v-model="form.cognome"
                    type="text"
                    class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Nato a</label>
                <input
                    v-model="form.nato_a"
                    type="text"
                    class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Nato il</label>
                <input
                    v-model="form.nato_il"
                    type="date"
                    class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Deceduto a</label>
                <input
                    v-model="form.deceduto_a"
                    type="text"
                    class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Deceduto il</label>
                <input
                    v-model="form.deceduto_il"
                    type="date"
                    class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
            </div>

            <!-- Sezione Relazioni Familiari -->
            <div class="border-t border-gray-200 dark:border-gray-700 pt-6 mt-6">
                <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Relazioni Familiari</h2>
                
                <div class="space-y-6">
                    <!-- Genitori -->
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">Genitori</h3>
                        </div>
                        
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <!-- Padre -->
                            <div>
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Padre</label>
                                <SearchableSelect
                                    v-model="selectedPadreId"
                                    :options="sortedAvailablePeople"
                                    option-label="nome_completo"
                                    option-value="id"
                                    placeholder="Cerca padre per nome o cognome..."
                                    empty-option="Seleziona padre esistente..."
                                    select-class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm"
                                >
                                    <template #option="{ option }">
                                        {{ option.nome_completo }} (ID: {{ option.id }})
                                    </template>
                                    <template #actions>
                                        <button
                                            type="button"
                                            @click="creaNuovoPadre"
                                            class="px-3 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors text-sm"
                                            title="Crea nuovo padre"
                                        >
                                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                            </svg>
                                        </button>
                                    </template>
                                </SearchableSelect>
                            </div>
                            
                            <!-- Madre -->
                            <div>
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Madre</label>
                                <SearchableSelect
                                    v-model="selectedMadreId"
                                    :options="sortedAvailablePeople"
                                    option-label="nome_completo"
                                    option-value="id"
                                    placeholder="Cerca madre per nome o cognome..."
                                    empty-option="Seleziona madre esistente..."
                                    select-class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm"
                                >
                                    <template #option="{ option }">
                                        {{ option.nome_completo }} (ID: {{ option.id }})
                                    </template>
                                    <template #actions>
                                        <button
                                            type="button"
                                            @click="creaNuovaMadre"
                                            class="px-3 py-2 bg-pink-600 text-white rounded-md hover:bg-pink-700 transition-colors text-sm"
                                            title="Crea nuova madre"
                                        >
                                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                            </svg>
                                        </button>
                                    </template>
                                </SearchableSelect>
                            </div>
                        </div>
                    </div>

                    <!-- Consorti -->
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">Consorti</h3>
                        </div>
                        
                        <div class="space-y-2">
                            <div v-for="(consorte, index) in selectedConsorti" :key="index" class="p-3 bg-purple-50 dark:bg-purple-900/20 rounded-md space-y-2">
                                <div class="flex items-center gap-2">
                                    <span class="flex-1 text-sm font-semibold text-gray-900 dark:text-white">{{ consorte.nome_completo || consorte.persona?.nome_completo }}</span>
                                    <button
                                        type="button"
                                        @click="removeConsorte(index)"
                                        class="p-1 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded"
                                    >
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                        </svg>
                                    </button>
                                </div>
                                <!-- Campi dettagli legame -->
                                <div class="grid grid-cols-1 md:grid-cols-3 gap-2 mt-2">
                                    <div>
                                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ t('persona.tipo_evento_legame') }}</label>
                                        <select
                                            v-model="consorte.tipo_evento_legame_id"
                                            class="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                                        >
                                            <option value="">{{ t('persona.select') }}</option>
                                            <option v-for="tipo in tipiEventoLegame" :key="tipo.id" :value="tipo.id">
                                                {{ tipo.descrizione || tipo.nome }}
                                            </option>
                                        </select>
                                    </div>
                                    <div>
                                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ t('persona.data_legame') }}</label>
                                        <input
                                            v-model="consorte.data_legame"
                                            type="date"
                                            class="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                                        />
                                    </div>
                                            <div>
                                                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ t('persona.luogo_legame') }}</label>
                                                <input
                                                    v-model="consorte.luogo_legame"
                                                    type="text"
                                                    class="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                                                    :placeholder="t('persona.birth_place_example')"
                                                />
                                            </div>
                                        </div>
                                        <!-- Campi separazione -->
                                        <div class="grid grid-cols-1 md:grid-cols-2 gap-2 mt-2 pt-2 border-t border-purple-200 dark:border-purple-800">
                                            <div>
                                                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ t('persona.data_separazione') }}</label>
                                                <input
                                                    v-model="consorte.data_separazione"
                                                    type="date"
                                                    class="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                                                />
                                            </div>
                                            <div>
                                                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ t('persona.luogo_separazione') }}</label>
                                                <input
                                                    v-model="consorte.luogo_separazione"
                                                    type="text"
                                                    class="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                                                    :placeholder="t('persona.birth_place_example')"
                                                />
                                            </div>
                                        </div>
                                    </div>
                            
                            <SearchableSelect
                                v-model="newConsorteId"
                                :options="sortedAvailablePeople"
                                option-label="nome_completo"
                                option-value="id"
                                placeholder="Cerca consorte per nome o cognome..."
                                empty-option="Seleziona consorte esistente..."
                                :disabled="selectedConsortiIds"
                                select-class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm"
                            >
                                <template #option="{ option }">
                                    {{ option.nome_completo }} (ID: {{ option.id }})
                                </template>
                                <template #actions>
                                    <button
                                        type="button"
                                        @click="addConsorte"
                                        :disabled="!newConsorteId"
                                        class="px-3 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm"
                                    >
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                        </svg>
                                    </button>
                                    <button
                                        type="button"
                                        @click="creaNuovoConsorte"
                                        class="px-3 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 transition-colors text-sm"
                                        title="Crea nuovo consorte"
                                    >
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                        </svg>
                                    </button>
                                </template>
                            </SearchableSelect>
                        </div>
                    </div>

                    <!-- Figli -->
                    <div>
                        <div class="flex items-center justify-between mb-3">
                            <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">Figli</h3>
                        </div>
                        
                        <div class="space-y-2">
                            <div v-for="(figlio, index) in selectedFigli" :key="index" class="flex items-center gap-2 p-2 bg-green-50 dark:bg-green-900/20 rounded-md">
                                <span class="flex-1 text-sm text-gray-900 dark:text-white">{{ figlio.nome_completo }}</span>
                                <button
                                    type="button"
                                    @click="removeFiglio(index)"
                                    class="p-1 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                    </svg>
                                </button>
                            </div>
                            
                            <SearchableSelect
                                v-model="newFiglioId"
                                :options="sortedAvailablePeople"
                                option-label="nome_completo"
                                option-value="id"
                                placeholder="Cerca figlio per nome o cognome..."
                                empty-option="Seleziona figlio esistente..."
                                :disabled="selectedFigliIds"
                                select-class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm"
                            >
                                <template #option="{ option }">
                                    {{ option.nome_completo }} (ID: {{ option.id }})
                                </template>
                                <template #actions>
                                    <button
                                        type="button"
                                        @click="addFiglio"
                                        :disabled="!newFiglioId"
                                        class="px-3 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm"
                                    >
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                        </svg>
                                    </button>
                                    <button
                                        type="button"
                                        @click="creaNuovoFiglio"
                                        class="px-3 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors text-sm"
                                        title="Crea nuovo figlio"
                                    >
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                        </svg>
                                    </button>
                                </template>
                            </SearchableSelect>
                        </div>
                    </div>
                </div>
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
                    :to="returnTo"
                    class="px-4 py-2 bg-gray-300 dark:bg-gray-600 text-gray-900 dark:text-white rounded-lg hover:bg-gray-400 dark:hover:bg-gray-700"
                >
                    Annulla
                </router-link>
            </div>
        </form>
    </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { usePersoneStore } from '../../stores/persone';
import { useLocaleStore } from '../../stores/locale';
import { personaService } from '../../services/personaService';
import { tipoLegameService } from '../../services/tipoLegameService';
import { tipoEventoLegameService } from '../../services/tipoEventoLegameService';
import SearchableSelect from '../../components/common/SearchableSelect.vue';

const route = useRoute();
const router = useRouter();
const store = usePersoneStore();
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

const form = ref({
    nome: '',
    cognome: '',
    nato_a: '',
    nato_il: '',
    deceduto_a: '',
    deceduto_il: '',
});

const loading = ref(false);
const tipiLegame = ref([]);
const tipiEventoLegame = ref([]);
const availablePeople = ref([]);

// Relazioni selezionate
const selectedPadreId = ref('');
const selectedMadreId = ref('');
const selectedConsorti = ref([]);
const selectedFigli = ref([]);
const newConsorteId = ref('');
const newFiglioId = ref('');

// Computed per gli ID selezionati
const selectedConsortiIds = computed(() => selectedConsorti.value.map(c => c.id || c.persona?.id));
const selectedFigliIds = computed(() => selectedFigli.value.map(f => f.id));

// Computed per ordinare le persone per cognome e poi nome
const sortedAvailablePeople = computed(() => {
    return [...availablePeople.value].sort((a, b) => {
        const cognomeA = (a.cognome || '').toLowerCase();
        const cognomeB = (b.cognome || '').toLowerCase();
        if (cognomeA !== cognomeB) {
            return cognomeA.localeCompare(cognomeB, 'it');
        }
        const nomeA = (a.nome || '').toLowerCase();
        const nomeB = (b.nome || '').toLowerCase();
        return nomeA.localeCompare(nomeB, 'it');
    });
});

// Leggi i parametri dalla query string
const relazionePersonaId = route.query.relazione_persona_id ? parseInt(route.query.relazione_persona_id) : null;
const relazioneTipo = route.query.relazione_tipo; // 'coniuge' o 'figlio'
const returnTo = route.query.return_to || '/persone';

onMounted(async () => {
    // Carica i tipi di legame, tipi evento legame e le persone disponibili
    try {
        const [tipiResponse, tipiEventoResponse, personeResponse] = await Promise.all([
            tipoLegameService.getAll(),
            tipoEventoLegameService.getAll(),
            personaService.getAllPeople()
        ]);
        
        tipiLegame.value = tipiResponse.data.data || tipiResponse.data || [];
        tipiEventoLegame.value = tipiEventoResponse.data || [];
        availablePeople.value = personeResponse.data.data || personeResponse.data || [];
        
        // Se si sta creando una relazione automatica, imposta i valori
        if (relazionePersonaId && relazioneTipo) {
            if (relazioneTipo === 'coniuge') {
                selectedConsorti.value = [{
                    id: relazionePersonaId,
                    nome_completo: 'Persona originale',
                    data_legame: '',
                    luogo_legame: '',
                    tipo_evento_legame_id: '',
                    data_separazione: '',
                    luogo_separazione: ''
                }];
            } else if (relazioneTipo === 'figlio') {
                selectedFigli.value = [{ id: relazionePersonaId, nome_completo: 'Persona originale' }];
            }
        }
    } catch (error) {
        console.error('Errore nel caricamento dei dati:', error);
    }
});

const handleSubmit = async () => {
    loading.value = true;
    
    try {
        // Prepara i genitori (relazioni inverse)
        const genitori = {};
        if (selectedPadreId.value) {
            genitori.padre_id = parseInt(selectedPadreId.value);
        }
        if (selectedMadreId.value) {
            genitori.madre_id = parseInt(selectedMadreId.value);
        }
        
        // Prepara le relazioni da creare (consorti e figli)
        const relazioni = [];
        
        // Aggiungi consorti
        const coniugeTipo = tipiLegame.value.find(t => t.nome === 'coniuge');
        if (coniugeTipo) {
            selectedConsorti.value.forEach(consorte => {
                const relazione = {
                    persona_collegata_id: consorte.id || consorte.persona?.id,
                    tipo_legame_id: coniugeTipo.id,
                };
                
                // Aggiungi dettagli del legame se presenti
                if (consorte.data_legame) {
                    relazione.data_legame = consorte.data_legame;
                }
                if (consorte.luogo_legame) {
                    relazione.luogo_legame = consorte.luogo_legame;
                }
                if (consorte.tipo_evento_legame_id) {
                    relazione.tipo_evento_legame_id = parseInt(consorte.tipo_evento_legame_id);
                }
                // Aggiungi dettagli della separazione se presenti
                if (consorte.data_separazione) {
                    relazione.data_separazione = consorte.data_separazione;
                }
                if (consorte.luogo_separazione) {
                    relazione.luogo_separazione = consorte.luogo_separazione;
                }
                
                relazioni.push(relazione);
            });
        }
        
        // Aggiungi figli
        const padreTipo = tipiLegame.value.find(t => t.nome === 'padre');
        if (padreTipo) {
            selectedFigli.value.forEach(figlio => {
                relazioni.push({
                    persona_collegata_id: figlio.id,
                    tipo_legame_id: padreTipo.id,
                });
            });
        }
        
        // Prepara i dati con le relazioni
        const dataToSend = {
            ...form.value,
        };
        
        if (Object.keys(genitori).length > 0) {
            dataToSend.genitori = genitori;
        }
        
        if (relazioni.length > 0) {
            dataToSend.relazioni = relazioni;
        }
        
        // Crea la persona
        const result = await store.createPersona(dataToSend);
        
        if (result.success && result.data && result.data.id) {
            const nuovaPersonaId = result.data.id;
            
            // Se ci sono parametri di relazione automatica (da Edit), crea anche quella relazione
            if (relazionePersonaId && relazioneTipo && !relazioni.find(r => r.persona_collegata_id === relazionePersonaId)) {
                await creaRelazioneAutomatica(relazionePersonaId, nuovaPersonaId, relazioneTipo);
            }
            
            // Torna alla pagina specificata o alla lista
            router.push(returnTo);
        } else {
            // Se non c'è relazione, vai alla lista normale
            router.push('/persone');
        }
    } catch (error) {
        console.error('Errore nel salvataggio:', error);
    } finally {
        loading.value = false;
    }
};

// Aggiungi consorte
const addConsorte = () => {
    if (!newConsorteId.value) return;
    
    const persona = sortedAvailablePeople.value.find(p => p.id === parseInt(newConsorteId.value));
    if (persona && !selectedConsortiIds.value.includes(persona.id)) {
        selectedConsorti.value.push({
            id: persona.id,
            nome_completo: persona.nome_completo,
            persona: persona,
            data_legame: '',
            luogo_legame: '',
            tipo_evento_legame_id: '',
            data_separazione: '',
            luogo_separazione: ''
        });
        newConsorteId.value = '';
    }
};

// Rimuovi consorte
const removeConsorte = (index) => {
    selectedConsorti.value.splice(index, 1);
};

// Aggiungi figlio
const addFiglio = () => {
    if (!newFiglioId.value) return;
    
    const persona = sortedAvailablePeople.value.find(p => p.id === parseInt(newFiglioId.value));
    if (persona && !selectedFigliIds.value.includes(persona.id)) {
        selectedFigli.value.push(persona);
        newFiglioId.value = '';
    }
};

// Rimuovi figlio
const removeFiglio = (index) => {
    selectedFigli.value.splice(index, 1);
};

// Crea nuovo padre
const creaNuovoPadre = () => {
    router.push({
        path: '/persone/create',
        query: {
            relazione_persona_id: null, // Sarà impostato dopo la creazione
            relazione_tipo: 'padre',
            return_to: route.fullPath // Torna a questa pagina dopo la creazione
        }
    });
};

// Crea nuova madre
const creaNuovaMadre = () => {
    router.push({
        path: '/persone/create',
        query: {
            relazione_persona_id: null,
            relazione_tipo: 'madre',
            return_to: route.fullPath
        }
    });
};

// Crea nuovo consorte
const creaNuovoConsorte = () => {
    router.push({
        path: '/persone/create',
        query: {
            relazione_persona_id: null,
            relazione_tipo: 'coniuge',
            return_to: route.fullPath
        }
    });
};

// Crea nuovo figlio
const creaNuovoFiglio = () => {
    router.push({
        path: '/persone/create',
        query: {
            relazione_persona_id: null,
            relazione_tipo: 'figlio',
            return_to: route.fullPath
        }
    });
};

// Crea la relazione automatica (quando si crea da Edit)
const creaRelazioneAutomatica = async (personaId, personaCollegataId, tipoRelazione) => {
    try {
        // Carica la persona originale per ottenere le relazioni esistenti
        const personaResponse = await personaService.getById(personaId);
        const persona = personaResponse.data;
        
        // Prepara i genitori esistenti
        const genitori = {};
        if (persona.padre) {
            genitori.padre_id = persona.padre.id;
        }
        if (persona.madre) {
            genitori.madre_id = persona.madre.id;
        }
        
        // Prepara le relazioni esistenti più la nuova
        const relazioni = [];
        
        // Aggiungi le relazioni esistenti (consorti)
        if (persona.consorti && Array.isArray(persona.consorti)) {
            const coniugeTipo = tipiLegame.value.find(t => t.nome === 'coniuge');
            if (coniugeTipo) {
                persona.consorti.forEach(consorte => {
                    relazioni.push({
                        persona_collegata_id: consorte.id,
                        tipo_legame_id: coniugeTipo.id,
                    });
                });
            }
        }
        
        // Aggiungi le relazioni esistenti (figli)
        if (persona.figli && Array.isArray(persona.figli)) {
            const padreTipo = tipiLegame.value.find(t => t.nome === 'padre');
            if (padreTipo) {
                persona.figli.forEach(figlio => {
                    relazioni.push({
                        persona_collegata_id: figlio.id,
                        tipo_legame_id: padreTipo.id,
                    });
                });
            }
        }
        
        // Aggiungi la nuova relazione
        let tipoLegameId = null;
        if (tipoRelazione === 'coniuge') {
            const tipo = tipiLegame.value.find(t => t.nome === 'coniuge');
            tipoLegameId = tipo ? tipo.id : null;
        } else if (tipoRelazione === 'figlio') {
            const tipo = tipiLegame.value.find(t => t.nome === 'padre');
            tipoLegameId = tipo ? tipo.id : null;
        } else if (tipoRelazione === 'padre') {
            // Se si crea un padre, la relazione va creata sulla persona originale (figlio)
            // La persona originale deve avere questa nuova persona come padre
            await personaService.update(personaId, {
                nome: persona.nome,
                cognome: persona.cognome,
                nato_a: persona.nato_a,
                nato_il: persona.nato_il,
                deceduto_a: persona.deceduto_a,
                deceduto_il: persona.deceduto_il,
                genitori: {
                    ...(persona.padre ? { padre_id: persona.padre.id } : {}),
                    ...(persona.madre ? { madre_id: persona.madre.id } : {}),
                    padre_id: personaCollegataId
                }
            });
            return; // Esci perché abbiamo già creato la relazione
        } else if (tipoRelazione === 'madre') {
            // Stesso discorso per la madre
            await personaService.update(personaId, {
                nome: persona.nome,
                cognome: persona.cognome,
                nato_a: persona.nato_a,
                nato_il: persona.nato_il,
                deceduto_a: persona.deceduto_a,
                deceduto_il: persona.deceduto_il,
                genitori: {
                    ...(persona.padre ? { padre_id: persona.padre.id } : {}),
                    ...(persona.madre ? { madre_id: persona.madre.id } : {}),
                    madre_id: personaCollegataId
                }
            });
            return;
        }
        
        if (tipoLegameId) {
            relazioni.push({
                persona_collegata_id: personaCollegataId,
                tipo_legame_id: tipoLegameId,
            });
        }
        
        // Prepara i dati per l'update
        const updateData = {
            nome: persona.nome,
            cognome: persona.cognome,
            nato_a: persona.nato_a,
            nato_il: persona.nato_il,
            deceduto_a: persona.deceduto_a,
            deceduto_il: persona.deceduto_il,
        };
        
        if (Object.keys(genitori).length > 0) {
            updateData.genitori = genitori;
        }
        
        if (relazioni.length > 0) {
            updateData.relazioni = relazioni;
        }
        
        // Aggiorna la persona con tutte le relazioni
        await personaService.update(personaId, updateData);
        
    } catch (error) {
        console.error('Errore nella creazione della relazione:', error);
        // Non bloccare il flusso se la relazione non viene creata
    }
};
</script>

