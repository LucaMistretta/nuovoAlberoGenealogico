<template>
    <div class="flex flex-col items-center">
        <!-- Nodo Persona -->
        <div 
            class="relative mb-4"
            :style="{ marginLeft: level > 0 ? '0' : '0' }"
        >
            <!-- Card Persona -->
            <div
                @click="$emit('navigate', node.id)"
                class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-4 min-w-[200px] max-w-[250px] cursor-pointer hover:shadow-xl transition-all transform hover:scale-105 border-2 border-blue-500 dark:border-blue-400"
                :class="{
                    'border-green-500 dark:border-green-400': level > 0,
                    'border-purple-500 dark:border-purple-400': level > 1,
                }"
            >
                <!-- Nome -->
                <h3 class="text-lg font-bold text-gray-900 dark:text-white text-center mb-2">
                    {{ node.nome_completo || `${node.nome} ${node.cognome}` }}
                </h3>

                <!-- Informazioni -->
                <div class="text-xs text-gray-600 dark:text-gray-400 space-y-1">
                    <div v-if="node.nato_il" class="flex items-center gap-1">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                        {{ formatDate(node.nato_il) }}
                    </div>
                    <div v-if="node.nato_a" class="flex items-center gap-1">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                        {{ node.nato_a }}
                    </div>
                    <div v-if="node.deceduto_il" class="flex items-center gap-1 text-red-600 dark:text-red-400">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        {{ formatDate(node.deceduto_il) }}
                    </div>
                </div>
            </div>

            <!-- Linea verticale verso il basso (se ha figli) -->
            <div 
                v-if="node.figli && node.figli.length > 0"
                class="absolute left-1/2 transform -translate-x-1/2 w-0.5 bg-gray-400 dark:bg-gray-600"
                :style="{ 
                    top: '100%', 
                    height: '40px',
                    marginTop: '16px'
                }"
            ></div>
        </div>

        <!-- Figli -->
        <div 
            v-if="node.figli && node.figli.length > 0"
            class="flex flex-row items-start gap-8 relative"
            :style="{ marginTop: '40px' }"
        >
            <!-- Linea orizzontale sopra i figli -->
            <div 
                class="absolute top-0 left-0 right-0 h-0.5 bg-gray-400 dark:bg-gray-600"
                :style="{ 
                    top: '-20px',
                    left: node.figli.length > 1 ? '0' : '50%',
                    right: node.figli.length > 1 ? '0' : '50%',
                    width: node.figli.length > 1 ? '100%' : '0'
                }"
            ></div>

            <!-- Linea verticale centrale (se più di un figlio) -->
            <div 
                v-if="node.figli.length > 1"
                class="absolute top-0 left-1/2 transform -translate-x-1/2 w-0.5 bg-gray-400 dark:bg-gray-600"
                :style="{ 
                    top: '-20px',
                    height: '20px'
                }"
            ></div>

            <!-- Renderizza ogni figlio -->
            <div 
                v-for="(figlio, index) in node.figli"
                :key="figlio.id"
                class="relative flex flex-col items-center"
            >
                <!-- Linea verticale dal figlio alla linea orizzontale -->
                <div 
                    class="absolute top-0 left-1/2 transform -translate-x-1/2 w-0.5 bg-gray-400 dark:bg-gray-600"
                    :style="{ 
                        top: '-20px',
                        height: '20px'
                    }"
                ></div>

                <!-- Nodo figlio (ricorsivo) -->
                <TreeNode 
                    :node="figlio" 
                    :level="level + 1"
                    @navigate="$emit('navigate', $event)"
                />
            </div>
        </div>
    </div>
</template>

<script setup>
defineProps({
    node: {
        type: Object,
        required: true,
    },
    level: {
        type: Number,
        default: 0,
    },
});

defineEmits(['navigate']);

const formatDate = (dateString) => {
    if (!dateString) return '-';
    
    try {
        const date = new Date(dateString);
        if (isNaN(date.getTime())) {
            return dateString;
        }
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    } catch (e) {
        return dateString;
    }
};
</script>

