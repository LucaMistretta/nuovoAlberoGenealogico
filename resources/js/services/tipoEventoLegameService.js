import api from './api';

export const tipoEventoLegameService = {
    /**
     * Ottiene tutti i tipi di evento legame disponibili
     */
    async getAll() {
        try {
            const response = await api.get('/tipi-evento-legame');
            return response;
        } catch (error) {
            console.error('Errore nel caricamento dei tipi evento legame:', error);
            throw error;
        }
    },
};

