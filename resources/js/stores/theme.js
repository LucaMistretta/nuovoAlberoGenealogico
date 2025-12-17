import { defineStore } from 'pinia';

export const useThemeStore = defineStore('theme', {
    state: () => ({
        theme: 'dark', // default
    }),

    actions: {
        initTheme() {
            const savedTheme = localStorage.getItem('theme');
            if (savedTheme) {
                this.theme = savedTheme;
            }
            this.applyTheme();
        },

        toggleTheme() {
            this.theme = this.theme === 'dark' ? 'light' : 'dark';
            this.applyTheme();
            localStorage.setItem('theme', this.theme);
        },

        applyTheme() {
            if (this.theme === 'dark') {
                document.documentElement.classList.add('dark');
            } else {
                document.documentElement.classList.remove('dark');
            }
        },
    },
});

