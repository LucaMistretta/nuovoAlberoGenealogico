import axios from 'axios';

const API_BASE_URL = '/api';

export const eventoService = {
    /**
     * Ottiene tutti gli eventi di una persona
     */
    async getByPersona(personaId) {
        const response = await axios.get(`${API_BASE_URL}/persone/${personaId}/eventi`);
        return response.data;
    },

    /**
     * Crea un nuovo evento
     */
    async create(personaId, eventoData) {
        const response = await axios.post(
            `${API_BASE_URL}/persone/${personaId}/eventi`,
            eventoData
        );
        return response.data;
    },

    /**
     * Aggiorna un evento
     */
    async update(personaId, eventoId, eventoData) {
        const response = await axios.put(
            `${API_BASE_URL}/persone/${personaId}/eventi/${eventoId}`,
            eventoData
        );
        return response.data;
    },

    /**
     * Elimina un evento
     */
    async delete(personaId, eventoId) {
        const response = await axios.delete(
            `${API_BASE_URL}/persone/${personaId}/eventi/${eventoId}`
        );
        return response.data;
    },
};

