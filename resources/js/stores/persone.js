import { defineStore } from 'pinia';
import { personaService } from '../services/personaService';

export const usePersoneStore = defineStore('persone', {
    state: () => {
        // Carica lo stato salvato dal localStorage
        const savedState = localStorage.getItem('persone_list_state');
        const defaultState = {
            persone: [],
            persona: null,
            loading: false,
            error: null,
            search: '',
            sortBy: 'id',
            sortDir: 'asc',
            pagination: {
                current_page: 1,
                last_page: 1,
                per_page: 15,
                total: 0,
            },
        };
        
        if (savedState) {
            try {
                const parsed = JSON.parse(savedState);
                return {
                    ...defaultState,
                    search: parsed.search || '',
                    sortBy: parsed.sortBy || 'id',
                    sortDir: parsed.sortDir || 'asc',
                    pagination: {
                        ...defaultState.pagination,
                        current_page: parsed.current_page || 1,
                    },
                };
            } catch (e) {
                console.error('Errore nel caricamento dello stato salvato:', e);
            }
        }
        
        return defaultState;
    },

    actions: {
        async fetchPersone(search = '', page = 1, sortBy = null, sortDir = null) {
            this.loading = true;
            this.error = null;
            // Aggiorna lo stato della ricerca
            this.search = search;
            
            // Usa i valori passati o quelli dello stato corrente
            const currentSortBy = sortBy !== null ? sortBy : this.sortBy;
            const currentSortDir = sortDir !== null ? sortDir : this.sortDir;
            
            // Aggiorna lo stato dell'ordinamento
            if (sortBy !== null) this.sortBy = sortBy;
            if (sortDir !== null) this.sortDir = sortDir;
            
            try {
                const response = await personaService.getAll(search, page, currentSortBy, currentSortDir);
                
                // Laravel con ResourceCollection restituisce i dati paginati in questo formato:
                // { data: [...], links: {...}, meta: { current_page, last_page, per_page, total, ... } }
                if (response.data && response.data.data && response.data.meta) {
                    // Risposta paginata con meta
                    this.persone = response.data.data;
                    this.pagination = {
                        current_page: response.data.meta.current_page || 1,
                        last_page: response.data.meta.last_page || 1,
                        per_page: response.data.meta.per_page || 15,
                        total: response.data.meta.total || 0,
                    };
                } else if (response.data && response.data.data && response.data.current_page) {
                    // Risposta paginata senza meta (formato alternativo)
                    this.persone = response.data.data;
                    this.pagination = {
                        current_page: response.data.current_page || 1,
                        last_page: response.data.last_page || 1,
                        per_page: response.data.per_page || 15,
                        total: response.data.total || 0,
                    };
                } else if (Array.isArray(response.data)) {
                    // Risposta non paginata (array diretto)
                    this.persone = response.data;
                    this.pagination = {
                        current_page: 1,
                        last_page: 1,
                        per_page: response.data.length,
                        total: response.data.length,
                    };
                } else {
                    this.persone = [];
                    this.pagination = {
                        current_page: 1,
                        last_page: 1,
                        per_page: 15,
                        total: 0,
                    };
                }
                
                // Salva lo stato nel localStorage
                this.saveState();
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nel caricamento delle persone';
                this.persone = [];
                this.pagination = {
                    current_page: 1,
                    last_page: 1,
                    per_page: 15,
                    total: 0,
                };
            } finally {
                this.loading = false;
            }
        },
        
        saveState() {
            // Salva lo stato corrente nel localStorage
            const stateToSave = {
                search: this.search,
                sortBy: this.sortBy,
                sortDir: this.sortDir,
                current_page: this.pagination.current_page,
            };
            localStorage.setItem('persone_list_state', JSON.stringify(stateToSave));
        },
        
        clearState() {
            // Pulisce lo stato salvato
            localStorage.removeItem('persone_list_state');
            this.search = '';
            this.sortBy = 'id';
            this.sortDir = 'asc';
            this.pagination.current_page = 1;
        },
        
        setSorting(sortBy, sortDir) {
            this.sortBy = sortBy;
            this.sortDir = sortDir;
        },

        async fetchPersona(id) {
            this.loading = true;
            this.error = null;
            try {
                const response = await personaService.getById(id);
                this.persona = response.data.data || response.data;
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nel caricamento della persona';
            } finally {
                this.loading = false;
            }
        },

        async createPersona(data) {
            this.loading = true;
            this.error = null;
            try {
                const response = await personaService.create(data);
                return { success: true, data: response.data };
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nella creazione della persona';
                return { success: false, error: this.error };
            } finally {
                this.loading = false;
            }
        },

        async updatePersona(id, data) {
            this.loading = true;
            this.error = null;
            try {
                const response = await personaService.update(id, data);
                return { success: true, data: response.data };
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nell\'aggiornamento della persona';
                return { success: false, error: this.error };
            } finally {
                this.loading = false;
            }
        },

        async deletePersona(id) {
            this.loading = true;
            this.error = null;
            try {
                await personaService.delete(id);
                return { success: true };
            } catch (error) {
                this.error = error.response?.data?.message || 'Errore nell\'eliminazione della persona';
                return { success: false, error: this.error };
            } finally {
                this.loading = false;
            }
        },
    },
});

