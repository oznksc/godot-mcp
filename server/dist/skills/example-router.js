import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
const __dirname = dirname(fileURLToPath(import.meta.url));
const EXAMPLES_DIR = join(__dirname, '..', '..', '..', 'examples');
const TYPE_KEYWORDS = {
    'player_controller_2d': [
        '2d player', 'characterbody2d', 'area2d player', 'platform player',
        'oyuncu 2d', 'hareket 2d', '2d movement', 'side scroller', 'top down',
        'jump', 'zıpla', 'dash', 'walk', 'run', 'velocity',
    ],
    'player_controller_3d': [
        '3d player', 'characterbody3d', 'third person', 'first person', 'fps', 'tps',
        'oyuncu 3d', '3d movement', 'camera controller', 'look around',
        'mouse look', 'gravity', 'jump 3d',
    ],
    'player_platformer': [
        'platformer', 'platform', 'coyote time', 'jump buffer', 'double jump',
        'wall slide', 'wall jump', 'grounded', 'air control',
    ],
    'player_3d_tps': [
        'third person controller', 'third person camera', 'aim', 'shoot',
        'over shoulder', 'strafe', 'combat 3d',
    ],
    'enemy_patrol': [
        'enemy ai', 'patrol', 'düşman', 'chase', 'investigate',
        'enemy movement', 'detection', 'alert', 'state machine enemy',
    ],
    'enemy_simple': [
        'simple enemy', 'random spawn', 'mob', 'düşman basit',
        'off screen', 'queue free',
    ],
    'combat_system': [
        'combat', 'savaş', 'turn based', 'rpg combat', 'battle',
        'damage', 'attack', 'hit', 'miss', 'stats', 'battler',
    ],
    'game_manager': [
        'game manager', 'score', 'skor', 'game loop', 'spawn',
        'restart', 'game over', 'timer', 'level management',
    ],
    'state_machine': [
        'state machine', 'durum makinesi', 'finite state', 'fsm',
        'state pattern', 'transition', 'state management',
    ],
    'health_component': [
        'health', 'can', 'hp', 'damage component', 'take damage',
        'heal', 'sağlık', 'damage system', 'health bar',
    ],
    'inventory_system': [
        'inventory', 'envanter', 'item', 'pickup', 'collect',
        'stack', 'slot', 'bag', 'loot', 'equipment',
    ],
    'save_system': [
        'save', 'kaydet', 'load', 'yükle', 'serialization',
        'persistence', 'save game', 'checkpoint', 'auto save',
    ],
    'multiplayer': [
        'multiplayer', 'çoklu oyuncu', 'online', 'enet', 'server',
        'client', 'rpc', 'sync', 'peer', 'lobby', 'network',
    ],
    'rts_unit': [
        'rts', 'strategy', 'strateji', 'unit', 'selection',
        'command', 'pathfinding', 'build', 'resource gathering',
    ],
    'space_movement': [
        'space', 'uzay', 'ship', 'gemi', 'thrust', 'orbit',
        'asteroid', 'mining', 'resource',
    ],
    'physics_piece': [
        'physics', 'fizik', 'rigidbody', 'card', 'dice',
        'tabletop', 'interaction', 'pick up', 'drop',
    ],
    'game_state': [
        'game state', 'level progression', 'card system',
        'state management', 'GameState',
    ],
    'simulation_system': [
        'simulation', 'simülasyon', 'procedural', 'evolution',
        'ai behavior', 'population', 'complex system',
    ],
    'movement_component': [
        'movement component', 'crouch', 'prone', 'mantle',
        'wall run', 'slide', 'sprint', 'strafe', 'ik',
    ],
    'grapple_physics': [
        'grapple', 'hook', 'swing', 'rope', 'physics swing',
        'grappling hook', 'tether',
    ],
    'idle_progression': [
        'idle', 'incremental', 'passive income', 'upgrade',
        'prestige', 'auto clicker', 'progression',
    ],
    'mechanic_examples': [
        'example', 'örnek', 'demo', 'tutorial', 'sample',
        'standalone', 'basic mechanic',
    ],
};
let registryCache = null;
function loadRegistry() {
    if (registryCache)
        return registryCache;
    try {
        const filePath = join(EXAMPLES_DIR, 'registry.json');
        const content = readFileSync(filePath, 'utf-8');
        const parsed = JSON.parse(content);
        registryCache = parsed.repositories;
        return registryCache;
    }
    catch {
        return [];
    }
}
function normalizeText(text) {
    return text.toLowerCase().replace(/[^\wğüşıöçĞÜŞİÖÇ\s]/g, ' ').replace(/\s+/g, ' ').trim();
}
function calculateScore(query, type, example) {
    const normalized = normalizeText(query);
    const keywords = TYPE_KEYWORDS[type] || [];
    let score = 0;
    for (const keyword of keywords) {
        if (normalized.includes(keyword.toLowerCase())) {
            score += keyword.length > 4 ? 3 : keyword.length > 2 ? 2 : 1;
        }
    }
    // Description match
    const descWords = normalizeText(example.description).split(' ');
    for (const word of descWords) {
        if (word.length > 3 && normalized.includes(word)) {
            score += 2;
        }
    }
    // Difficulty bonus
    const difficultyBonus = {
        beginner: 1,
        intermediate: 2,
        advanced: 3,
        expert: 4,
    };
    score += difficultyBonus[example.difficulty] || 1;
    return score;
}
export function findRelevantExamples(query, maxResults = 5, minScore = 4) {
    const repos = loadRegistry();
    const matches = [];
    for (const repo of repos) {
        for (const example of repo.examples) {
            const score = calculateScore(query, example.type, example);
            if (score >= minScore) {
                matches.push({ repo, example, score });
            }
        }
    }
    matches.sort((a, b) => b.score - a.score);
    return matches.slice(0, maxResults);
}
export function getExampleContent(repoUrl, examplePath) {
    // Return the repo URL and path for reference
    return `Source: ${repoUrl}/blob/main/${examplePath}`;
}
export function listRepositories() {
    return loadRegistry();
}
export function getExamplesByDifficulty(difficulty) {
    const repos = loadRegistry();
    const matches = [];
    for (const repo of repos) {
        for (const example of repo.examples) {
            if (example.difficulty === difficulty) {
                matches.push({ repo, example, score: 0 });
            }
        }
    }
    return matches;
}
export function getExamplesByType(type) {
    const repos = loadRegistry();
    const matches = [];
    for (const repo of repos) {
        for (const example of repo.examples) {
            if (example.type === type) {
                matches.push({ repo, example, score: 0 });
            }
        }
    }
    return matches;
}
//# sourceMappingURL=example-router.js.map