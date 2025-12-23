import api from './api';

export const notaService = {
    async getByPersona(personaId) {
        const response = await api.get(`/persone/${personaId}/note`);
        return response.data;
    },

    async create(personaId, contenuto) {
        const response = await api.post(`/persone/${personaId}/note`, { contenuto });
        return response.data;
    },

    async update(personaId, notaId, contenuto) {
        const response = await api.put(`/persone/${personaId}/note/${notaId}`, { contenuto });
        return response.data;
    },

    async delete(personaId, notaId) {
        const response = await api.delete(`/persone/${personaId}/note/${notaId}`);
        return response.data;
    },
};


