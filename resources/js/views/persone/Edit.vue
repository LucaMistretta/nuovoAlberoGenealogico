<template>
    <div class="bg-gray-200 dark:bg-gray-900">
        <!-- Header con azioni -->
        <div class="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700 mb-3">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-2">
                <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                    <div class="flex items-center gap-3">
                        <div>
                            <h1 class="text-xl font-bold text-gray-900 dark:text-white">{{ t('persona.edit_title') }}</h1>
                            <p class="text-xs text-gray-500 dark:text-gray-400">{{ t('persona.edit_subtitle') }}</p>
                        </div>
                    </div>
                    <div v-if="store.persona" class="flex items-center gap-2">
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
                            :to="`/persone/${$route.params.id}`"
                            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
                        >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                            <span>{{ t('persona.view') }}</span>
                        </router-link>
                    </div>
                </div>
            </div>
        </div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-4">
            <!-- Loading State -->
            <div v-if="store.loading" class="flex items-center justify-center py-12">
                <div class="text-center">
                    <div class="inline-block animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mb-3"></div>
                    <p class="text-gray-600 dark:text-gray-400">{{ t('persona.loading_info') }}</p>
                </div>
            </div>

            <!-- Form -->
            <form v-else-if="store.persona" @submit.prevent="handleSubmit" class="space-y-3">
                <!-- Card Informazioni Personali -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
                    <div class="bg-gradient-to-r from-blue-500 to-blue-600 px-4 py-2">
                        <h2 class="text-base font-bold text-white flex items-center gap-2">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                            </svg>
                            {{ t('persona.personal_info') }}
                        </h2>
                    </div>
                    <div class="p-4 space-y-4">
                        <!-- Nome e Cognome -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                            <div>
                                <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                                    <span class="flex items-center gap-1.5">
                                        <svg class="w-3.5 h-3.5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                        </svg>
                                        {{ t('persona.nome') }} *
                                    </span>
                                </label>
                                <input
                                    v-model="form.nome"
                                    type="text"
                                    required
                                    class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                                    :placeholder="t('persona.enter_name')"
                                />
                            </div>

                            <div>
                                <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                                    <span class="flex items-center gap-1.5">
                                        <svg class="w-3.5 h-3.5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                        </svg>
                                        {{ t('persona.cognome') }} *
                                    </span>
                                </label>
                                <input
                                    v-model="form.cognome"
                                    type="text"
                                    required
                                    class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                                    :placeholder="t('persona.enter_surname')"
                                />
                            </div>
                        </div>

                        <!-- Nascita -->
                        <div class="border-t border-gray-200 dark:border-gray-700 pt-3">
                            <h3 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide mb-2 flex items-center gap-1.5">
                                <svg class="w-3.5 h-3.5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                </svg>
                                {{ t('persona.birth') }}
                            </h3>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                                <div>
                                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                                        {{ t('persona.birth_place') }}
                                    </label>
                                    <input
                                        v-model="form.nato_a"
                                        type="text"
                                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors"
                                        :placeholder="t('persona.birth_place_example')"
                                    />
                                </div>
                                <div>
                                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                                        {{ t('persona.birth_date') }}
                                    </label>
                                    <input
                                        v-model="form.nato_il"
                                        type="date"
                                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors"
                                    />
                                </div>
                            </div>
                        </div>

                        <!-- Decesso -->
                        <div class="border-t border-gray-200 dark:border-gray-700 pt-3">
                            <h3 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide mb-2 flex items-center gap-1.5">
                                <svg class="w-3.5 h-3.5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                {{ t('persona.death') }}
                            </h3>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                                <div>
                                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                                        {{ t('persona.death_place') }}
                                    </label>
                                    <input
                                        v-model="form.deceduto_a"
                                        type="text"
                                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-red-500 focus:border-transparent transition-colors"
                                        :placeholder="t('persona.death_place_example')"
                                    />
                                </div>
                                <div>
                                    <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                                        {{ t('persona.death_date') }}
                                    </label>
                                    <input
                                        v-model="form.deceduto_il"
                                        type="date"
                                        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-red-500 focus:border-transparent transition-colors"
                                    />
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
                        <div class="space-y-2">
                            <div class="flex items-center justify-between">
                                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">{{ t('persona.genitori') }}</h4>
                            </div>
                            
                            <!-- Padre -->
                            <div>
                                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">{{ t('persona.padre') }}</label>
                                <div v-if="selectedPadreId || store.persona.padre" class="mb-1.5">
                                    <div 
                                        v-if="store.persona.padre && !selectedPadreId"
                                        @click="navigateToPersonaEdit(store.persona.padre.id)"
                                        class="group p-2 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800 hover:border-blue-300 dark:hover:border-blue-700 transition-colors cursor-pointer"
                                    >
                                        <div class="flex items-center gap-2">
                                            <div class="flex-shrink-0 w-7 h-7 bg-blue-100 dark:bg-blue-900/40 rounded-lg flex items-center justify-center">
                                                <svg class="w-3.5 h-3.5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                                </svg>
                                            </div>
                                            <div class="flex-1 min-w-0">
                                                <p class="text-xs font-semibold text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors truncate">
                                                    {{ store.persona.padre.nome_completo }}
                                                </p>
                                            </div>
                                            <button
                                                type="button"
                                                @click.stop="selectedPadreId = ''; store.persona.padre = null"
                                                class="p-0.5 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded"
                                            >
                                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                    <div v-else-if="selectedPadreId" class="p-2 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                                        <div class="flex items-center gap-2">
                                            <span class="flex-1 text-xs text-gray-900 dark:text-white">
                                                {{ getPersonaName(selectedPadreId) }}
                                            </span>
                                            <button
                                                type="button"
                                                @click="selectedPadreId = ''"
                                                class="p-0.5 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded"
                                            >
                                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                <div class="space-y-1.5">
                                    <div class="flex gap-1.5">
                                        <select
                                            v-model="newPadreId"
                                            class="flex-1 px-2.5 py-1.5 text-xs border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                                        >
                                            <option value="">{{ t('persona.select_existing_father') }}</option>
                                            <option
                                                v-for="persona in sortedAvailablePeople"
                                                :key="persona.id"
                                                :value="persona.id"
                                                :disabled="persona.id === parseInt(route.params.id)"
                                            >
                                                {{ persona.nome_completo }} (ID: {{ persona.id }})
                                            </option>
                                        </select>
                                    <button
                                        type="button"
                                        @click="addPadre"
                                        :disabled="!newPadreId"
                                        class="p-1.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                    >
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                        </svg>
                                    </button>
                                    <button
                                        type="button"
                                        @click="creaNuovoPadre"
                                        class="p-1.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                                        :title="t('persona.create_new_father')"
                                    >
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                        </svg>
                                    </button>
                                    </div>
                                </div>
                            </div>

                            <!-- Madre -->
                            <div>
                                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">{{ t('persona.madre') }}</label>
                                <div v-if="selectedMadreId || store.persona.madre" class="mb-1.5">
                                    <div 
                                        v-if="store.persona.madre && !selectedMadreId"
                                        @click="navigateToPersonaEdit(store.persona.madre.id)"
                                        class="group p-2 bg-pink-50 dark:bg-pink-900/20 rounded-lg border border-pink-200 dark:border-pink-800 hover:border-pink-300 dark:hover:border-pink-700 transition-colors cursor-pointer"
                                    >
                                        <div class="flex items-center gap-2">
                                            <div class="flex-shrink-0 w-7 h-7 bg-pink-100 dark:bg-pink-900/40 rounded-lg flex items-center justify-center">
                                                <svg class="w-3.5 h-3.5 text-pink-600 dark:text-pink-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                                </svg>
                                            </div>
                                            <div class="flex-1 min-w-0">
                                                <p class="text-xs font-semibold text-gray-900 dark:text-white group-hover:text-pink-600 dark:group-hover:text-pink-400 transition-colors truncate">
                                                    {{ store.persona.madre.nome_completo }}
                                                </p>
                                            </div>
                                            <button
                                                type="button"
                                                @click.stop="selectedMadreId = ''; store.persona.madre = null"
                                                class="p-0.5 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded"
                                            >
                                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                    <div v-else-if="selectedMadreId" class="p-2 bg-pink-50 dark:bg-pink-900/20 rounded-lg border border-pink-200 dark:border-pink-800">
                                        <div class="flex items-center gap-2">
                                            <span class="flex-1 text-xs text-gray-900 dark:text-white">
                                                {{ getPersonaName(selectedMadreId) }}
                                            </span>
                                            <button
                                                type="button"
                                                @click="selectedMadreId = ''"
                                                class="p-0.5 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded"
                                            >
                                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                <div class="space-y-1.5">
                                    <div class="flex gap-1.5">
                                        <select
                                            v-model="newMadreId"
                                            class="flex-1 px-2.5 py-1.5 text-xs border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                                        >
                                            <option value="">{{ t('persona.select_existing_mother') }}</option>
                                            <option
                                                v-for="persona in sortedAvailablePeople"
                                                :key="persona.id"
                                                :value="persona.id"
                                                :disabled="persona.id === parseInt(route.params.id)"
                                            >
                                                {{ persona.nome_completo }} (ID: {{ persona.id }})
                                            </option>
                                        </select>
                                        <button
                                            type="button"
                                            @click="addMadre"
                                            :disabled="!newMadreId"
                                            class="p-1.5 bg-pink-600 text-white rounded-lg hover:bg-pink-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                        >
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                            </svg>
                                        </button>
                                        <button
                                            type="button"
                                            @click="creaNuovaMadre"
                                            class="p-1.5 bg-pink-600 text-white rounded-lg hover:bg-pink-700 transition-colors"
                                            :title="t('persona.create_new_mother')"
                                        >
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Consorti e Figli -->
                        <div class="space-y-2">
                            <!-- Consorti -->
                            <div>
                                <div class="flex items-center justify-between mb-2">
                                    <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">{{ t('persona.consorti') }}</h4>
                                    <button
                                        type="button"
                                        @click="showAddConsorte = true"
                                        class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-purple-700 dark:text-purple-300 bg-purple-100 dark:bg-purple-900/30 rounded-lg hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors"
                                    >
                                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                        </svg>
                                        {{ t('persona.add') }}
                                    </button>
                                </div>
                                
                                <!-- Selettore per aggiungere consorte -->
                                <div v-if="showAddConsorte" class="mb-2 p-2 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800">
                                    <div class="flex flex-col gap-2">
                                        <div class="flex gap-2">
                                            <select
                                                v-model="newConsorteId"
                                                class="flex-1 px-3 py-2 border border-purple-300 dark:border-purple-700 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm"
                                            >
                                                <option value="">{{ t('persona.select_existing_spouse') }}</option>
                                                <option
                                                    v-for="persona in sortedAvailablePeople"
                                                    :key="persona.id"
                                                    :value="persona.id"
                                                    :disabled="persona.id === route.params.id || selectedConsortiIds.includes(persona.id)"
                                                >
                                                    {{ persona.nome_completo }} (ID: {{ persona.id }})
                                                </option>
                                            </select>
                                            <button
                                                type="button"
                                                @click="addConsorte"
                                                :disabled="!newConsorteId"
                                                class="p-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                                :title="t('persona.add_spouse')"
                                            >
                                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                                </svg>
                                            </button>
                                            <button
                                                type="button"
                                                @click="showAddConsorte = false"
                                                class="p-2 bg-gray-300 dark:bg-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-400 dark:hover:bg-gray-700 transition-colors"
                                                :title="t('common.cancel')"
                                            >
                                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                                </svg>
                                            </button>
                                        </div>
                                        <div class="text-center text-sm text-gray-600 dark:text-gray-400">{{ t('persona.or') }}</div>
                                        <button
                                            type="button"
                                            @click="creaNuovoConsorte"
                                            class="w-full px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors flex items-center justify-center gap-2"
                                        >
                                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                            </svg>
                                            {{ t('persona.create_new_spouse') }}
                                        </button>
                                    </div>
                                </div>

                                <div v-if="selectedConsorti.length > 0" class="space-y-1.5">
                                    <div
                                        v-for="consorte in selectedConsorti"
                                        :key="consorte.id"
                                        class="group p-2 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800 hover:border-purple-300 dark:hover:border-purple-700 transition-colors"
                                    >
                                        <div class="flex items-center gap-2">
                                            <div class="flex-shrink-0 w-7 h-7 bg-purple-100 dark:bg-purple-900/40 rounded-lg flex items-center justify-center">
                                                <svg class="w-3.5 h-3.5 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                                                </svg>
                                            </div>
                                            <div class="flex-1 min-w-0">
                                                <p class="text-sm font-semibold text-gray-900 dark:text-white truncate">
                                                    {{ consorte.nome_completo }}
                                                </p>
                                            </div>
                                            <button
                                                type="button"
                                                @click="removeConsorte(consorte.id)"
                                                class="p-1 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded transition-colors"
                                                :title="t('persona.remove_spouse')"
                                            >
                                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                <p v-else class="text-xs text-gray-500 dark:text-gray-400 italic">{{ t('persona.no_spouse_added') }}</p>
                            </div>

                            <!-- Figli -->
                            <div>
                                <div class="flex items-center justify-between mb-2">
                                    <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">{{ t('persona.figli') }}</h4>
                                    <button
                                        type="button"
                                        @click="showAddFiglio = true"
                                        class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-green-700 dark:text-green-300 bg-green-100 dark:bg-green-900/30 rounded-lg hover:bg-green-200 dark:hover:bg-green-900/50 transition-colors"
                                    >
                                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                        </svg>
                                        {{ t('persona.add') }}
                                    </button>
                                </div>

                                <!-- Selettore per aggiungere figlio -->
                                <div v-if="showAddFiglio" class="mb-2 p-2 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                                    <div class="flex flex-col gap-2">
                                        <div class="flex gap-2">
                                            <select
                                                v-model="newFiglioId"
                                                class="flex-1 px-3 py-2 border border-green-300 dark:border-green-700 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm"
                                            >
                                                <option value="">{{ t('persona.select_existing_child') }}</option>
                                                <option
                                                    v-for="persona in sortedAvailablePeople"
                                                    :key="persona.id"
                                                    :value="persona.id"
                                                    :disabled="persona.id === route.params.id || selectedFigliIds.includes(persona.id)"
                                                >
                                                    {{ persona.nome_completo }} (ID: {{ persona.id }})
                                                </option>
                                            </select>
                                            <button
                                                type="button"
                                                @click="addFiglio"
                                                :disabled="!newFiglioId"
                                                class="p-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                                :title="t('persona.add_child')"
                                            >
                                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                                </svg>
                                            </button>
                                            <button
                                                type="button"
                                                @click="showAddFiglio = false"
                                                class="p-2 bg-gray-300 dark:bg-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-400 dark:hover:bg-gray-700 transition-colors"
                                                :title="t('common.cancel')"
                                            >
                                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                                </svg>
                                            </button>
                                        </div>
                                        <div class="text-center text-sm text-gray-600 dark:text-gray-400">{{ t('persona.or') }}</div>
                                        <button
                                            type="button"
                                            @click="creaNuovoFiglio"
                                            class="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors flex items-center justify-center gap-2"
                                        >
                                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                            </svg>
                                            {{ t('persona.create_new_child') }}
                                        </button>
                                    </div>
                                </div>

                                <div v-if="selectedFigli.length > 0" class="space-y-1.5">
                                    <div
                                        v-for="figlio in selectedFigli"
                                        :key="figlio.id"
                                        class="group p-2 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800 hover:border-green-300 dark:hover:border-green-700 transition-colors"
                                    >
                                        <div class="flex items-center gap-2">
                                            <div class="flex-shrink-0 w-7 h-7 bg-green-100 dark:bg-green-900/40 rounded-lg flex items-center justify-center">
                                                <svg class="w-3.5 h-3.5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                                                </svg>
                                            </div>
                                            <div class="flex-1 min-w-0">
                                                <p class="text-sm font-semibold text-gray-900 dark:text-white truncate">
                                                    {{ figlio.nome_completo }}
                                                </p>
                                            </div>
                                            <button
                                                type="button"
                                                @click="removeFiglio(figlio.id)"
                                                class="p-1 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded transition-colors"
                                                :title="t('persona.remove_child')"
                                            >
                                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                <p v-else class="text-xs text-gray-500 dark:text-gray-400 italic">{{ t('persona.no_child_added') }}</p>
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

                <!-- Bottoni azione -->
                <div class="flex flex-col sm:flex-row justify-end gap-2 pt-2">
                    <router-link
                        :to="`/persone/${$route.params.id}`"
                        class="inline-flex items-center justify-center gap-1.5 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
                    >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                        <span>{{ t('common.cancel') }}</span>
                    </router-link>
                    <button
                        type="submit"
                        :disabled="loading"
                        class="inline-flex items-center justify-center gap-1.5 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors shadow-sm"
                    >
                        <svg v-if="!loading" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <svg v-else class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>{{ loading ? t('persona.saving') : t('persona.save_changes') }}</span>
                    </button>
                </div>
            </form>
        </div>
    </div>
