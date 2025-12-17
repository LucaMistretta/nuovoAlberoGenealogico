<template>
    <div class="bg-gray-200 dark:bg-gray-900">
        <Navbar />
        <div class="flex">
            <Sidebar />
            <main class="flex-1 p-6">
                <router-view />
            </main>
        </div>
    </div>
</template>

<script setup>
import Navbar from '../common/Navbar.vue';
import Sidebar from '../common/Sidebar.vue';
</script>

