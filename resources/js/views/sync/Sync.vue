<template>
    <div class="container mx-auto px-4 py-8">
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
            <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
                Sincronizzazione Database
            </h1>

            <!-- Selezione Modalità -->
            <div class="mb-6 p-4 bg-gray-100 dark:bg-gray-700 rounded-lg">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Modalità Sincronizzazione
                </label>
                <div class="flex gap-4">
                    <label class="flex items-center">
                        <input 
                            type="radio" 
                            v-model="syncMode" 
                            value="http" 
                            class="mr-2"
                        />
                        <span class="text-gray-700 dark:text-gray-300">Rete HTTP</span>
                    </label>
                    <label class="flex items-center">
                        <input 
                            type="radio" 
                            v-model="syncMode" 
                            value="adb" 
                            class="mr-2"
                        />
                        <span class="text-gray-700 dark:text-gray-300">USB ADB</span>
                    </label>
                </div>
            </div>

            <!-- Messaggio informativo per modalità HTTP -->
            <div v-if="syncMode === 'http'" class="mb-6 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
                <h3 class="font-semibold mb-2 text-blue-900 dark:text-blue-100">Modalità HTTP</h3>
                <p class="text-sm text-blue-700 dark:text-blue-300 mb-3">
                    Con la modalità HTTP, usa l'app Flutter Android per sincronizzare i dati.
                </p>
                <div class="bg-white dark:bg-gray-800 p-4 rounded-lg border border-blue-200 dark:border-blue-700">
                    <h4 class="font-semibold mb-2 text-blue-900 dark:text-blue-100">Come sincronizzare dall'app Flutter:</h4>
                    <ol class="list-decimal list-inside space-y-2 text-sm text-blue-700 dark:text-blue-300">
                        <li>Apri l'app Flutter sul tuo telefono Android</li>
                        <li>Nella schermata principale (lista persone), clicca sull'icona <strong>🔄 Sincronizza</strong> in alto a destra</li>
                        <li>Seleziona la modalità <strong>"Rete HTTP"</strong></li>
                        <li>Clicca su <strong>"Calcola Differenze"</strong> per vedere cosa è cambiato</li>
                        <li>Scegli l'azione desiderata:
                            <ul class="list-disc list-inside ml-4 mt-1">
                                <li><strong>Copia App → Server</strong>: invia i dati dal telefono al server</li>
                                <li><strong>Copia Server → App</strong>: scarica i dati dal server al telefono</li>
                                <li><strong>Unisci (Merge)</strong>: unisce i dati da entrambe le parti</li>
                            </ul>
                        </li>
                    </ol>
                </div>
                <p class="text-xs text-blue-600 dark:text-blue-400 mt-3">
                    💡 Il frontend web funziona solo come dashboard di monitoraggio per la modalità ADB.
                </p>
            </div>

            <!-- Stato Sincronizzazione (solo per modalità ADB) -->
            <div v-if="syncStatus && syncMode !== 'http'" class="mb-6 p-4 rounded-lg" 
                 :class="syncStatus.pending_conflicts > 0 ? 'bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800' : 'bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800'">
                <h3 class="font-semibold mb-2 text-gray-900 dark:text-white">Ultima Sincronizzazione</h3>
                <p v-if="syncStatus.last_sync" class="text-sm text-gray-700 dark:text-gray-300">
                    Tipo: {{ syncStatus.last_sync.sync_type }} | 
                    Modalità: {{ syncStatus.last_sync.sync_mode }} | 
                    Completata: {{ formatDate(syncStatus.last_sync.completed_at) }} | 
                    Record sincronizzati: {{ syncStatus.last_sync.records_synced }}
                </p>
                <p v-else class="text-sm text-gray-700 dark:text-gray-300">
                    Nessuna sincronizzazione effettuata
                </p>
                <p v-if="syncStatus.pending_conflicts > 0" class="text-sm text-yellow-700 dark:text-yellow-300 mt-2">
                    ⚠️ {{ syncStatus.pending_conflicts }} conflitti in attesa di risoluzione
                </p>
            </div>

            <!-- Bottone Calcola Differenze (solo per modalità ADB) -->
            <div v-if="syncMode === 'adb'" class="mb-6">
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">
                    Con la modalità ADB, esporta i dati dall'app Flutter e usa lo script 
                    <code class="bg-gray-200 dark:bg-gray-700 px-2 py-1 rounded">./sync_via_adb.sh</code> sul server.
                </p>
                <button
                    @click="calculateDiff"
                    :disabled="loading || syncing"
                    class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
                >
                    <svg v-if="loading" class="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    <span>{{ loading ? 'Calcolo differenze...' : 'Calcola Differenze' }}</span>
                </button>
            </div>

            <!-- Visualizzazione Differenze (solo per modalità ADB) -->
            <div v-if="diff && syncMode === 'adb'" class="mb-6">
                <h2 class="text-2xl font-bold mb-4 text-gray-900 dark:text-white">Differenze Trovate</h2>
                
                <!-- Riepilogo -->
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                    <div class="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg border border-blue-200 dark:border-blue-800">
                        <div class="text-sm text-gray-600 dark:text-gray-400">Nuovi sul Server</div>
                        <div class="text-2xl font-bold text-blue-600 dark:text-blue-400">{{ diff.summary?.server_new || 0 }}</div>
                    </div>
                    <div class="bg-green-50 dark:bg-green-900/20 p-4 rounded-lg border border-green-200 dark:border-green-800">
                        <div class="text-sm text-gray-600 dark:text-gray-400">Nuovi sull'App</div>
                        <div class="text-2xl font-bold text-green-600 dark:text-green-400">{{ diff.summary?.app_new || 0 }}</div>
                    </div>
                    <div class="bg-yellow-50 dark:bg-yellow-900/20 p-4 rounded-lg border border-yellow-200 dark:border-yellow-800">
                        <div class="text-sm text-gray-600 dark:text-gray-400">Modificati</div>
                        <div class="text-2xl font-bold text-yellow-600 dark:text-yellow-400">{{ diff.summary?.modified || 0 }}</div>
                    </div>
                    <div class="bg-red-50 dark:bg-red-900/20 p-4 rounded-lg border border-red-200 dark:border-red-800">
                        <div class="text-sm text-gray-600 dark:text-gray-400">Conflitti</div>
                        <div class="text-2xl font-bold text-red-600 dark:text-red-400">{{ diff.summary?.conflicts || 0 }}</div>
                    </div>
                </div>

                <!-- Dettagli per Tabella -->
                <template v-for="(tableDiff, tableName) in diff" :key="tableName">
                    <div v-if="tableName !== 'summary' && tableDiff && typeof tableDiff === 'object' && (tableDiff.server_new_count > 0 || tableDiff.app_new_count > 0 || tableDiff.modified_count > 0 || tableDiff.conflicts_count > 0)"
                         class="mb-4 p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
                        <h3 class="font-semibold mb-2 text-gray-900 dark:text-white capitalize">{{ tableName }}</h3>
                        <div class="grid grid-cols-4 gap-2 text-sm">
                            <div>Server nuovi: <span class="font-bold">{{ tableDiff.server_new_count || 0 }}</span></div>
                            <div>App nuovi: <span class="font-bold">{{ tableDiff.app_new_count || 0 }}</span></div>
                            <div>Modificati: <span class="font-bold">{{ tableDiff.modified_count || 0 }}</span></div>
                            <div>Conflitti: <span class="font-bold text-red-600">{{ tableDiff.conflicts_count || 0 }}</span></div>
                        </div>
                    </div>
                </template>
            </div>

            <!-- Bottoni Azioni Sincronizzazione (solo per modalità ADB) -->
            <div v-if="diff && syncMode === 'adb'" class="flex flex-col md:flex-row gap-4 mb-6">
                <button
                    @click="syncPush"
                    :disabled="syncing || !diff"
                    class="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
                >
                    <svg v-if="syncing && syncType === 'push'" class="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    <span>{{ syncing && syncType === 'push' ? 'Sincronizzazione...' : 'Copia App → Server' }}</span>
                </button>

                <button
                    @click="syncPull"
                    :disabled="syncing || !diff"
                    class="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
                >
                    <svg v-if="syncing && syncType === 'pull'" class="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    <span>{{ syncing && syncType === 'pull' ? 'Sincronizzazione...' : 'Copia Server → App' }}</span>
                </button>

                <button
                    @click="syncMerge"
                    :disabled="syncing || !diff"
                    class="flex-1 px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
                >
                    <svg v-if="syncing && syncType === 'merge'" class="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    <span>{{ syncing && syncType === 'merge' ? 'Merge in corso...' : 'Merge Tutto' }}</span>
                </button>
            </div>

            <!-- Progress Bar -->
            <div v-if="syncing" class="mb-6">
                <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-4">
                    <div class="bg-blue-600 h-4 rounded-full transition-all duration-300" :style="{ width: syncProgress + '%' }"></div>
                </div>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-2 text-center">{{ syncProgress }}% completato</p>
            </div>

            <!-- Messaggi Successo/Errore -->
            <div v-if="message" class="mb-6 p-4 rounded-lg" 
                 :class="message.type === 'success' ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800' : 'bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800'">
                <p :class="message.type === 'success' ? 'text-green-800 dark:text-green-200' : 'text-red-800 dark:text-red-200'">
                    {{ message.text }}
                </p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import api from '../../services/api';

