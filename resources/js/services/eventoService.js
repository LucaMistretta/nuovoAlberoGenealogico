import api from './api';

export const eventoService = {
    /**
     * Ottiene tutti gli eventi di una persona
     */
    async getByPersona(personaId) {
        const response = await api.get(`/persone/${personaId}/eventi`);
        return response.data;
    },

    /**
     * Crea un nuovo evento
     */
    async create(personaId, eventoData) {
        const response = await api.post(
            `/persone/${personaId}/eventi`,
            eventoData
        );
        return response.data;
    },

    /**
     * Aggiorna un evento
     */
    async update(personaId, eventoId, eventoData) {
        const response = await api.put(
            `/persone/${personaId}/eventi/${eventoId}`,
            eventoData
        );
        return response.data;
    },

    /**
     * Elimina un evento
     */
    async delete(personaId, eventoId) {
        const response = await api.delete(
            `/persone/${personaId}/eventi/${eventoId}`
        );
        return response.data;
    },
};


