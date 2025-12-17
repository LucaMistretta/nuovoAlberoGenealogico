import './bootstrap';
import '../css/app.css';

import { createApp } from 'vue';
import { createPinia } from 'pinia';
import router from './router';
import App from './App.vue';
import { useThemeStore } from './stores/theme';
import { useLocaleStore } from './stores/locale';

const app = createApp(App);
const pinia = createPinia();

app.use(pinia);
app.use(router);

// Inizializza tema e lingua prima di montare l'app
const themeStore = useThemeStore();
themeStore.initTheme();

const localeStore = useLocaleStore();
localeStore.initLocale();

app.mount('#app');

