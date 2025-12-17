import api from './api';

export const authService = {
    login(credentials) {
        return api.post('/auth/login', credentials);
    },

    logout() {
        return api.post('/auth/logout');
    },

    user() {
        return api.get('/auth/user');
    },
};