const syncMode = ref('http');
const loading = ref(false);
const syncing = ref(false);
const syncType = ref(null);
const syncProgress = ref(0);
const diff = ref(null);
const syncStatus = ref(null);
const message = ref(null);
// Rimossi: appDataFile, appDataFileInput, appDataFromFile
// Con modalità HTTP, l'app Flutter invia i dati direttamente via API

onMounted(async () => {
    // Carica lo stato solo se non è modalità HTTP
    // Con modalità HTTP, l'app Flutter gestisce tutto
    if (syncMode.value !== 'http') {
        await loadSyncStatus();
    }
});

const loadSyncStatus = async () => {
    // Non caricare lo stato se è modalità HTTP (l'app Flutter gestisce tutto)
    if (syncMode.value === 'http') {
        return;
    }
    
    try {
        const response = await api.get('/sync/status');
        if (response.data.success) {
            syncStatus.value = response.data.data;
        }
    } catch (error) {
        console.error('Errore nel caricamento stato sync:', error);
    }
};

// Quando cambia la modalità, gestisci di conseguenza
watch(syncMode, async (newMode) => {
    if (newMode === 'http') {
        // Con HTTP, pulisci lo stato perché l'app Flutter gestisce tutto
        syncStatus.value = null;
        diff.value = null;
        message.value = {
            type: 'info',
            text: 'Con la modalità HTTP, usa l\'app Flutter per sincronizzare i dati.',
        };
    } else {
        // Con ADB, carica lo stato
        await loadSyncStatus();
    }
});

