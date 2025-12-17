// Sistema semplificato di traduzione
// In produzione, usare vue-i18n

const translations = {
    it: {},
    en: {},
    fr: {},
    de: {},
    es: {},
    pt: {},
};

export const i18n = {
    locale: 'it',

    setLocale(locale) {
        this.locale = locale;
        localStorage.setItem('locale', locale);
    },

    t(key, params = {}) {
        const keys = key.split('.');
        let value = translations[this.locale];
        
        for (const k of keys) {
            value = value?.[k];
        }
        
        if (!value) {
            return key;
        }

        // Sostituisci parametri
        return value.replace(/\{(\w+)\}/g, (match, key) => {
            return params[key] || match;
        });
    },
};

// Carica traduzioni dal localStorage o da API
const savedLocale = localStorage.getItem('locale');
if (savedLocale) {
    i18n.locale = savedLocale;
}

