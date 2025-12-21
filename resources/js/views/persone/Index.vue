<template>
    <div>
        <div class="flex justify-between items-center mb-4">
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">{{ t('persona.persone') }}</h1>
            <div class="flex gap-2">
                <GedcomImport @imported="handleImport" />
                <router-link
                    to="/persone/create"
                    class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                    {{ t('persona.create_persona') }}
                </router-link>
            </div>
        </div>

        <AdvancedSearch @search-results="handleSearchResults" />

        <div class="mb-3 relative">
            <input
                v-model="search"
                @input="handleSearch"
                type="text"
                :placeholder="t('persona.search_placeholder')"
                class="w-full px-4 py-2 pr-10 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <button
                v-if="search"
                @click="clearSearch"
                type="button"
                class="absolute right-2 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 focus:outline-none"
                :aria-label="t('persona.clear_search')"
            >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>
        </div>

        <div v-if="store.loading" class="text-center py-8">
            <p class="text-gray-600 dark:text-gray-400">{{ t('persona.loading') }}</p>
        </div>

        <div v-else-if="store.error" class="bg-red-100 dark:bg-red-900 border border-red-400 text-red-700 dark:text-red-300 px-4 py-3 rounded">
            {{ store.error }}
        </div>

        <div v-else-if="store.persone.length === 0" class="text-center py-8">
            <p class="text-gray-600 dark:text-gray-400">{{ t('persona.no_results') }}</p>
        </div>

        <div v-else class="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-50 dark:bg-gray-700">
                        <tr>
                            <th 
                                @click="handleSort('id')"
                                class="px-3 py-1 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors select-none"
                            >
                                <div class="flex items-center gap-1.5">
                                    <span>{{ t('persona.id') }}</span>
                                    <div class="flex flex-col">
                                        <svg 
                                            v-if="store.sortBy === 'id' && store.sortDir === 'asc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else-if="store.sortBy === 'id' && store.sortDir === 'desc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else
                                            class="w-3 h-3 text-gray-300 dark:text-gray-600" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path d="M5 12a1 1 0 102 0V6.414l1.293 1.293a1 1 0 001.414-1.414l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L5 6.414V12zM15 8a1 1 0 10-2 0v5.586l-1.293-1.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L15 13.586V8z" />
                                        </svg>
                                    </div>
                                </div>
                            </th>
                            <th 
                                @click="handleSort('nome')"
                                class="px-3 py-1 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors select-none"
                            >
                                <div class="flex items-center gap-1.5">
                                    <span>{{ t('persona.nome') }}</span>
                                    <div class="flex flex-col">
                                        <svg 
                                            v-if="store.sortBy === 'nome' && store.sortDir === 'asc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else-if="store.sortBy === 'nome' && store.sortDir === 'desc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else
                                            class="w-3 h-3 text-gray-300 dark:text-gray-600" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path d="M5 12a1 1 0 102 0V6.414l1.293 1.293a1 1 0 001.414-1.414l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L5 6.414V12zM15 8a1 1 0 10-2 0v5.586l-1.293-1.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L15 13.586V8z" />
                                        </svg>
                                    </div>
                                </div>
                            </th>
                            <th 
                                @click="handleSort('cognome')"
                                class="px-3 py-1 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors select-none"
                            >
                                <div class="flex items-center gap-1.5">
                                    <span>{{ t('persona.cognome') }}</span>
                                    <div class="flex flex-col">
                                        <svg 
                                            v-if="store.sortBy === 'cognome' && store.sortDir === 'asc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else-if="store.sortBy === 'cognome' && store.sortDir === 'desc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else
                                            class="w-3 h-3 text-gray-300 dark:text-gray-600" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path d="M5 12a1 1 0 102 0V6.414l1.293 1.293a1 1 0 001.414-1.414l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L5 6.414V12zM15 8a1 1 0 10-2 0v5.586l-1.293-1.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L15 13.586V8z" />
                                        </svg>
                                    </div>
                                </div>
                            </th>
                            <th 
                                @click="handleSort('nato_il')"
                                class="px-3 py-1 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors select-none"
                            >
                                <div class="flex items-center gap-1.5">
                                    <span>{{ t('persona.nato_il') }}</span>
                                    <div class="flex flex-col">
                                        <svg 
                                            v-if="store.sortBy === 'nato_il' && store.sortDir === 'asc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else-if="store.sortBy === 'nato_il' && store.sortDir === 'desc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else
                                            class="w-3 h-3 text-gray-300 dark:text-gray-600" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path d="M5 12a1 1 0 102 0V6.414l1.293 1.293a1 1 0 001.414-1.414l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L5 6.414V12zM15 8a1 1 0 10-2 0v5.586l-1.293-1.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L15 13.586V8z" />
                                        </svg>
                                    </div>
                                </div>
                            </th>
                            <th 
                                @click="handleSort('nato_a')"
                                class="px-3 py-1 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors select-none"
                            >
                                <div class="flex items-center gap-1.5">
                                    <span>{{ t('persona.nato_a') }}</span>
                                    <div class="flex flex-col">
                                        <svg 
                                            v-if="store.sortBy === 'nato_a' && store.sortDir === 'asc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else-if="store.sortBy === 'nato_a' && store.sortDir === 'desc'"
                                            class="w-3 h-3 text-blue-600 dark:text-blue-400" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                                        </svg>
                                        <svg 
                                            v-else
                                            class="w-3 h-3 text-gray-300 dark:text-gray-600" 
                                            fill="currentColor" 
                                            viewBox="0 0 20 20"
                                        >
                                            <path d="M5 12a1 1 0 102 0V6.414l1.293 1.293a1 1 0 001.414-1.414l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L5 6.414V12zM15 8a1 1 0 10-2 0v5.586l-1.293-1.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L15 13.586V8z" />
                                        </svg>
                                    </div>
                                </div>
                            </th>
                            <th class="px-2 py-1 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider w-20">
                                {{ t('persona.actions') }}
                            </th>
                        </tr>
                    </thead>
                    <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                        <tr
                            v-for="persona in store.persone"
                            :key="persona.id"
                            class="odd:bg-gray-50 even:bg-gray-200 dark:odd:bg-gray-800 dark:even:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
                            @click="$router.push(`/persone/${persona.id}`)"
                        >
                            <td class="px-3 py-1 whitespace-nowrap text-xs text-gray-900 dark:text-white">
                                {{ persona.id }}
                            </td>
                            <td class="px-3 py-1 whitespace-nowrap text-xs text-gray-900 dark:text-white">
                                {{ persona.nome || '-' }}
                            </td>
                            <td class="px-3 py-1 whitespace-nowrap text-xs text-gray-900 dark:text-white">
                                {{ persona.cognome || '-' }}
                            </td>
                            <td class="px-3 py-1 whitespace-nowrap text-xs text-gray-900 dark:text-white">
                                {{ formatDateItalian(persona.nato_il) }}
                            </td>
                            <td class="px-3 py-1 whitespace-nowrap text-xs text-gray-900 dark:text-white">
                                {{ persona.nato_a || '-' }}
                            </td>
                            <td class="px-2 py-1 whitespace-nowrap">
                                <div class="flex items-center gap-1.5">
                                    <button
                                        @click.stop="$router.push(`/persone/${persona.id}`)"
                                        class="p-1.5 text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded transition-colors"
                                        title="Vedi dettaglio"
                                    >
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                    </button>
                                    <button
                                        @click.stop="$router.push(`/persone/${persona.id}/edit`)"
                                        class="p-1.5 text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded transition-colors"
                                        title="Modifica"
                                    >
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                        </svg>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Paginazione -->
            <div v-if="shouldShowPagination" class="bg-white dark:bg-gray-800 px-4 py-3 flex items-center justify-between border-t border-gray-200 dark:border-gray-700 sm:px-6">
                <div class="flex-1 flex justify-between sm:hidden">
                    <button
                        @click="goToPage(store.pagination.current_page - 1)"
                        :disabled="store.pagination.current_page === 1"
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 text-sm font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {{ t('pagination.previous') }}
                    </button>
                    <button
                        @click="goToPage(store.pagination.current_page + 1)"
                        :disabled="store.pagination.current_page === store.pagination.last_page"
                        class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 text-sm font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {{ t('pagination.next') }}
                    </button>
                </div>
                <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                    <div>
                        <p class="text-sm text-gray-700 dark:text-gray-300">
                            {{ t('pagination.showing') }}
                            <span class="font-medium">{{ (store.pagination.current_page - 1) * store.pagination.per_page + 1 }}</span>
                            {{ t('pagination.to') }}
                            <span class="font-medium">{{ Math.min(store.pagination.current_page * store.pagination.per_page, store.pagination.total) }}</span>
                            {{ t('pagination.of') }}
                            <span class="font-medium">{{ store.pagination.total }}</span>
                            {{ t('pagination.results') }}
                        </p>
                    </div>
                    <div>
                        <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                            <button
                                @click="goToPage(store.pagination.current_page - 1)"
                                :disabled="store.pagination.current_page === 1"
                                class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm font-medium text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                <span class="sr-only">Precedente</span>
                                <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
                                </svg>
                            </button>
                            <template v-for="page in visiblePages" :key="page">
                                <button
                                    v-if="page !== '...'"
                                    @click="goToPage(page)"
                                    :class="[
                                        page === store.pagination.current_page
                                            ? 'z-10 bg-blue-50 dark:bg-blue-900 border-blue-500 dark:border-blue-400 text-blue-600 dark:text-blue-300'
                                            : 'bg-white dark:bg-gray-800 border-gray-300 dark:border-gray-600 text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700',
                                        'relative inline-flex items-center px-4 py-2 border text-sm font-medium'
                                    ]"
                                >
                                    {{ page }}
                                </button>
                                <span
                                    v-else
                                    class="relative inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    ...
                                </span>
                            </template>
                            <button
                                @click="goToPage(store.pagination.current_page + 1)"
                                :disabled="store.pagination.current_page === store.pagination.last_page"
                                class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-sm font-medium text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                <span class="sr-only">Successivo</span>
                                <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                                </svg>
                            </button>
                        </nav>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { usePersoneStore } from '../../stores/persone';
