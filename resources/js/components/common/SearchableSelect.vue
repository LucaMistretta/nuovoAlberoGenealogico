<template>
    <div class="relative w-full">
        <div class="flex flex-col gap-2">
            <!-- Input di ricerca -->
            <input
                v-model="searchQuery"
                type="text"
                :placeholder="placeholder || 'Cerca per nome o cognome...'"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                @focus="isOpen = true"
                @blur="handleBlur"
                @keydown.escape="isOpen = false"
                @input="handleSearchInput"
            />
            
            <!-- Dropdown con risultati filtrati -->
            <div 
                v-if="isOpen && (searchQuery || showAllWhenOpen)" 
                class="absolute z-50 w-full top-full mt-1 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg shadow-lg max-h-60 overflow-y-auto"
            >
                <div
                    v-for="option in filteredOptions"
                    :key="getOptionValue(option)"
                    @mousedown.prevent="selectOption(option)"
                    class="px-3 py-2 text-sm cursor-pointer hover:bg-blue-50 dark:hover:bg-gray-700 transition-colors"
                    :class="{
                        'bg-blue-100 dark:bg-gray-700': isSelected(option),
                        'opacity-50 cursor-not-allowed': isDisabled(option)
                    }"
                >
                    <slot name="option" :option="option">
                        {{ getOptionLabel(option) }}
                    </slot>
                </div>
                <div v-if="filteredOptions.length === 0" class="px-3 py-2 text-sm text-gray-500 dark:text-gray-400 text-center">
                    Nessun risultato trovato
                </div>
            </div>

            <!-- Container per select e slot per bottoni -->
            <div class="flex gap-2 items-end">
                <!-- Select tradizionale (mostrata quando non si cerca) -->
                <select
                    v-if="!isOpen || !searchQuery"
                    v-model="selectedValue"
                    :class="selectClass"
                    @change="handleSelectChange"
                    @focus="isOpen = false"
                    class="flex-1"
                >
                    <option :value="nullValue">{{ emptyOption || 'Seleziona...' }}</option>
                    <option
                        v-for="option in sortedOptions"
                        :key="getOptionValue(option)"
                        :value="getOptionValue(option)"
                        :disabled="isDisabled(option)"
                    >
                        <slot name="option" :option="option">
                            {{ getOptionLabel(option) }}
                        </slot>
                    </option>
                </select>
                
                <!-- Mostra il valore selezionato quando si cerca -->
                <div 
                    v-else-if="selectedValue && selectedOption"
                    class="flex-1 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-white"
                >
                    <slot name="option" :option="selectedOption">
                        {{ getOptionLabel(selectedOption) }}
                    </slot>
                </div>
                
                <!-- Slot per bottoni esterni -->
                <slot name="actions"></slot>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';

const props = defineProps({
    modelValue: {
        type: [String, Number],
        default: null
    },
    options: {
        type: Array,
        required: true
    },
    optionLabel: {
        type: [String, Function],
        default: 'nome_completo'
    },
    optionValue: {
        type: [String, Function],
        default: 'id'
    },
    placeholder: {
        type: String,
        default: 'Cerca...'
    },
    emptyOption: {
        type: String,
        default: 'Seleziona...'
    },
    nullValue: {
        type: [String, Number],
        default: ''
    },
    disabled: {
        type: [Function, Array],
        default: null
    },
    searchFields: {
        type: Array,
        default: () => ['nome', 'cognome', 'nome_completo']
    },
    selectClass: {
        type: String,
        default: 'w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white'
    },
    showAllWhenOpen: {
        type: Boolean,
        default: true
    }
});

const emit = defineEmits(['update:modelValue', 'change']);

const searchQuery = ref('');
const isOpen = ref(false);
const selectedValue = ref(props.modelValue);

// Funzione helper per ottenere il valore dell'opzione
const getOptionValue = (option) => {
    if (typeof props.optionValue === 'function') {
        return props.optionValue(option);
    }
    return option[props.optionValue];
};

// Funzione helper per ottenere la label dell'opzione
const getOptionLabel = (option) => {
    if (typeof props.optionLabel === 'function') {
        return props.optionLabel(option);
    }
    return option[props.optionLabel] || '';
};

// Funzione helper per verificare se un'opzione è disabilitata
const isDisabled = (option) => {
    if (!props.disabled) return false;
    if (Array.isArray(props.disabled)) {
        return props.disabled.includes(getOptionValue(option));
    }
    if (typeof props.disabled === 'function') {
        return props.disabled(option);
    }
    return false;
};

// Funzione helper per verificare se un'opzione è selezionata
const isSelected = (option) => {
    return getOptionValue(option) == selectedValue.value;
};

// Ordina le opzioni per cognome e nome
const sortedOptions = computed(() => {
    return [...props.options].sort((a, b) => {
        const cognomeA = (a.cognome || '').toLowerCase();
        const cognomeB = (b.cognome || '').toLowerCase();
        if (cognomeA !== cognomeB) {
            return cognomeA.localeCompare(cognomeB, 'it');
        }
        const nomeA = (a.nome || '').toLowerCase();
        const nomeB = (b.nome || '').toLowerCase();
        return nomeA.localeCompare(nomeB, 'it');
    });
});

// Filtra le opzioni in base alla ricerca
const filteredOptions = computed(() => {
    if (!searchQuery.value) {
        return sortedOptions.value;
    }
    
    const query = searchQuery.value.toLowerCase();
    return sortedOptions.value.filter(option => {
        return props.searchFields.some(field => {
            const value = option[field];
            if (!value) return false;
            return value.toString().toLowerCase().includes(query);
        });
    });
});

// Gestisce la selezione di un'opzione dalla lista di ricerca
const selectOption = (option) => {
    if (isDisabled(option)) return;
    
    const value = getOptionValue(option);
    selectedValue.value = value;
    const selectedLabel = getOptionLabel(option);
    searchQuery.value = selectedLabel;
    isOpen.value = false;
    emit('update:modelValue', value);
    emit('change', value, option);
};

// Gestisce il cambio della select tradizionale
const handleSelectChange = (event) => {
    const value = event.target.value === props.nullValue ? null : event.target.value;
    selectedValue.value = value;
    emit('update:modelValue', value);
    emit('change', value);
};

// Gestisce il blur dell'input di ricerca
const handleBlur = () => {
    // Delay per permettere il click sull'opzione
    setTimeout(() => {
        isOpen.value = false;
    }, 200);
};

// Watch per sincronizzare il modelValue esterno
watch(() => props.modelValue, (newValue) => {
    if (newValue !== selectedValue.value) {
        selectedValue.value = newValue || props.nullValue;
    }
}, { immediate: true });

// Computed per ottenere l'opzione selezionata
const selectedOption = computed(() => {
    if (!selectedValue.value) return null;
    return props.options.find(opt => getOptionValue(opt) == selectedValue.value);
});

// Gestisce l'input di ricerca
const handleSearchInput = () => {
    isOpen.value = true;
};

// Watch per aggiornare la ricerca quando cambia il valore selezionato
watch(selectedValue, (newValue) => {
    if (newValue && selectedOption.value) {
        // Non sovrascrivere se l'utente sta cercando
        if (!isOpen.value) {
            searchQuery.value = getOptionLabel(selectedOption.value);
        }
    } else {
        if (!isOpen.value) {
            searchQuery.value = '';
        }
    }
});
</script>

