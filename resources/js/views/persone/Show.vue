<template>
    <div class="bg-gray-200 dark:bg-gray-900 h-full flex flex-col overflow-hidden">
        <!-- Header con azioni - FISSO -->
        <div class="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700 flex-shrink-0" style="z-index: 100;">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-2">
                <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                    <div class="flex items-center gap-3">
                        <div>
                            <h1 class="text-xl font-bold text-gray-900 dark:text-white">{{ t('persona.detail_title') }}</h1>
                            <p class="text-xs text-gray-500 dark:text-gray-400">{{ t('persona.detail_subtitle') }}</p>
                        </div>
                    </div>
                    <div class="flex items-center gap-2">
                        <router-link
                            to="/persone"
                            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
                        >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                            </svg>
                            <span>{{ t('persona.back_to_list') }}</span>
                        </router-link>
                        <router-link
                            :to="`/persone/${$route.params.id}/edit`"
                            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
                        >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                            <span>{{ t('common.edit') }}</span>
                        </router-link>
                        <button
                            @click="handleDelete"
                            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors shadow-sm"
                        >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                            <span>{{ t('common.delete') }}</span>
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Contenuto scrollabile -->
        <div class="flex-1 overflow-y-auto">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-4 pt-3">
            <!-- Loading State -->
            <div v-if="store.loading" class="flex items-center justify-center py-12">
                <div class="text-center">
                    <div class="inline-block animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mb-3"></div>
                    <p class="text-gray-600 dark:text-gray-400">{{ t('persona.loading_info') }}</p>
                </div>
            </div>

            <!-- Contenuto principale -->
            <div v-else-if="store.persona" class="space-y-3">
                <!-- Card principale - Informazioni Persona -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
                    <div class="bg-gradient-to-r from-blue-500 to-blue-600 px-4 py-3">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center gap-3">
                                <div class="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm">
                                    <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                    </svg>
                                </div>
                                <div>
                                    <h2 class="text-xl font-bold text-white">
                                        {{ store.persona.nome_completo || `${store.persona.nome} ${store.persona.cognome}` }}
                                    </h2>
                                    <div class="flex items-center gap-2 mt-1">
                                        <span v-if="store.persona.deceduto_il" class="inline-flex items-center gap-1 px-2 py-0.5 bg-red-500/20 text-white rounded-full text-xs font-medium">
                                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                            </svg>
                                            {{ t('persona.deceased') }}
                                        </span>
                                        <span v-else class="inline-flex items-center gap-1 px-2 py-0.5 bg-green-500/20 text-white rounded-full text-xs font-medium">
                                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                            </svg>
                                            {{ t('persona.living') }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Informazioni dettagliate -->
                    <div class="p-4">
                        <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-3 flex items-center gap-2">
                            <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            {{ t('persona.personal_info') }}
                        </h3>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                            <!-- Nascita -->
                            <div v-if="store.persona.nato_il || store.persona.nato_a" class="flex items-start gap-2 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                                <div class="flex-shrink-0 w-8 h-8 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                                    <svg class="w-4 h-4 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                    </svg>
                                </div>
                                <div class="flex-1">
                                    <p class="text-xs font-medium text-gray-500 dark:text-gray-400">{{ t('persona.birth') }}</p>
                                    <p v-if="store.persona.nato_il" class="text-sm font-semibold text-gray-900 dark:text-white">
                                        {{ formatDateItalian(store.persona.nato_il) }}
                                    </p>
                                    <p v-if="store.persona.nato_a" class="text-xs text-gray-600 dark:text-gray-300 mt-0.5">
                                        <svg class="w-3 h-3 inline mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                                        </svg>
                                        {{ store.persona.nato_a }}
                                    </p>
                                </div>
                            </div>

                            <!-- Decesso -->
                            <div v-if="store.persona.deceduto_il || store.persona.deceduto_a" class="flex items-start gap-2 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                                <div class="flex-shrink-0 w-8 h-8 bg-red-100 dark:bg-red-900/30 rounded-lg flex items-center justify-center">
                                    <svg class="w-4 h-4 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                    </svg>
                                </div>
                                <div class="flex-1">
                                    <p class="text-xs font-medium text-gray-500 dark:text-gray-400">{{ t('persona.death') }}</p>
                                    <p v-if="store.persona.deceduto_il" class="text-sm font-semibold text-gray-900 dark:text-white">
                                        {{ formatDateItalian(store.persona.deceduto_il) }}
                                    </p>
                                    <p v-if="store.persona.deceduto_a" class="text-xs text-gray-600 dark:text-gray-300 mt-0.5">
                                        <svg class="w-3 h-3 inline mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                                        </svg>
                                        {{ store.persona.deceduto_a }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Card Relazioni Familiari -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
                    <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-3 flex items-center gap-2">
                        <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                        </svg>
                        {{ t('persona.family_relations') }}
                    </h3>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <!-- Genitori -->
                        <div v-if="store.persona.padre || store.persona.madre" class="space-y-2">
                            <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">{{ t('persona.genitori') }}</h4>
                            
                            <!-- Padre -->
                            <div 
                                v-if="store.persona.padre" 
                                @click="navigateToPersona(store.persona.padre.id)"
                                class="group p-2.5 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800 hover:border-blue-300 dark:hover:border-blue-700 transition-colors cursor-pointer"
                            >
                                <div class="flex items-center gap-2">
                                    <div class="flex-shrink-0 w-8 h-8 bg-blue-100 dark:bg-blue-900/40 rounded-lg flex items-center justify-center">
                                        <svg class="w-4 h-4 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                        </svg>
                                    </div>
                                    <div class="flex-1 min-w-0">
                                        <p class="text-xs font-medium text-gray-500 dark:text-gray-400">{{ t('persona.padre') }}</p>
                                        <p class="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors truncate">
                                            {{ store.persona.padre.nome_completo }}
                                        </p>
                                    </div>
                                    <svg class="w-4 h-4 text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                                    </svg>
                                </div>
                            </div>

                            <!-- Madre -->
                            <div 
                                v-if="store.persona.madre" 
                                @click="navigateToPersona(store.persona.madre.id)"
                                class="group p-2.5 bg-pink-50 dark:bg-pink-900/20 rounded-lg border border-pink-200 dark:border-pink-800 hover:border-pink-300 dark:hover:border-pink-700 transition-colors cursor-pointer"
                            >
                                <div class="flex items-center gap-2">
                                    <div class="flex-shrink-0 w-8 h-8 bg-pink-100 dark:bg-pink-900/40 rounded-lg flex items-center justify-center">
                                        <svg class="w-4 h-4 text-pink-600 dark:text-pink-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                        </svg>
                                    </div>
                                    <div class="flex-1 min-w-0">
                                        <p class="text-xs font-medium text-gray-500 dark:text-gray-400">{{ t('persona.madre') }}</p>
                                        <p class="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-pink-600 dark:group-hover:text-pink-400 transition-colors truncate">
                                            {{ store.persona.madre.nome_completo }}
                                        </p>
                                    </div>
                                    <svg class="w-4 h-4 text-gray-400 group-hover:text-pink-600 dark:group-hover:text-pink-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                                    </svg>
                                </div>
                            </div>
                        </div>

                        <!-- Consorti e Figli -->
                        <div class="space-y-2">
                            <!-- Consorti -->
                            <div v-if="store.persona.consorti && store.persona.consorti.length > 0">
                                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide mb-2">{{ t('persona.consorti') }}</h4>
                                <div class="space-y-1.5">
                                    <div
                                        v-for="consorte in store.persona.consorti"
                                        :key="consorte.id"
                                        @click="navigateToPersona(consorte.id)"
                                        class="group p-2.5 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800 hover:border-purple-300 dark:hover:border-purple-700 transition-colors cursor-pointer"
                                    >
                                        <div class="flex items-center gap-2">
                                            <div class="flex-shrink-0 w-8 h-8 bg-purple-100 dark:bg-purple-900/40 rounded-lg flex items-center justify-center">
                                                <svg class="w-4 h-4 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                                                </svg>
                                            </div>
                                            <div class="flex-1 min-w-0">
                                                <p class="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors truncate">
                                                    {{ consorte.nome_completo }}
                                                </p>
                                                <!-- Dettagli legame -->
                                                <div v-if="consorte.tipo_evento_legame || consorte.data_legame || consorte.luogo_legame || consorte.data_separazione || consorte.luogo_separazione" class="mt-1 space-y-0.5">
                                                    <p v-if="consorte.tipo_evento_legame" class="text-xs text-gray-600 dark:text-gray-400">
                                                        {{ consorte.tipo_evento_legame.descrizione || consorte.tipo_evento_legame.nome }}
                                                    </p>
                                                    <p v-if="consorte.data_legame || consorte.luogo_legame" class="text-xs text-gray-500 dark:text-gray-500">
                                                        <span v-if="consorte.data_legame">{{ formatDateItalian(consorte.data_legame) }}</span>
                                                        <span v-if="consorte.data_legame && consorte.luogo_legame"> - </span>
                                                        <span v-if="consorte.luogo_legame">{{ consorte.luogo_legame }}</span>
                                                    </p>
                                                    <p v-if="consorte.data_separazione || consorte.luogo_separazione" class="text-xs text-red-600 dark:text-red-400 italic">
                                                        {{ t('persona.data_separazione') }}: 
                                                        <span v-if="consorte.data_separazione">{{ formatDateItalian(consorte.data_separazione) }}</span>
                                                        <span v-if="consorte.data_separazione && consorte.luogo_separazione"> - </span>
                                                        <span v-if="consorte.luogo_separazione">{{ consorte.luogo_separazione }}</span>
                                                    </p>
                                                </div>
                                            </div>
                                            <svg class="w-4 h-4 text-gray-400 group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                                            </svg>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Figli -->
                            <div v-if="store.persona.figli && store.persona.figli.length > 0">
                                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide mb-2">{{ t('persona.figli') }} ({{ store.persona.figli.length }})</h4>
                                <div class="space-y-1.5">
                                    <div
                                        v-for="figlio in store.persona.figli"
                                        :key="figlio.id"
                                        @click="navigateToPersona(figlio.id)"
                                        class="group p-2.5 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800 hover:border-green-300 dark:hover:border-green-700 transition-colors cursor-pointer"
                                    >
                                        <div class="flex items-center gap-2">
                                            <div class="flex-shrink-0 w-8 h-8 bg-green-100 dark:bg-green-900/40 rounded-lg flex items-center justify-center">
                                                <svg class="w-4 h-4 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                                                </svg>
                                            </div>
                                            <div class="flex-1 min-w-0">
                                                <p class="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-green-600 dark:group-hover:text-green-400 transition-colors truncate">
                                                    {{ figlio.nome_completo }}
                                                </p>
                                            </div>
                                            <svg class="w-4 h-4 text-gray-400 group-hover:text-green-600 dark:group-hover:text-green-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                                            </svg>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Messaggio se non ci sono relazioni -->
                    <div v-if="!store.persona.padre && !store.persona.madre && (!store.persona.consorti || store.persona.consorti.length === 0) && (!store.persona.figli || store.persona.figli.length === 0)" class="text-center py-6">
                        <svg class="w-10 h-10 text-gray-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                        </svg>
                        <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('persona.no_family_relations') }}</p>
                    </div>
                </div>

                <!-- Card Media Gallery -->
                <MediaGallery :persona-id="parseInt($route.params.id)" />

                <!-- Timeline e Mappa sulla stessa riga -->
                <div class="grid grid-cols-1 lg:grid-cols-6 gap-4 items-stretch" style="min-height: 680px;">
                    <!-- Timeline: 2/6 dello spazio -->
                    <div class="lg:col-span-2 flex w-full">
                        <Timeline :persona-id="parseInt($route.params.id)" :persona="store.persona" class="w-full" />
                    </div>
                    <!-- Mappa: 4/6 dello spazio -->
                    <div class="lg:col-span-4 flex w-full">
                        <MapView v-if="hasMapData" :luoghi="mapLuoghi" class="w-full" />
                    </div>
                </div>

                <!-- Note e Tag sulla stessa riga -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <!-- Note: 50% dello spazio -->
                    <div class="flex">
                        <NoteSection :persona-id="parseInt($route.params.id)" class="w-full" />
                    </div>
                    <!-- Tags: 50% dello spazio -->
                    <div class="flex">
                        <TagSection :persona-id="parseInt($route.params.id)" :persona-tags="store.persona?.tags || []" @tags-updated="loadPersonaTags" class="w-full" />
                    </div>
                </div>

                <!-- Card Albero Genealogico Verticale -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-base font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                            <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                            </svg>
                            {{ t('persona.family_tree') }}
                        </h3>
                        <button
                            @click="window.print()"
                            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
                            :title="t('persona.print_family_tree') || 'Stampa albero genealogico'"
                        >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
                            </svg>
                            {{ t('persona.print') || 'Stampa' }}
                        </button>
                    </div>

                    <div class="flex flex-col items-center space-y-4 py-4">
                        <!-- Nonni -->
                        <div v-if="hasNonni" class="flex flex-col items-center space-y-2 w-full">
                            <div class="flex justify-center gap-4 w-full">
                                <!-- Nonni Paterni -->
                                <div class="flex flex-col items-center space-y-2">
                                    <div 
                                        v-if="nonnoPaterno"
                                        @click="navigateToPersona(nonnoPaterno.id)"
                                        class="persona-card bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 hover:border-amber-300 dark:hover:border-amber-700"
                                    >
                                        <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ t('persona.grandfather_paternal') }}</div>
                                        <div class="text-sm font-semibold text-gray-900 dark:text-white">{{ nonnoPaterno.nome_completo }}</div>
                                    </div>
                                    <div 
                                        v-if="nonnaPaterna"
                                        @click="navigateToPersona(nonnaPaterna.id)"
                                        class="persona-card bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 hover:border-amber-300 dark:hover:border-amber-700"
                                    >
                                        <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ t('persona.grandmother_paternal') }}</div>
                                        <div class="text-sm font-semibold text-gray-900 dark:text-white">{{ nonnaPaterna.nome_completo }}</div>
                                    </div>
                                </div>
                                
                                <!-- Nonni Materni -->
                                <div class="flex flex-col items-center space-y-2">
                                    <div 
                                        v-if="nonnoMaterno"
                                        @click="navigateToPersona(nonnoMaterno.id)"
                                        class="persona-card bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 hover:border-amber-300 dark:hover:border-amber-700"
                                    >
                                        <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ t('persona.grandfather_maternal') }}</div>
                                        <div class="text-sm font-semibold text-gray-900 dark:text-white">{{ nonnoMaterno.nome_completo }}</div>
                                    </div>
                                    <div 
                                        v-if="nonnaMaterna"
                                        @click="navigateToPersona(nonnaMaterna.id)"
                                        class="persona-card bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 hover:border-amber-300 dark:hover:border-amber-700"
                                    >
                                        <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ t('persona.grandmother_maternal') }}</div>
                                        <div class="text-sm font-semibold text-gray-900 dark:text-white">{{ nonnaMaterna.nome_completo }}</div>
                                    </div>
                                </div>
                            </div>
                            <!-- Linea verticale dai nonni ai genitori -->
                            <div v-if="hasGenitori" class="w-0.5 h-6 bg-gray-300 dark:bg-gray-600"></div>
                        </div>

                        <!-- Genitori -->
                        <div v-if="store.persona.padre || store.persona.madre" class="flex flex-col items-center space-y-2">
                            <div class="flex justify-center gap-4">
                                <div 
                                    v-if="store.persona.padre"
                                    @click="navigateToPersona(store.persona.padre.id)"
                                    class="persona-card bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 hover:border-blue-300 dark:hover:border-blue-700"
                                >
                                    <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ t('persona.padre') }}</div>
                                    <div class="text-sm font-semibold text-gray-900 dark:text-white">{{ store.persona.padre.nome_completo }}</div>
                                </div>
                                <div 
                                    v-if="store.persona.madre"
                                    @click="navigateToPersona(store.persona.madre.id)"
                                    class="persona-card bg-pink-50 dark:bg-pink-900/20 border-pink-200 dark:border-pink-800 hover:border-pink-300 dark:hover:border-pink-700"
                                >
                                    <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ t('persona.madre') }}</div>
                                    <div class="text-sm font-semibold text-gray-900 dark:text-white">{{ store.persona.madre.nome_completo }}</div>
                                </div>
                            </div>
                            <!-- Linea verticale dai genitori alla persona -->
                            <div class="w-0.5 h-6 bg-gray-300 dark:bg-gray-600"></div>
                        </div>

                        <!-- Consorte/i -->
                        <div v-if="store.persona.consorti && store.persona.consorti.length > 0" class="flex flex-col items-center space-y-2">
                            <div class="flex justify-center gap-2 flex-wrap">
                                <div 
                                    v-for="consorte in store.persona.consorti"
                                    :key="consorte.id"
                                    @click="navigateToPersona(consorte.id)"
                                    class="persona-card bg-purple-50 dark:bg-purple-900/20 border-purple-200 dark:border-purple-800 hover:border-purple-300 dark:hover:border-purple-700"
                                >
                                    <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ t('persona.consorte') }}</div>
                                    <div class="text-sm font-semibold text-gray-900 dark:text-white">{{ consorte.nome_completo }}</div>
                                </div>
                            </div>
                            <!-- Linea verticale dai consorti alla persona -->
                            <div class="w-0.5 h-4 bg-gray-300 dark:bg-gray-600"></div>
                        </div>

                        <!-- Persona Principale -->
                        <div class="persona-card bg-gradient-to-r from-blue-500 to-blue-600 border-blue-600 text-white shadow-lg">
                            <div class="text-xs text-blue-100 mb-1">{{ t('persona.persona') }}</div>
                            <div class="text-base font-bold">{{ store.persona.nome_completo || `${store.persona.nome} ${store.persona.cognome}` }}</div>
                        </div>

                        <!-- Linea verticale dalla persona ai figli -->
                        <div v-if="store.persona.figli && store.persona.figli.length > 0" class="w-0.5 h-6 bg-gray-300 dark:bg-gray-600"></div>

                        <!-- Figli -->
                        <div v-if="store.persona.figli && store.persona.figli.length > 0" class="flex flex-col items-center space-y-2">
                            <div class="flex justify-center gap-2 flex-wrap max-w-2xl">
                                <div 
                                    v-for="figlio in store.persona.figli"
                                    :key="figlio.id"
                                    @click="navigateToPersona(figlio.id)"
                                    class="persona-card bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 hover:border-green-300 dark:hover:border-green-700"
                                >
                                    <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ t('persona.child') }}</div>
                                    <div class="text-sm font-semibold text-gray-900 dark:text-white">{{ figlio.nome_completo }}</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        </div>
    </div>
