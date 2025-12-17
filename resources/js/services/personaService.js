import api from './api';

export const personaService = {
    getAll(search = '', page = 1, sortBy = 'id', sortDir = 'asc') {
        const params = {};
        if (search) {
            params.search = search;
        }
        if (page > 1) {
            params.page = page;
        }
        if (sortBy) {
            params.sort_by = sortBy;
        }
        if (sortDir) {
            params.sort_dir = sortDir;
        }
        return api.get('/persone', { params });
    },

    getById(id) {
        return api.get(`/persone/${id}`);
    },

    create(data) {
        return api.post('/persone', data);
    },

    update(id, data) {
        return api.put(`/persone/${id}`, data);
    },

    delete(id) {
        return api.delete(`/persone/${id}`);
    },

    getFamily(id) {
        return api.get(`/persone/${id}/family`);
    },

    getAllForTree() {
        return api.get('/persone/tree');
    },

    getAllPeople() {
        return api.get('/persone', { params: { all: true } });
    },

    getTreeFromPerson(id) {
        return api.get(`/persone/${id}/tree`);
    },
};

