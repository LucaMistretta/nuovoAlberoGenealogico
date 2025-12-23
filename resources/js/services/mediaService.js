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
        if (!file) {
            throw new Error('File non specificato');
        }
        
        const formData = new FormData();
        formData.append('file', file);
        formData.append('tipo', tipo);
        if (descrizione) {
            formData.append('descrizione', descrizione);
        }

        // Non impostare Content-Type manualmente, axios lo gestisce automaticamente per FormData
        const response = await api.post(
            `/persone/${personaId}/media`,
            formData,
            {
                // Timeout per upload
                timeout: 60000, // 60 secondi
            }
        );
        
        return response.data;
    },

    /**
     * Elimina un media
     */
    async delete(personaId, mediaId) {
        const response = await api.delete(
            `/persone/${personaId}/media/${mediaId}`
        );
        return response.data;
    },
};

