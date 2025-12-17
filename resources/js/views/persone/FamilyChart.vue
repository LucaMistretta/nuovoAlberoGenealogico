<template>
    <div class="bg-gray-200 dark:bg-gray-900 min-h-screen">
        <!-- Header -->
        <div class="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700 mb-3">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-2">
                <div class="flex items-center gap-3">
                    <router-link
                        to="/persone"
                        class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
                    >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                        </svg>
                        <span>{{ t('persona.back_to_list') }}</span>
                    </router-link>
                    <div>
                        <h1 class="text-xl font-bold text-gray-900 dark:text-white">{{ t('persona.family_tree_chart') }}</h1>
                        <p class="text-xs text-gray-500 dark:text-gray-400">{{ t('persona.family_tree_chart_subtitle') }}</p>
                    </div>
                </div>
            </div>
        </div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-4">
            <!-- Loading State -->
            <div v-if="loading" class="flex items-center justify-center py-12">
                <div class="text-center">
                    <div class="inline-block animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mb-3"></div>
                    <p class="text-gray-600 dark:text-gray-400">{{ t('persona.loading_info') }}</p>
                </div>
            </div>

            <!-- Error State -->
            <div v-else-if="error" class="bg-red-100 dark:bg-red-900 border border-red-400 text-red-700 dark:text-red-300 px-4 py-3 rounded">
                {{ error }}
            </div>

            <!-- Chart Container -->
            <div v-else class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
                <div class="mb-4 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">{{ t('persona.chart_legend') }}</h3>
                    <div class="flex flex-wrap gap-3 text-xs">
                        <div class="flex items-center gap-1.5">
                            <div class="w-4 h-4 rounded" style="background-color: #3b82f6; opacity: 0.2; border: 2px solid #3b82f6;"></div>
                            <span class="text-gray-600 dark:text-gray-400">{{ t('persona.generation') }} 0</span>
                        </div>
                        <div class="flex items-center gap-1.5">
                            <div class="w-4 h-4 rounded" style="background-color: #10b981; opacity: 0.2; border: 2px solid #10b981;"></div>
                            <span class="text-gray-600 dark:text-gray-400">{{ t('persona.generation') }} 1</span>
                        </div>
                        <div class="flex items-center gap-1.5">
                            <div class="w-4 h-4 rounded" style="background-color: #f59e0b; opacity: 0.2; border: 2px solid #f59e0b;"></div>
                            <span class="text-gray-600 dark:text-gray-400">{{ t('persona.generation') }} 2</span>
                        </div>
                        <div class="flex items-center gap-1.5">
                            <div class="w-4 h-4 rounded" style="background-color: #ef4444; opacity: 0.2; border: 2px solid #ef4444;"></div>
                            <span class="text-gray-600 dark:text-gray-400">{{ t('persona.generation') }} 3+</span>
                        </div>
                    </div>
                </div>
                <div id="family-chart-container" class="w-full" style="min-height: 600px;"></div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue';
import { useLocaleStore } from '../../stores/locale';
import { personaService } from '../../services/personaService';
import * as d3 from 'd3';

const localeStore = useLocaleStore();
const loading = ref(true);
const error = ref(null);
const chartInstance = ref(null);
const svgRef = ref(null);

// Helper per le traduzioni
const t = (key) => {
    return localeStore.t(key);
};

// Costruisce una struttura ad albero gerarchica per d3
const buildTreeData = (persone) => {
    if (!persone || persone.length === 0) {
        console.log('Nessuna persona disponibile');
        return null;
    }

    console.log('Costruendo albero con', persone.length, 'persone');

    // Crea una mappa per accesso rapido
    const personMap = new Map();
    persone.forEach(p => {
        personMap.set(p.id, p);
    });

    // Trova tutte le persone che sono figli (hanno padre_id o madre_id)
    const childrenIds = new Set();
    persone.forEach(persona => {
        const padreId = persona.padre?.id || persona.padre_id;
        const madreId = persona.madre?.id || persona.madre_id;
        if (padreId) childrenIds.add(persona.id);
        if (madreId) childrenIds.add(persona.id);
    });

    // Trova la radice (persona che non è figlio di nessuno)
    let rootPerson = null;
    
    // Prima prova a trovare qualcuno senza genitori
    for (const persona of persone) {
        const padreId = persona.padre?.id || persona.padre_id;
        const madreId = persona.madre?.id || persona.madre_id;
        if (!padreId && !madreId) {
            rootPerson = persona;
            break;
        }
    }

    // Se non trovato, usa la prima persona
    if (!rootPerson) {
        rootPerson = persone[0];
    }

    console.log('Radice trovata:', rootPerson.nome_completo, rootPerson.id);

    // Costruisce ricorsivamente l'albero
    const buildNode = (persona, visited = new Set()) => {
        if (visited.has(persona.id)) {
            return null; // Evita cicli infiniti
        }
        visited.add(persona.id);

        const node = {
            id: persona.id,
            name: persona.nome_completo || `${persona.nome} ${persona.cognome}`,
            data: persona,
            children: []
        };

        // Trova i figli cercando tutte le persone che hanno questa persona come padre o madre
        const figli = persone.filter(p => {
            const padreId = p.padre?.id || p.padre_id;
            const madreId = p.madre?.id || p.madre_id;
            return padreId === persona.id || madreId === persona.id;
        });

        console.log(`Persona ${persona.nome_completo} (${persona.id}) ha ${figli.length} figli`);

        // Aggiungi i figli
        figli.forEach(figlio => {
            const childNode = buildNode(figlio, new Set(visited));
            if (childNode) {
                node.children.push(childNode);
            }
        });

        return node;
    };

    const treeData = buildNode(rootPerson);
    console.log('Albero costruito:', treeData);
    return treeData;
};

