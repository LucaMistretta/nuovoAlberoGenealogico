import api from './api';

export const mediaService = {
    /**
     * Ottiene tutti i media di una persona
     */
    async getByPersona(personaId) {
        const response = await api.get(`/persone/${personaId}/media`);
        return response.data;
    },

    /**
     * Carica un nuovo media
     */
    async upload(personaId, file, tipo, descrizione = '') {
        const formData = new FormData();
        formData.append('file', file);
        formData.append('tipo', tipo);
        if (descrizione) {
            formData.append('descrizione', descrizione);
        }

        const response = await api.post(
            `/persone/${personaId}/media`,
            formData,
            {
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
            }
        );
        return response.data;
    },

    /**
     * Elimina un media
     */
    async delete(personaId, mediaId) {
        const response = await axios.delete(
            `${API_BASE_URL}/persone/${personaId}/media/${mediaId}`
        );
        return response.data;
    },
};