// Rimossa funzione handleAppDataFileSelect - non più necessaria con modalità HTTP
// Rimossa funzione clearAppDataFile - non più necessaria con modalità HTTP

const calculateDiff = async () => {
    // Con modalità HTTP, l'app Flutter calcola le differenze direttamente
    // Questa funzione è mantenuta solo per compatibilità con modalità ADB
    if (syncMode.value === 'http') {
        message.value = {
            type: 'info',
            text: 'Con la modalità HTTP, usa l\'app Flutter per calcolare le differenze e sincronizzare.',
        };
        return;
    }

    loading.value = true;
    message.value = null;
    
    try {
        // Per modalità ADB, i dati vengono gestiti dallo script sync_via_adb.sh
        message.value = {
            type: 'info',
            text: 'Per modalità ADB, usa lo script sync_via_adb.sh sul server.',
        };
    } catch (error) {
        message.value = {
            type: 'error',
            text: error.response?.data?.message || 'Errore nel calcolo delle differenze',
        };
    } finally {
        loading.value = false;
    }
};

const syncPush = async () => {
    if (syncMode.value === 'http') {
        message.value = {
            type: 'info',
            text: 'Con la modalità HTTP, usa l\'app Flutter per sincronizzare i dati.',
        };
        return;
    }
    
    // Per modalità ADB, usa lo script sync_via_adb.sh
    message.value = {
        type: 'info',
        text: 'Per modalità ADB, usa lo script sync_via_adb.sh push sul server.',
    };
};

const syncPull = async () => {
    if (syncMode.value === 'http') {
        message.value = {
            type: 'info',
            text: 'Con la modalità HTTP, usa l\'app Flutter per sincronizzare i dati.',
        };
        return;
    }
    
    // Per modalità ADB, usa lo script sync_via_adb.sh
    message.value = {
        type: 'info',
        text: 'Per modalità ADB, usa lo script sync_via_adb.sh pull sul server.',
    };
};

const syncMerge = async () => {
    if (syncMode.value === 'http') {
        message.value = {
            type: 'info',
            text: 'Con la modalità HTTP, usa l\'app Flutter per sincronizzare i dati.',
        };
        return;
    }
    
    // Per modalità ADB, usa lo script sync_via_adb.sh
    message.value = {
        type: 'info',
        text: 'Per modalità ADB, usa lo script sync_via_adb.sh merge sul server.',
    };
};

const performSync = async (type, syncFunction) => {
    syncing.value = true;
    syncType.value = type;
    syncProgress.value = 0;
    message.value = null;

    try {
        // Simula progresso
        const progressInterval = setInterval(() => {
            if (syncProgress.value < 90) {
                syncProgress.value += 10;
            }
        }, 500);

        const result = await syncFunction();

        clearInterval(progressInterval);
        syncProgress.value = 100;

        message.value = {
            type: 'success',
            text: result.message || `Sincronizzazione ${type} completata con successo`,
        };

        // Ricarica solo lo stato (le differenze vengono calcolate dall'app Flutter)
        await loadSyncStatus();

        setTimeout(() => {
            syncProgress.value = 0;
        }, 2000);
    } catch (error) {
        message.value = {
            type: 'error',
            text: error.response?.data?.message || `Errore durante la sincronizzazione ${type}`,
        };
        syncProgress.value = 0;
    } finally {
        syncing.value = false;
        syncType.value = null;
    }
};

const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleString('it-IT');
};
</script>

