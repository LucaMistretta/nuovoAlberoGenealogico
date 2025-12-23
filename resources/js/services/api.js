import axios from 'axios';

const api = axios.create({
    baseURL: '/api',
    headers: {
        'Accept': 'application/json',
    },
});

// Interceptor per aggiungere il token alle richieste e gestire Content-Type
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        
        // Se i dati sono FormData, rimuovi Content-Type per permettere al browser di impostarlo automaticamente
        // con il boundary corretto per multipart/form-data
        if (config.data instanceof FormData) {
            delete config.headers['Content-Type'];
        } else if (!config.headers['Content-Type']) {
            // Imposta Content-Type solo se non è FormData e non è già impostato
            config.headers['Content-Type'] = 'application/json';
        }
        
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

// Interceptor per gestire errori di autenticazione
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            const token = localStorage.getItem('token');
            if (token) {
                // Rimuovi il token e aggiorna lo store
                localStorage.removeItem('token');
                // Non fare redirect immediato, lascia che il router gestisca
                // Solo se non siamo già sulla pagina di login
                if (window.location.pathname !== '/login') {
                    // Usa un timeout per evitare conflitti con il router
                    setTimeout(() => {
                        if (window.location.pathname !== '/login') {
                            window.location.href = '/login';
                        }
                    }, 100);
                }
            }
        }
        return Promise.reject(error);
    }
);

export default api;