</template>

<script setup>
import { ref, watch, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { usePersoneStore } from '../../stores/persone';
import { useLocaleStore } from '../../stores/locale';
import { personaService } from '../../services/personaService';
import { tipoLegameService } from '../../services/tipoLegameService';

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

const form = ref({
    nome: '',
    cognome: '',
    nato_a: '',
    nato_il: '',
    deceduto_a: '',
    deceduto_il: '',
});

const loading = ref(false);
const availablePeople = ref([]);
const tipiLegame = ref([]);
const showAddConsorte = ref(false);
const showAddFiglio = ref(false);
const newConsorteId = ref('');
const newFiglioId = ref('');
const newPadreId = ref('');
const newMadreId = ref('');
const selectedConsorti = ref([]);
const selectedFigli = ref([]);
const selectedPadreId = ref('');
const selectedMadreId = ref('');

// Computed per gli ID selezionati
const selectedConsortiIds = computed(() => selectedConsorti.value.map(c => c.id));
const selectedFigliIds = computed(() => selectedFigli.value.map(f => f.id));

// Funzione helper per ordinare le persone per cognome e poi nome
const sortPeople = (people) => {
    return [...people].sort((a, b) => {
        const cognomeA = (a.cognome || '').toLowerCase();
        const cognomeB = (b.cognome || '').toLowerCase();
        if (cognomeA !== cognomeB) {
            return cognomeA.localeCompare(cognomeB, 'it');
        }
        const nomeA = (a.nome || '').toLowerCase();
        const nomeB = (b.nome || '').toLowerCase();
        return nomeA.localeCompare(nomeB, 'it');
    });
};

// Computed per ordinare le persone disponibili
const sortedAvailablePeople = computed(() => {
    return sortPeople(availablePeople.value);
});

onMounted(async () => {
    await Promise.all([
        store.fetchPersona(route.params.id),
        loadAvailablePeople(),
        loadTipiLegame()
    ]);
});

// Carica tutte le persone disponibili
const loadAvailablePeople = async () => {
    try {
        const response = await personaService.getAllPeople();
        availablePeople.value = response.data.data || response.data || [];
    } catch (error) {
        console.error('Errore nel caricamento delle persone:', error);
    }
};

// Carica i tipi di legame
const loadTipiLegame = async () => {
    try {
        const response = await tipoLegameService.getAll();
        tipiLegame.value = response.data.data || response.data || [];
    } catch (error) {
        console.error('Errore nel caricamento dei tipi di legame:', error);
    }
};

watch(() => store.persona, (persona) => {
    if (persona) {
        form.value = {
            nome: persona.nome || '',
            cognome: persona.cognome || '',
            nato_a: persona.nato_a || '',
            nato_il: persona.nato_il || '',
            deceduto_a: persona.deceduto_a || '',
            deceduto_il: persona.deceduto_il || '',
        };
        
        // Inizializza consorti e figli selezionati
        selectedConsorti.value = persona.consorti ? [...persona.consorti] : [];
        selectedFigli.value = persona.figli ? [...persona.figli] : [];
        
        // Inizializza genitori selezionati
        selectedPadreId.value = persona.padre ? persona.padre.id.toString() : '';
        selectedMadreId.value = persona.madre ? persona.madre.id.toString() : '';
    }
}, { immediate: true });

const navigateToPersonaEdit = (personaId) => {
    window.location.href = `/persone/${personaId}/edit`;
};

// Aggiungi consorte
const addConsorte = () => {
    if (!newConsorteId.value) return;
    
    const persona = sortedAvailablePeople.value.find(p => p.id === parseInt(newConsorteId.value));
    if (persona && !selectedConsortiIds.value.includes(persona.id)) {
        selectedConsorti.value.push(persona);
        newConsorteId.value = '';
        showAddConsorte.value = false;
    }
};

// Rimuovi consorte
const removeConsorte = (id) => {
    selectedConsorti.value = selectedConsorti.value.filter(c => c.id !== id);
};

// Aggiungi figlio
const addFiglio = () => {
    if (!newFiglioId.value) return;
    
    const persona = sortedAvailablePeople.value.find(p => p.id === parseInt(newFiglioId.value));
    if (persona && !selectedFigliIds.value.includes(persona.id)) {
        selectedFigli.value.push(persona);
        newFiglioId.value = '';
        showAddFiglio.value = false;
    }
};

// Rimuovi figlio
const removeFiglio = (id) => {
    selectedFigli.value = selectedFigli.value.filter(f => f.id !== id);
};

// Aggiungi padre
const addPadre = () => {
    if (!newPadreId.value) return;
    selectedPadreId.value = newPadreId.value;
    newPadreId.value = '';
};

// Aggiungi madre
const addMadre = () => {
    if (!newMadreId.value) return;
    selectedMadreId.value = newMadreId.value;
    newMadreId.value = '';
};

// Crea nuovo padre
const creaNuovoPadre = () => {
    router.push({
        path: '/persone/create',
        query: {
            relazione_persona_id: route.params.id,
            relazione_tipo: 'padre',
            return_to: `/persone/${route.params.id}/edit`
        }
    });
};

// Crea nuova madre
const creaNuovaMadre = () => {
    router.push({
        path: '/persone/create',
        query: {
            relazione_persona_id: route.params.id,
            relazione_tipo: 'madre',
            return_to: `/persone/${route.params.id}/edit`
        }
    });
};

// Crea nuovo consorte
const creaNuovoConsorte = () => {
    router.push({
        path: '/persone/create',
        query: {
            relazione_persona_id: route.params.id,
            relazione_tipo: 'coniuge',
            return_to: `/persone/${route.params.id}/edit`
        }
    });
};

// Crea nuovo figlio
const creaNuovoFiglio = () => {
    router.push({
        path: '/persone/create',
        query: {
            relazione_persona_id: route.params.id,
            relazione_tipo: 'figlio',
            return_to: `/persone/${route.params.id}/edit`
        }
    });
};

// Ottieni nome persona per ID
const getPersonaName = (id) => {
    if (!id) return '';
    const persona = sortedAvailablePeople.value.find(p => p.id === parseInt(id));
    return persona ? persona.nome_completo : '';
};

// Trova ID tipo legame per nome
const getTipoLegameId = (nome) => {
    const tipo = tipiLegame.value.find(t => t.nome === nome);
    return tipo ? tipo.id : null;
};

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
        
        // Prepara le relazioni (consorti e figli)
        const relazioni = [];
        
        // Aggiungi consorti (tipo: coniuge)
        const coniugeId = getTipoLegameId('coniuge');
        if (coniugeId) {
            selectedConsorti.value.forEach(consorte => {
                relazioni.push({
                    persona_collegata_id: consorte.id,
                    tipo_legame_id: coniugeId,
                });
            });
        }
        
        // Aggiungi figli (tipo: padre o madre - usiamo padre come default)
        const padreId = getTipoLegameId('padre');
        if (padreId) {
            selectedFigli.value.forEach(figlio => {
                relazioni.push({
                    persona_collegata_id: figlio.id,
                    tipo_legame_id: padreId,
                });
            });
        }
        
        // Prepara i dati da inviare
        const dataToSend = {
            ...form.value,
        };
        
        if (Object.keys(genitori).length > 0) {
            dataToSend.genitori = genitori;
        }
        
        if (relazioni.length > 0) {
            dataToSend.relazioni = relazioni;
        }
        
        const result = await store.updatePersona(route.params.id, dataToSend);
        
        if (result.success) {
            router.push(`/persone/${route.params.id}`);
        }
    } catch (error) {
        console.error('Errore nel salvataggio:', error);
    } finally {
        loading.value = false;
    }
};
</script>
