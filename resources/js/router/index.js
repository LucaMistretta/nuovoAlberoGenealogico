import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/auth';

const routes = [
    {
        path: '/login',
        name: 'login',
        component: () => import('../views/auth/Login.vue'),
        meta: { requiresAuth: false },
    },
    {
        path: '/',
        component: () => import('../components/layouts/AppLayout.vue'),
        meta: { requiresAuth: true },
        children: [
            {
                path: '',
                name: 'home',
                redirect: '/persone',
            },
            {
                path: '/persone',
                name: 'persone.index',
                component: () => import('../views/persone/Index.vue'),
            },
            {
                path: '/persone/create',
                name: 'persone.create',
                component: () => import('../views/persone/Create.vue'),
            },
            {
                path: '/persone/:id',
                name: 'persone.show',
                component: () => import('../views/persone/Show.vue'),
            },
            {
                path: '/persone/:id/edit',
                name: 'persone.edit',
                component: () => import('../views/persone/Edit.vue'),
            },
            {
                path: '/persone/tree',
                name: 'persone.tree',
                component: () => import('../views/persone/Tree.vue'),
            },
            {
                path: '/persone/:id/tree',
                name: 'persone.tree.from',
                component: () => import('../views/persone/Tree.vue'),
            },
            {
                path: '/persone/family-chart',
                name: 'persone.family-chart',
                component: () => import('../views/persone/FamilyChart.vue'),
            },
            {
                path: '/report',
                name: 'report.index',
                component: () => import('../views/report/Report.vue'),
            },
            {
                path: '/data-quality',
                name: 'data-quality.index',
                component: () => import('../views/quality/DataQuality.vue'),
            },
            {
                path: '/users',
                name: 'users.index',
                component: () => import('../views/users/Index.vue'),
            },
            {
                path: '/audit-logs',
                name: 'audit-logs.index',
                component: () => import('../views/audit/AuditLogs.vue'),
            },
            {
                path: '/tipi-legame',
                name: 'tipi-legame.index',
                component: () => import('../views/tipi-legame/Index.vue'),
            },
            {
                path: '/tipi-legame/create',
                name: 'tipi-legame.create',
                component: () => import('../views/tipi-legame/Create.vue'),
            },
            {
                path: '/tipi-legame/:id/edit',
                name: 'tipi-legame.edit',
                component: () => import('../views/tipi-legame/Edit.vue'),
            },
            {
                path: '/sync',
                name: 'sync.index',
                component: () => import('../views/sync/Sync.vue'),
            },
        ],
    },
];

const router = createRouter({
    history: createWebHistory(),
    routes,
});

router.beforeEach(async (to, from, next) => {
    const authStore = useAuthStore();
    
    // Se c'è un token ma l'utente non è ancora autenticato, verifica il token
    if (authStore.token && !authStore.isAuthenticated && to.meta.requiresAuth) {
        try {
            await authStore.checkAuth();
        } catch (error) {
            // Se il check fallisce, il logout viene chiamato automaticamente
        }
    }
    
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
        next('/login');
    } else if (to.path === '/login' && authStore.isAuthenticated) {
        next('/');
    } else {
        next();
    }
});

export default router;

