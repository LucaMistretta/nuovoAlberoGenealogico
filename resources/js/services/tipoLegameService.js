import api from './api';

export const tipoLegameService = {
    getAll() {
        return api.get('/tipi-legame');
    },

    getById(id) {
        return api.get(`/tipi-legame/${id}`);
    },

    create(data) {
        return api.post('/tipi-legame', data);
    },

    update(id, data) {
        return api.put(`/tipi-legame/${id}`, data);
    },

    delete(id) {
        return api.delete(`/tipi-legame/${id}`);
    },
};

