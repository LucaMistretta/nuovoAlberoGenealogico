<template>
    <div class="relative">
        <select
            v-model="currentLocale"
            @change="changeLocale"
            class="px-3 py-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
            <option value="it">IT</option>
            <option value="en">EN</option>
            <option value="fr">FR</option>
            <option value="de">DE</option>
            <option value="es">ES</option>
            <option value="pt">PT</option>
        </select>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useLocaleStore } from '../../stores/locale';

const localeStore = useLocaleStore();
const currentLocale = ref(localeStore.locale);

const changeLocale = () => {
    localeStore.setLocale(currentLocale.value);
};

onMounted(() => {
    currentLocale.value = localeStore.locale;
});
</script>

