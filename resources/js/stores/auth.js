import { defineStore } from 'pinia';
import { authService } from '../services/authService';
import router from '../router';

export const useAuthStore = defineStore('auth', {
    state: () => ({
        user: null,
        token: localStorage.getItem('token'),
        isAuthenticated: !!localStorage.getItem('token'), // Inizializza basandosi sul token
    }),

    actions: {
        async login(credentials) {
            try {
                const response = await authService.login(credentials);
                this.user = response.data.user;
                this.token = response.data.token;
                this.isAuthenticated = true;
                localStorage.setItem('token', this.token);
                return { success: true };
            } catch (error) {
                return {
                    success: false,
                    error: error.response?.data?.message || 'Errore durante il login',
                };
            }
        },

        async logout() {
            try {
                if (this.token) {
                    await authService.logout();
                }
            } catch (error) {
                console.error('Errore logout:', error);
            } finally {
                this.user = null;
                this.token = null;
                this.isAuthenticated = false;
                localStorage.removeItem('token');
                // Non fare push se siamo già sulla pagina di login
                if (router.currentRoute.value.path !== '/login') {
                    router.push('/login');
                }
            }
        },

        async checkAuth() {
            if (!this.token) {
                this.isAuthenticated = false;
                return;
            }

            try {
                const response = await authService.user();
                this.user = response.data;
                this.isAuthenticated = true;
            } catch (error) {
                // Se il token non è valido, resetta lo stato ma non chiama logout
                // per evitare loop infiniti
                this.user = null;
                this.token = null;
                this.isAuthenticated = false;
                localStorage.removeItem('token');
                throw error; // Rilancia l'errore per permettere al router di gestirlo
            }
        },
    },
});