</template>

<script setup>
import { onMounted, ref, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { usePersoneStore } from '../../stores/persone';
import { useLocaleStore } from '../../stores/locale';
import { personaService } from '../../services/personaService';
import { eventoService } from '../../services/eventoService';
import MediaGallery from '../media/MediaGallery.vue';
import Timeline from '../eventi/Timeline.vue';
import NoteSection from '../../components/persona/NoteSection.vue';
import TagSection from '../../components/persona/TagSection.vue';
import MapView from '../../components/maps/MapView.vue';

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

// Watch per ricaricare le traduzioni quando cambia la lingua
watch(() => localeStore.locale, () => {
    localeStore.loadTranslations();
});

// Nonni caricati
const nonnoPaterno = ref(null);
const nonnaPaterna = ref(null);
const nonnoMaterno = ref(null);
const nonnaMaterna = ref(null);

// Eventi caricati per la mappa
const eventi = ref([]);

const hasNonni = computed(() => {
    return nonnoPaterno.value || nonnaPaterna.value || nonnoMaterno.value || nonnaMaterna.value;
});

const hasGenitori = computed(() => {
    return store.persona?.padre || store.persona?.madre;
});

const hasMapData = computed(() => {
    const hasNascita = store.persona?.nato_a && store.persona.nato_a !== '0' && store.persona.nato_a !== '';
    const hasMorte = store.persona?.deceduto_a && store.persona.deceduto_a !== '0' && store.persona.deceduto_a !== '';
    const hasEventiLuoghi = eventi.value.some(e => e.luogo && e.luogo !== '0' && e.luogo !== '');
    const hasMatrimonio = store.persona?.consorti?.some(c => c.luogo_legame && c.luogo_legame !== '0' && c.luogo_legame !== '');
    return hasNascita || hasMorte || hasMatrimonio || hasEventiLuoghi;
});

const mapLuoghi = computed(() => {
    const luoghi = [];
    const nomePersona = store.persona?.nome_completo || `${store.persona?.nome} ${store.persona?.cognome}`;
    
    // Aggiungi luogo di nascita
    if (store.persona?.nato_a && store.persona.nato_a !== '0' && store.persona.nato_a !== '') {
        luoghi.push({ 
            nome: nomePersona + ' - ' + t('persona.birth_place'), 
            luogo: store.persona.nato_a,
            tipo: 'nascita',
            data: store.persona.nato_il
        });
    }
    
    // Aggiungi luogo di morte
    if (store.persona?.deceduto_a && store.persona.deceduto_a !== '0' && store.persona.deceduto_a !== '') {
        luoghi.push({ 
            nome: nomePersona + ' - ' + t('persona.death_place'), 
            luogo: store.persona.deceduto_a,
            tipo: 'morte',
            data: store.persona.deceduto_il
        });
    }
    
    // Aggiungi luoghi dei matrimoni (consorti)
    if (store.persona?.consorti && store.persona.consorti.length > 0) {
        store.persona.consorti.forEach(consorte => {
            if (consorte.luogo_legame && consorte.luogo_legame !== '0' && consorte.luogo_legame !== '') {
                const consorteNome = consorte.nome_completo || `${consorte.nome} ${consorte.cognome}`;
                luoghi.push({
                    nome: nomePersona + ' - ' + t('eventi.marriage') + ' con ' + consorteNome,
                    luogo: consorte.luogo_legame,
                    tipo: 'matrimonio',
                    data: consorte.data_legame,
                    descrizione: consorte.tipo_evento_legame?.descrizione || consorte.tipo_evento_legame?.nome || ''
                });
            }
        });
    }
    
    // Aggiungi luoghi degli eventi
    eventi.value.forEach(evento => {
        if (evento.luogo && evento.luogo !== '0' && evento.luogo !== '') {
            const eventTypeLabel = getEventTypeLabel(evento.tipo_evento);
            luoghi.push({
                nome: nomePersona + ' - ' + eventTypeLabel + ': ' + evento.titolo,
                luogo: evento.luogo,
                tipo: evento.tipo_evento,
                data: evento.data_evento,
                descrizione: evento.descrizione
            });
        }
    });
    
    return luoghi;
});

// Funzione helper per ottenere l'etichetta del tipo di evento
const getEventTypeLabel = (tipo) => {
    const labels = {
        nascita: t('eventi.birth'),
        battesimo: t('eventi.baptism'),
        comunione: t('eventi.communion'),
        cresima: t('eventi.confirmation'),
        primo_giorno_asilo: t('eventi.first_day_kindergarten'),
        primo_giorno_scuola: t('eventi.first_day_school'),
        licenza_elementare: t('eventi.elementary_license'),
        licenza_media: t('eventi.middle_school_license'),
        diploma_superiore: t('eventi.high_school_diploma'),
        laurea: t('eventi.graduation'),
        matrimonio: t('eventi.marriage'),
        divorzio: t('eventi.divorce'),
        lavoro: t('eventi.work'),
        cambio_lavoro: t('eventi.job_change'),
        militare: t('eventi.military'),
        guerra: t('eventi.war'),
        trasloco: t('eventi.move'),
        emigrazione: t('eventi.emigration'),
        immigrazione: t('eventi.immigration'),
        malattia: t('eventi.illness'),
        guarigione: t('eventi.recovery'),
        pensione: t('eventi.retirement'),
        morte: t('eventi.death'),
        sepoltura: t('eventi.burial'),
        altro: t('eventi.other'),
    };
    return labels[tipo] || tipo;
};

// Carica gli eventi per la mappa
const loadEventi = async () => {
    if (!route.params.id) return;
    try {
        const response = await eventoService.getByPersona(parseInt(route.params.id));
        // La risposta può essere response.data.data o response.data a seconda della struttura
        eventi.value = response.data?.data || response.data || [];
        console.log(`Caricati ${eventi.value.length} eventi per la mappa`);
    } catch (error) {
        console.error('Errore nel caricamento degli eventi per la mappa:', error);
        eventi.value = [];
    }
};

// Carica i nonni quando la persona viene caricata
const loadNonni = async () => {
    if (!store.persona) return;
    
    // Carica nonni paterni
    if (store.persona.padre) {
        try {
            const padreResponse = await personaService.getById(store.persona.padre.id);
            const padre = padreResponse.data.data || padreResponse.data;
            if (padre.padre) nonnoPaterno.value = padre.padre;
            if (padre.madre) nonnaPaterna.value = padre.madre;
        } catch (error) {
            console.error('Errore nel caricamento dei nonni paterni:', error);
        }
    }
    
    // Carica nonni materni
    if (store.persona.madre) {
        try {
            const madreResponse = await personaService.getById(store.persona.madre.id);
            const madre = madreResponse.data.data || madreResponse.data;
            if (madre.padre) nonnoMaterno.value = madre.padre;
            if (madre.madre) nonnaMaterna.value = madre.madre;
        } catch (error) {
            console.error('Errore nel caricamento dei nonni materni:', error);
        }
    }
};

const formatDateItalian = (dateString) => {
    if (!dateString) return '-';
    
    // Se la data è già in formato italiano, restituiscila così
    if (dateString.includes('/')) {
        return dateString;
    }
    
    // Converti da formato YYYY-MM-DD a DD/MM/YYYY
    try {
        const date = new Date(dateString);
        if (isNaN(date.getTime())) {
            return dateString;
        }
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    } catch (e) {
        return dateString;
    }
};

const loadPersonaTags = async () => {
    await store.fetchPersona(route.params.id);
};

onMounted(async () => {
    await store.fetchPersona(route.params.id);
    // Carica i nonni dopo che la persona è stata caricata
    await loadNonni();
    // Carica gli eventi per la mappa
    await loadEventi();
});

// Watch per ricaricare quando cambia la persona
watch(() => route.params.id, async (newId) => {
    if (newId) {
        await store.fetchPersona(newId);
        await loadNonni();
        await loadEventi();
    }
});

const navigateToPersona = (personaId) => {
    // Usa window.location.href per navigazione diretta e affidabile
    window.location.href = `/persone/${personaId}`;
};


const handleDelete = async () => {
    if (confirm(t('persona.delete_confirm'))) {
        const result = await store.deletePersona(route.params.id);
        if (result.success) {
            router.push('/persone');
        }
    }
};
</script>

<style scoped>
.persona-card {
    @apply px-4 py-2 rounded-lg border-2 cursor-pointer transition-all w-[220px] min-h-[80px] text-center flex flex-col justify-center;
}
</style>

