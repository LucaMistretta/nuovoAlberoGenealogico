<template>
    <div class="bg-gray-200 dark:bg-gray-900">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">{{ t('users.title') }}</h1>
                <button
                    @click="showForm = true; editingUser = null"
                    class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                    + {{ t('users.add_user') }}
                </button>
            </div>

            <!-- Form Utente -->
            <div v-if="showForm" class="mb-6 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                    {{ editingUser ? t('users.edit_user') : t('users.new_user') }}
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                            {{ t('auth.name') }} *
                        </label>
                        <input
                            v-model="form.name"
                            type="text"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        />
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                            {{ t('auth.email') }} *
                        </label>
                        <input
                            v-model="form.email"
                            type="email"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        />
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                            {{ t('auth.password') }} {{ editingUser ? '(opzionale)' : '*' }}
                        </label>
                        <input
                            v-model="form.password"
                            type="password"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        />
                    </div>
                    <div>
                        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                            {{ t('users.role') }} *
                        </label>
                        <select
                            v-model="form.role"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        >
                            <option value="user">{{ t('users.role_user') }}</option>
                            <option value="admin">{{ t('users.role_admin') }}</option>
                        </select>
                    </div>
                </div>
                <div class="flex gap-2 mt-4">
                    <button
                        @click="handleSave"
                        :disabled="!form.name || !form.email || (!editingUser && !form.password) || saving"
                        class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
                    >
                        {{ t('common.save') }}
                    </button>
                    <button
                        @click="cancelForm"
                        class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-gray-600 rounded-lg hover:bg-gray-300 transition-colors"
                    >
                        {{ t('common.cancel') }}
                    </button>
                </div>
            </div>

            <!-- Lista Utenti -->
            <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-50 dark:bg-gray-700">
                        <tr>
                            <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">{{ t('users.name') }}</th>
                            <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">{{ t('users.email') }}</th>
                            <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">{{ t('users.role') }}</th>
                            <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">{{ t('common.actions') }}</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                        <tr v-for="user in users" :key="user.id" class="hover:bg-gray-50 dark:hover:bg-gray-700">
                            <td class="px-4 py-3 text-sm text-gray-900 dark:text-white">{{ user.name }}</td>
                            <td class="px-4 py-3 text-sm text-gray-600 dark:text-gray-400">{{ user.email }}</td>
                            <td class="px-4 py-3 text-sm">
                                <span class="px-2 py-1 text-xs font-medium rounded" :class="user.role === 'admin' ? 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300' : 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'">
                                    {{ user.role === 'admin' ? t('users.role_admin') : t('users.role_user') }}
                                </span>
                            </td>
                            <td class="px-4 py-3 text-sm">
                                <div class="flex gap-2">
                                    <button
                                        @click="editUser(user)"
                                        class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300"
                                    >
                                        {{ t('common.edit') }}
                                    </button>
                                    <button
                                        @click="deleteUser(user)"
                                        class="text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300"
                                    >
                                        {{ t('common.delete') }}
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useLocaleStore } from '../../stores/locale';
import axios from 'axios';

const localeStore = useLocaleStore();
const t = (key) => localeStore.t(key);

const users = ref([]);
const showForm = ref(false);
const editingUser = ref(null);
const saving = ref(false);

const form = ref({
    name: '',
    email: '',
    password: '',
    role: 'user',
});

const loadUsers = async () => {
    try {
        const response = await axios.get('/api/users');
        users.value = response.data.data || [];
    } catch (error) {
        console.error('Errore nel caricamento degli utenti:', error);
    }
};

const handleSave = async () => {
    saving.value = true;
    try {
        const data = { ...form.value };
        if (!data.password) {
            delete data.password;
        }

        if (editingUser.value) {
            await axios.put(`/api/users/${editingUser.value.id}`, data);
        } else {
            await axios.post('/api/users', data);
        }

        await loadUsers();
        cancelForm();
    } catch (error) {
        console.error('Errore nel salvataggio dell\'utente:', error);
        alert(error.response?.data?.message || t('users.save_error'));
    } finally {
        saving.value = false;
    }
};

const editUser = (user) => {
    editingUser.value = user;
    form.value = {
        name: user.name,
        email: user.email,
        password: '',
        role: user.role,
    };
    showForm.value = true;
};

const deleteUser = async (user) => {
    const confirmMessage = t('users.delete_confirm') || 'Eliminare questo utente?';
    if (!confirm(confirmMessage)) return;

    try {
        await axios.delete(`/api/users/${user.id}`);
        await loadUsers();
    } catch (error) {
        console.error('Errore nell\'eliminazione dell\'utente:', error);
        alert(error.response?.data?.message || t('users.delete_error'));
    }
};

const cancelForm = () => {
    showForm.value = false;
    editingUser.value = null;
    form.value = {
        name: '',
        email: '',
        password: '',
        role: 'user',
    };
};

onMounted(() => {
    loadUsers();
    if (Object.keys(localeStore.translations).length === 0) {
        localeStore.loadTranslations();
    }
});
</script>

