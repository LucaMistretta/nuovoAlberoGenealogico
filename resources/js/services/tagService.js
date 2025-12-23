import api from './api';

export const tagService = {
    async getAll() {
        const response = await api.get(`/tags`);
        return response.data;
    },

    async create(tagData) {
        const response = await api.post(`/tags`, tagData);
        return response.data;
    },

    async update(id, tagData) {
        const response = await api.put(`/tags/${id}`, tagData);
        return response.data;
    },

    async delete(id) {
        const response = await api.delete(`/tags/${id}`);
        return response.data;
    },

    async attachToPersona(personaId, tagId) {
        const response = await api.post(`/persone/${personaId}/tags`, { tag_id: tagId });
        return response.data;
    },

    async detachFromPersona(personaId, tagId) {
        const response = await api.delete(`/persone/${personaId}/tags/${tagId}`);
        return response.data;
    },
};


