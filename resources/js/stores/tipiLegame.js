import { defineStore } from 'pinia';
import { tipoLegameService } from '../services/tipoLegameService';

export const useTipiLegameStore = defineStore('tipiLegame', {
    state: () => ({
        tipiLegame: [],
        tipoLegame: null,
        loading: false,
        error: null,
    }),

    actions: {
        async fetchTipiLegame() {
            this.loading = true;
            this.error = null;
            try {
                const response = await tipoLegameService.getAll();
                this.tipiLegame = response.data.data || response.data;
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nel caricamento dei tipi di legame';
            } finally {
                this.loading = false;
            }
        },

        async fetchTipoLegame(id) {
            this.loading = true;
            this.error = null;
            try {
                const response = await tipoLegameService.getById(id);
                this.tipoLegame = response.data.data || response.data;
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nel caricamento del tipo di legame';
            } finally {
                this.loading = false;
            }
        },

        async createTipoLegame(data) {
            this.loading = true;
            this.error = null;
            try {
                const response = await tipoLegameService.create(data);
                return { success: true, data: response.data };
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nella creazione del tipo di legame';
                return { success: false, error: this.error };
            } finally {
                this.loading = false;
            }
        },

        async updateTipoLegame(id, data) {
            this.loading = true;
            this.error = null;
            try {
                const response = await tipoLegameService.update(id, data);
                return { success: true, data: response.data };
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nell\'aggiornamento del tipo di legame';
                return { success: false, error: this.error };
            } finally {
                this.loading = false;
            }
        },

        async deleteTipoLegame(id) {
            this.loading = true;
            this.error = null;
            try {
                await tipoLegameService.delete(id);
                return { success: true };
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nell\'eliminazione del tipo di legame';
                return { success: false, error: this.error };
            } finally {
                this.loading = false;
            }
        },
    },
});

