import axios from 'axios';

const API_BASE_URL = '/api';

export const tagService = {
    async getAll() {
        const response = await axios.get(`${API_BASE_URL}/tags`);
        return response.data;
    },

    async create(tagData) {
        const response = await axios.post(`${API_BASE_URL}/tags`, tagData);
        return response.data;
    },

    async update(id, tagData) {
        const response = await axios.put(`${API_BASE_URL}/tags/${id}`, tagData);
        return response.data;
    },

    async delete(id) {
        const response = await axios.delete(`${API_BASE_URL}/tags/${id}`);
        return response.data;
    },

    async attachToPersona(personaId, tagId) {
        const response = await axios.post(`${API_BASE_URL}/persone/${personaId}/tags`, { tag_id: tagId });
        return response.data;
    },

    async detachFromPersona(personaId, tagId) {
        const response = await axios.delete(`${API_BASE_URL}/persone/${personaId}/tags/${tagId}`);
        return response.data;
    },
};

