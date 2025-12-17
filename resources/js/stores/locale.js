import { defineStore } from 'pinia';

export const useLocaleStore = defineStore('locale', {
    state: () => ({
        locale: 'it', // default
        translations: {},
    }),

    actions: {
        initLocale() {
            const savedLocale = localStorage.getItem('locale');
            if (savedLocale) {
                this.locale = savedLocale;
            }
            this.loadTranslations();
        },

        setLocale(locale) {
            this.locale = locale;
            localStorage.setItem('locale', locale);
            this.loadTranslations();
        },

        async loadTranslations() {
            try {
                const response = await fetch(`/api/translations/${this.locale}`);
                if (response.ok) {
                    const data = await response.json();
                    this.translations = data;
                } else {
                    console.error('Errore caricamento traduzioni:', response.statusText);
                    this.translations = {};
                }
            } catch (error) {
                console.error('Errore caricamento traduzioni:', error);
                this.translations = {};
            }
        },

        t(key, params = {}) {
            // Sistema semplificato di traduzione
            // In produzione, usare vue-i18n o simile
            const keys = key.split('.');
            let value = this.translations;
            for (const k of keys) {
                value = value?.[k];
            }
            return value || key;
        },
    },
});