import { useLocaleStore } from '../../stores/locale';
import AdvancedSearch from '../../components/search/AdvancedSearch.vue';
import GedcomImport from '../../components/import/GedcomImport.vue';

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
// Inizializza il campo di ricerca con lo stato salvato
const search = ref(store.search || '');
let searchTimeout = null;

const handleSearch = () => {
    if (searchTimeout) {
        clearTimeout(searchTimeout);
    }
    searchTimeout = setTimeout(() => {
        store.fetchPersone(search.value, 1, store.sortBy, store.sortDir);
    }, 300);
};

const handleSort = (column) => {
    // Se si clicca sulla stessa colonna, inverte la direzione
    // Altrimenti imposta la colonna e direzione ascendente
    if (store.sortBy === column) {
        const newDir = store.sortDir === 'asc' ? 'desc' : 'asc';
        store.setSorting(column, newDir);
        store.fetchPersone(search.value, 1, column, newDir);
    } else {
        store.setSorting(column, 'asc');
        store.fetchPersone(search.value, 1, column, 'asc');
    }
};

const goToPage = (page) => {
    if (page >= 1 && page <= store.pagination.last_page) {
        store.fetchPersone(search.value, page, store.sortBy, store.sortDir);
    }
};

const clearSearch = () => {
    search.value = '';
    store.clearState();
    store.fetchPersone('', 1, 'id', 'asc');
};

