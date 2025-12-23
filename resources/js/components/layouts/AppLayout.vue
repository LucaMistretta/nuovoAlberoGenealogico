<template>
    <div class="bg-gray-200 dark:bg-gray-900 h-screen flex flex-col overflow-hidden">
        <Navbar />
        <div class="flex flex-1 overflow-hidden">
            <Sidebar />
            <main class="flex-1 overflow-y-auto p-6">
                <router-view />
            </main>
        </div>
    </div>
</template>

<script setup>
import Navbar from '../common/Navbar.vue';
import Sidebar from '../common/Sidebar.vue';
</script>