// Inizializza il grafico con d3
const initChart = (treeData) => {
    console.log('initChart chiamato con treeData:', treeData);
    
    if (!treeData) {
        console.error('treeData è null o undefined');
        error.value = t('persona.no_results');
        return;
    }

    // Usa nextTick per assicurarsi che il DOM sia renderizzato
    setTimeout(() => {
        const container = document.getElementById('family-chart-container');
        console.log('Container trovato:', container);
        
        if (!container) {
            console.error('Container non trovato!');
            error.value = 'Container del grafico non trovato';
            return;
        }

        // Pulisci il container
        container.innerHTML = '';

        // Calcola il numero totale di nodi per determinare l'altezza
        const countNodes = (node) => {
            let count = 1;
            if (node.children && node.children.length > 0) {
                node.children.forEach(child => {
                    count += countNodes(child);
                });
            }
            return count;
        };
        
        const totalNodes = countNodes(treeData);
        const maxDepth = (node, depth = 0) => {
            if (!node.children || node.children.length === 0) {
                return depth;
            }
            return Math.max(...node.children.map(child => maxDepth(child, depth + 1)));
        };
        
        const depth = maxDepth(treeData);
        
        // Dimensioni con più spazio verticale
        const width = Math.max(container.clientWidth || 1200, 1200);
        // Aumenta l'altezza: almeno 200px per livello + spazio extra
        const height = Math.max(800, depth * 250 + 300);
        
        console.log('Dimensioni:', { width, height, totalNodes, depth });

        // Crea SVG
        const svg = d3.select(container)
            .append('svg')
            .attr('width', width)
            .attr('height', height)
            .style('background-color', '#f9fafb');

        const g = svg.append('g')
            .attr('transform', `translate(100, 50)`);

        // Crea il layout ad albero con più spazio verticale
        // Il primo parametro è l'altezza (verticale), il secondo è la larghezza (orizzontale)
        const tree = d3.tree()
            .nodeSize([120, 300]) // [altezza tra nodi, larghezza tra nodi]
            .separation((a, b) => {
                // Aumenta la separazione tra nodi fratelli
                return a.parent === b.parent ? 1.2 : 1;
            });

        // Colori per le diverse generazioni/rami (definiti PRIMA del loro utilizzo)
        const colorScale = d3.scaleOrdinal()
            .domain([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
            .range([
                '#3b82f6', // Blu - Generazione 0 (radice)
                '#10b981', // Verde - Generazione 1
                '#f59e0b', // Arancione - Generazione 2
                '#ef4444', // Rosso - Generazione 3
                '#8b5cf6', // Viola - Generazione 4
                '#ec4899', // Rosa - Generazione 5
                '#06b6d4', // Ciano - Generazione 6
                '#84cc16', // Lime - Generazione 7
                '#f97316', // Arancione scuro - Generazione 8
                '#6366f1', // Indaco - Generazione 9
            ]);

        // Funzione per ottenere il colore in base alla profondità
        const getNodeColor = (d) => {
            return colorScale(d.depth);
        };

        const root = d3.hierarchy(treeData);
        tree(root);
        
        console.log('Root dopo tree layout:', root);
        console.log('Numero di nodi:', root.descendants().length);
        console.log('Numero di link:', root.links().length);

        // Disegna i link con colori in base alla generazione del nodo target
        const linkGenerator = d3.linkHorizontal()
            .x(d => d.y)
            .y(d => d.x);

        g.selectAll('.link')
            .data(root.links())
            .enter()
            .append('path')
            .attr('class', 'link')
            .attr('d', linkGenerator)
            .attr('fill', 'none')
            .attr('stroke', d => getNodeColor(d.target))
            .attr('stroke-width', 2.5)
            .attr('stroke-opacity', 0.6);

        // Disegna i nodi
        const nodeGroup = g.selectAll('.node')
            .data(root.descendants())
            .enter()
            .append('g')
            .attr('class', 'node')
            .attr('transform', d => `translate(${d.y},${d.x})`);

        // Aggiungi rettangoli per i nodi (più grandi) con colori
        nodeGroup.append('rect')
            .attr('x', -80)
            .attr('y', -20)
            .attr('width', 160)
            .attr('height', 40)
            .attr('rx', 5)
            .attr('fill', d => getNodeColor(d))
            .attr('fill-opacity', 0.2)
            .attr('stroke', d => getNodeColor(d))
            .attr('stroke-width', 2.5)
            .style('cursor', 'pointer')
            .on('mouseover', function(event, d) {
                d3.select(this)
                    .attr('fill-opacity', 0.4)
                    .attr('stroke-width', 3);
            })
            .on('mouseout', function(event, d) {
                d3.select(this)
                    .attr('fill-opacity', 0.2)
                    .attr('stroke-width', 2.5);
            })
            .on('click', (event, d) => {
                // Naviga alla pagina della persona
                window.location.href = `/persone/${d.data.id}`;
            });

        // Aggiungi testo (più grande) con colore in base alla generazione
        nodeGroup.append('text')
            .attr('dy', 5)
            .attr('text-anchor', 'middle')
            .attr('font-size', '14px')
            .attr('font-family', 'sans-serif')
            .attr('font-weight', '600')
            .attr('fill', d => getNodeColor(d))
            .text(d => {
                const name = d.data.name || '';
                return name.length > 20 ? name.substring(0, 20) + '...' : name;
            });

        // Centra il grafico verticalmente
        const bounds = g.node().getBBox();
        const fullWidth = bounds.width;
        const fullHeight = bounds.height;
        
        // Ricalcola il transform iniziale per centrare
        const initialX = (width - fullWidth) / 2 - bounds.x;
        const initialY = 50;
        
        g.attr('transform', `translate(${initialX}, ${initialY})`);

        // Aggiungi zoom
        const zoom = d3.zoom()
            .scaleExtent([0.1, 3])
            .on('zoom', (event) => {
                g.attr('transform', `translate(${event.transform.x + initialX}, ${event.transform.y + initialY}) scale(${event.transform.k})`);
            });

        svg.call(zoom);

        chartInstance.value = { svg, zoom };
        console.log('Grafico inizializzato correttamente');
    }, 100);
};

// Carica i dati
const loadData = async () => {
    try {
        loading.value = true;
        error.value = null;

        const response = await personaService.getAllPeople();
        const persone = response.data.data || response.data;

        if (!persone || persone.length === 0) {
            error.value = t('persona.no_results');
            loading.value = false;
            return;
        }

        // Carica i dettagli completi per ogni persona (inclusi padre, madre, consorti)
        const personeComplete = await Promise.all(
            persone.map(async (persona) => {
                try {
                    const detailResponse = await personaService.getById(persona.id);
                    return detailResponse.data.data || detailResponse.data;
                } catch (err) {
                    console.error(`Errore nel caricamento della persona ${persona.id}:`, err);
                    return persona;
                }
            })
        );

        console.log('Persone complete caricate:', personeComplete.length);
        const treeData = buildTreeData(personeComplete);
        console.log('TreeData costruito:', treeData);
        
        if (!treeData) {
            error.value = 'Impossibile costruire l\'albero genealogico. Verifica che ci siano relazioni padre-figlio.';
            loading.value = false;
            return;
        }
        
        initChart(treeData);
        
        loading.value = false;
    } catch (err) {
        console.error('Errore nel caricamento dei dati:', err);
        error.value = err.response?.data?.message || t('common.error') || 'Errore nel caricamento dei dati';
        loading.value = false;
    }
};

onMounted(async () => {
    await loadData();
});

onUnmounted(() => {
    // Pulisci il grafico quando il componente viene smontato
    if (chartInstance.value && chartInstance.value.svg) {
        chartInstance.value.svg.remove();
    }
});

// Watch per ricaricare le traduzioni quando cambia la lingua
watch(() => localeStore.locale, () => {
    localeStore.loadTranslations();
});
</script>

<style scoped>
#family-chart-container {
    width: 100%;
    overflow: auto;
    min-height: 600px;
}

#family-chart-container :deep(.link) {
    fill: none;
    stroke: #999;
    stroke-width: 2px;
}

#family-chart-container :deep(.node rect) {
    fill: #fff;
    stroke: #333;
    stroke-width: 2px;
    transition: fill 0.3s;
}

#family-chart-container :deep(.node rect:hover) {
    fill: #e3f2fd;
}

#family-chart-container :deep(.node text) {
    font-family: sans-serif;
    font-size: 12px;
    pointer-events: none;
}
</style>