const shouldShowPagination = computed(() => {
    if (!store.pagination) return false;
    // Mostra paginazione se ci sono più pagine o se il totale è maggiore del per_page
    return store.pagination.last_page > 1 || 
           (store.pagination.total > 0 && store.pagination.total > store.pagination.per_page);
});

const visiblePages = computed(() => {
    if (!store.pagination) return [];
    
    const current = store.pagination.current_page || 1;
    const last = store.pagination.last_page || Math.ceil((store.pagination.total || 0) / (store.pagination.per_page || 15));
    const pages = [];
    
    if (last <= 1) return [];
    
    if (last <= 7) {
        // Mostra tutte le pagine se sono poche
        for (let i = 1; i <= last; i++) {
            pages.push(i);
        }
    } else {
        // Mostra pagine intorno alla corrente
        if (current <= 3) {
            for (let i = 1; i <= 5; i++) {
                pages.push(i);
            }
            pages.push('...');
            pages.push(last);
        } else if (current >= last - 2) {
            pages.push(1);
            pages.push('...');
            for (let i = last - 4; i <= last; i++) {
                pages.push(i);
            }
        } else {
            pages.push(1);
            pages.push('...');
            for (let i = current - 1; i <= current + 1; i++) {
                pages.push(i);
            }
            pages.push('...');
            pages.push(last);
        }
    }
    
    return pages;
});

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

const handleSearchResults = (results) => {
    if (results.success && results.data) {
        store.persone = results.data.data || [];
        store.pagination = results.meta || {};
    }
};

const handleImport = () => {
    // Ricarica la lista dopo l'importazione
    store.fetchPersone(search.value, store.pagination.current_page || 1, store.sortBy, store.sortDir);
};

onMounted(() => {
    // Carica i dati usando lo stato salvato (ricerca, pagina e ordinamento)
    const savedSearch = store.search || '';
    const savedPage = store.pagination.current_page || 1;
    const savedSortBy = store.sortBy || 'id';
    const savedSortDir = store.sortDir || 'asc';
    search.value = savedSearch;
    store.fetchPersone(savedSearch, savedPage, savedSortBy, savedSortDir);
});
</script>

