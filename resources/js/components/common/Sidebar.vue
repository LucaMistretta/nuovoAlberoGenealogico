<template>
    <aside class="w-16 md:w-64 bg-gray-300 dark:bg-gray-800 min-h-screen p-2 md:p-4 transition-all duration-300">
        <nav class="space-y-2 bg-gray-300 dark:bg-gray-800">
            <router-link
                to="/persone"
                class="flex items-center justify-center md:justify-start gap-0 md:gap-3 px-2 md:px-4 py-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                :class="{ 'bg-blue-500 text-white': isPersoneActive }"
                :title="t('menu.persone')"
            >
                <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
                <span class="hidden md:inline">{{ t('menu.persone') }}</span>
            </router-link>
            <router-link
                to="/tipi-legame"
                class="flex items-center justify-center md:justify-start gap-0 md:gap-3 px-2 md:px-4 py-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                :class="{ 'bg-blue-500 text-white': isTipiLegameActive }"
                :title="t('menu.tipi_legame')"
            >
                <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                </svg>
                <span class="hidden md:inline">{{ t('menu.tipi_legame') }}</span>
            </router-link>
            <router-link
                to="/report"
                class="flex items-center justify-center md:justify-start gap-0 md:gap-3 px-2 md:px-4 py-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                :class="{ 'bg-blue-500 text-white': isReportActive }"
                :title="t('menu.report')"
            >
                <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
                <span class="hidden md:inline">{{ t('menu.report') }}</span>
            </router-link>
            <router-link
                to="/data-quality"
                class="flex items-center justify-center md:justify-start gap-0 md:gap-3 px-2 md:px-4 py-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                :class="{ 'bg-blue-500 text-white': isDataQualityActive }"
                :title="t('menu.data_quality')"
            >
                <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span class="hidden md:inline">{{ t('menu.data_quality') }}</span>
            </router-link>
            <router-link
                v-if="isAdmin"
                to="/users"
                class="flex items-center justify-center md:justify-start gap-0 md:gap-3 px-2 md:px-4 py-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                :class="{ 'bg-blue-500 text-white': isUsersActive }"
                :title="t('menu.users')"
            >
                <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
                <span class="hidden md:inline">{{ t('menu.users') }}</span>
            </router-link>
            <router-link
                v-if="isAdmin"
                to="/audit-logs"
                class="flex items-center justify-center md:justify-start gap-0 md:gap-3 px-2 md:px-4 py-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                :class="{ 'bg-blue-500 text-white': isAuditLogsActive }"
                :title="t('menu.audit_logs')"
            >
                <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <span class="hidden md:inline">{{ t('menu.audit_logs') }}</span>
            </router-link>
        </nav>
    </aside>
</template>

<script setup>
import { computed, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useLocaleStore } from '../../stores/locale';
import { useAuthStore } from '../../stores/auth';

const route = useRoute();
const localeStore = useLocaleStore();
const authStore = useAuthStore();

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

const isReportActive = computed(() => {
    return route.path.startsWith('/report');
});

const isDataQualityActive = computed(() => {
    return route.path.startsWith('/data-quality');
});

const isUsersActive = computed(() => {
    return route.path.startsWith('/users');
});

const isAdmin = computed(() => {
    return authStore.user?.role === 'admin';
});

const isAuditLogsActive = computed(() => {
    return route.path.startsWith('/audit-logs');
});
</script>

