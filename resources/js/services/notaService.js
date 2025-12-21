import axios from 'axios';

const API_BASE_URL = '/api';

export const notaService = {
    async getByPersona(personaId) {
        const response = await axios.get(`${API_BASE_URL}/persone/${personaId}/note`);
        return response.data;
    },

    async create(personaId, contenuto) {
        const response = await axios.post(`${API_BASE_URL}/persone/${personaId}/note`, { contenuto });
        return response.data;
    },

    async update(personaId, notaId, contenuto) {
        const response = await axios.put(`${API_BASE_URL}/persone/${personaId}/note/${notaId}`, { contenuto });
        return response.data;
    },

    async delete(personaId, notaId) {
        const response = await axios.delete(`${API_BASE_URL}/persone/${personaId}/note/${notaId}`);
        return response.data;
    },
};

