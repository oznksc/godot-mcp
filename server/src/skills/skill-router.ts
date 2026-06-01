import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SKILLS_DIR = join(__dirname, '..', '..', 'skills');

export interface SkillDefinition {
  id: string;
  name: string;
  file: string;
  keywords: string[];
  patterns: RegExp[];
  contextClues: string[];
  description: string;
}

export interface SkillMatch {
  skill: SkillDefinition;
  score: number;
  matchedKeywords: string[];
}

const SKILL_REGISTRY: SkillDefinition[] = [
  {
    id: 'gdscript',
    name: 'GDScript',
    file: 'gdscript.md',
    keywords: [
      'gdscript', 'script', 'code', 'coding', 'function', 'variable', 'class',
      'type hint', 'enum', 'signal', 'onready', 'export', 'static', 'void',
      'snake_case', 'pascal_case', 'sintaks', 'syntax', 'hata', 'error',
      'null reference', 'type error', 'bug', 'debug', 'refactor', 'optimize',
      'fonksiyon', 'değişken', 'sabit', 'dizi', 'array', 'dictionary',
      'string', 'int', 'float', 'bool', 'variant', 'callable', 'preload',
      'extends', 'class_name', 'super', 'self', 'pass', 'match', 'when',
    ],
    patterns: [
      /\b(func|var|const|enum|class_name|extends|signal|@onready|@export)\b/,
      /\b(_ready|_process|_physics_process|_input|_unhandled_input)\b/,
      /\b(move_and_slide|get_node|queue_free|is_on_floor|velocity)\b/,
      /\bgdscript\b/i,
      /\bscript\s*(yaz|oluştur|edit|debug|incele|review|test|çalıştır)\b/i,
    ],
    contextClues: [
      'fonksiyon nasıl yazılır', 'değişken tanımlama', 'type hint',
      'class oluştur', 'hata alıyorum', 'çalışmıyor', 'syntax error',
      'refactor', 'kod incele', 'kod kalitesi', 'best practice',
    ],
    description: 'GDScript kodlama standartları, kalıplar ve yaygın hatalar',
  },
  {
    id: 'scene-architecture',
    name: 'Sahne Mimarisi',
    file: 'scene-architecture.md',
    keywords: [
      'scene', 'sahne', 'node', 'hierarchy', 'hiyerarşi', 'prefab', 'instance',
      'composition', 'architecture', 'mimari', 'yapı', 'structure', 'organize',
      'root node', 'parent', 'child', 'children', 'autoload', 'singleton',
      'packed scene', 'instantiate', 'component', 'bileşen', 'modular',
      'proje yapısı', 'klasör', 'folder', 'directory', 'dosya yapısı',
      'level', 'harita', 'map', 'world', 'arena', 'stage',
    ],
    patterns: [
      /\b(scene|sahne)\s*(oluştur|yapı|yapılandır| organize|incele|oku)\b/i,
      /\b(node|düğü)\s*(ekle|kaldır|bul|listele|oluştur)\b/i,
      /\b(hierarchy|hiyerarşi|ağaç|tree)\b/i,
      /\b(PackedScene|instantiate|prefab)\b/,
      /\b(root|kök)\s*(node|düğü)\b/i,
      /\b(scene.*setup|sahne.*kurulum)\b/i,
    ],
    contextClues: [
      'sahne nasıl oluşturulur', 'node hiyerarşisi', 'sahne yapısı',
      'hangi root node', 'sahne organize', 'modüler sahne', 'prefab',
      'proje düzeni', 'klasör yapısı', 'level tasarımı',
    ],
    description: 'Node hiyerarşisi, prefab yapısı, sahne organizasyonu',
  },
  {
    id: 'signal-patterns',
    name: 'Sinyal Kalıpları',
    file: 'signal-patterns.md',
    keywords: [
      'signal', 'sinyal', 'connect', 'bağla', 'disconnect', 'kes', 'emit',
      'event', 'olay', 'callback', 'geri çağırma', 'observer', 'listener',
      'callable', 'bind', 'one_shot', 'deferred', 'connected',
      'signal_name', 'signal_received', 'signal_emitted',
    ],
    patterns: [
      /\b(signal|sinyal)\b/i,
      /\bconnect|disconnect|emit_signal\b/,
      /\b\.connect\(|\.disconnect\(|\.emit_signal\(/,
      /\b(signal.*connect|sinyal.*bağla)\b/i,
      /\b(event.*driven|olay.*tabanlı)\b/i,
      /\b(callable|callback|geri.*çağırma)\b/i,
    ],
    contextClues: [
      'sinyal nasıl bağlanır', 'sinyal gönder', 'sinyal al',
      'bağlantı hatası', 'disconnect', 'event system', 'observer pattern',
      'sinyal tanımla', 'custom signal', 'signal parameter',
    ],
    description: 'Event-driven mimari, sinyal bağlantı kalıpları',
  },
  {
    id: 'performance',
    name: 'Performans',
    file: 'performance.md',
    keywords: [
      'performance', 'performans', 'speed', 'hız', 'fps', 'optimization',
      'optimize', 'profil', 'profiler', 'benchmark', 'memory', 'hafıza',
      'leak', 'sızıntı', 'gc', 'garbage', 'pool', 'cache', 'batch',
      'draw call', 'render', 'frame', 'lag', 'donma', 'kasma', 'yavaş',
      'slow', 'fast', 'hızlı', 'tuning', 'budget', 'limit',
    ],
    patterns: [
      /\b(performance|performans|fps|hız)\b/i,
      /\b(optimize|iyileştir|hızlandır)\b/i,
      /\b(profiler|profil|benchmark)\b/i,
      /\b(draw.?call|render.?batch)\b/i,
      /\b(memory|hafıza|leak|sızıntı)\b/i,
      /\b(yavaş|slow|kasma|donma|lag)\b/i,
      /\b(object.?pool|cache|buffer)\b/i,
    ],
    contextClues: [
      'fps düşüyor', 'oyun yavaş', 'kasıyor', 'donuyor',
      'memory leak', 'hafıza doluyor', 'profiling', 'optimizasyon',
      'draw call azalt', 'performans artır', 'hızlandır',
    ],
    description: 'Profiling, optimizasyon, hafıza yönetimi',
  },
  {
    id: '2d-patterns',
    name: '2D Oyun',
    file: '2d-patterns.md',
    keywords: [
      '2d', 'two dimensional', 'iki boyut', 'platform', 'platformer',
      'sprite', 'tilemap', 'tile', 'parallax', 'camera2d', 'characterbody2d',
      'rigidbody2d', 'area2d', 'staticbody2d', 'collisionshape2d',
      'jump', 'zıpla', 'walk', 'yürü', 'run', 'koş', 'dash', 'double jump',
      'coyote time', 'jump buffer', 'gravity', 'yerçekimi',
      'side scroller', 'top down', 'isometric', 'pixel', 'retro',
    ],
    patterns: [
      /\b2d\b/i,
      /\b(characterbody2d|rigidbody2d|area2d|staticbody2d)\b/i,
      /\b(platform|platformer|side.?scroller)\b/i,
      /\b(tilemap|tile.?set|parallax)\b/i,
      /\b(sprite|animatedsprite|texture.?rect)\b/i,
      /\b(jump|zıpla|double.?jump|coyote|wall.?slide)\b/i,
      /\b(top.?down|isometric|pixel.?art)\b/i,
    ],
    contextClues: [
      '2d oyun', 'platform oyunu', 'yerden zıplama', 'karakter hareket',
      'tilemap', 'sprite', '2d kamera', 'pixel art', 'side scroller',
      'top down', '2d fizik', '2d collision',
    ],
    description: '2D fizik, kamera, tilemap, platformer kalıpları',
  },
  {
    id: '3d-patterns',
    name: '3D Oyun',
    file: '3d-patterns.md',
    keywords: [
      '3d', 'three dimensional', 'üç boyut', 'characterbody3d', 'rigidbody3d',
      'area3d', 'staticbody3d', 'meshinstance3d', 'camera3d', 'navmesh',
      'light', 'ışık', 'directionallight', 'omnilight', 'spotlight',
      'material', 'materyal', 'shader', 'pbr', 'albedo', 'metallic',
      'roughness', 'normal', 'emission', 'shadow', 'gölge',
      'first person', 'third person', 'fps', 'tps', 'third person camera',
      'terrain', 'landscape', 'sky', 'environment', 'fog',
      'lod', 'occlusion', 'culling', 'gi', 'global illumination',
      'baked', 'lightmap', 'reflection probe', 'gi probe',
    ],
    patterns: [
      /\b3d\b/i,
      /\b(characterbody3d|rigidbody3d|area3d|staticbody3d)\b/i,
      /\b(meshinstance|camera3d|light3d)\b/i,
      /\b(directionallight|omnilight|spotlight)\b/i,
      /\b(first.?person|third.?person|fps|tps)\b/i,
      /\b(navmesh|navigation)\b/i,
      /\b(material|materyal|pbr|albedo|metallic|roughness)\b/i,
      /\b(shadow|gölge|lightmap|gi|illumination)\b/i,
      /\b(environment|worldenvironment|sky|fog)\b/i,
    ],
    contextClues: [
      '3d oyun', '3d model', '3d kamera', 'ışıklandırma', 'materyal',
      'shader', 'navmesh', 'first person', 'third person', '3d fizik',
      'environment', 'skybox', 'reflection', 'shadow',
    ],
    description: '3D fizik, ışıklandırma, materyal, NavMesh, kamera',
  },
  {
    id: 'ui-design',
    name: 'UI/UX',
    file: 'ui-design.md',
    keywords: [
      'ui', 'gui', 'control', 'button', 'label', 'textedit', 'lineedit',
      'progressbar', 'texturerect', 'panel', 'container', 'margincontainer',
      'hbox', 'vbox', 'grid', 'flow', 'center', 'scroll',
      'anchor', 'margin', 'offset', 'layout', 'theme', 'tema', 'font',
      'stylebox', 'color', 'responsive', 'hud', 'menu', 'popup', 'dialog',
      'inventory', 'hotbar', 'tooltip', 'checkbox', 'slider',
      'user interface', 'arayüz', 'menü', 'ekran', 'screen',
    ],
    patterns: [
      /\b(ui|gui|arayüz)\b/i,
      /\b(control|button|label|textedit|lineedit)\b/i,
      /\b(container|hbox|vbox|grid|margin|scroll)\b/i,
      /\b(anchor|margin|offset|layout)\b/i,
      /\b(theme|tema|font|stylebox)\b/i,
      /\b(hud|menu|popup|dialog|tooltip)\b/i,
      /\b(inventory|hotbar|slot|item.?slot)\b/i,
      /\b(responsive|ekran.*boyut|screen.*size)\b/i,
    ],
    contextClues: [
      'ui nasıl yapılır', 'buton ekle', 'menü tasarla', 'hud oluştur',
      'tema uygula', 'font değiştir', 'anchor ayarla', 'responsive ui',
      'inventory sistemi', 'popup dialog', 'label güncelle',
    ],
    description: 'Control node\'ları, container, tema, responsive tasarım',
  },
  {
    id: 'physics',
    name: 'Fizik',
    file: 'physics.md',
    keywords: [
      'physics', 'fizik', 'collision', 'çarpışma', 'collider', 'shape',
      'rectangle', 'circle', 'capsule', 'box', 'sphere', 'convex', 'concave',
      'raycast', 'ray', 'trigger', 'tetikle', 'area', 'layer', 'mask',
      'rigidbody', 'characterbody', 'staticbody', 'kinematic',
      'bounce', 'zıplama', 'friction', 'sürtünme', 'gravity', 'yerçekimi',
      'velocity', 'hız', 'impulse', 'force', 'kuvvet', 'torque',
      'joint', 'mafsallı', 'spring', 'yay', 'damp', 'sönümleme',
      'contact', 'temas', 'one.?way', 'buoyancy', 'suda yüzdürme',
    ],
    patterns: [
      /\b(physics|fizik)\b/i,
      /\b(collision|çarpışma|collider)\b/i,
      /\b(raycast|ray|ışın)\b/i,
      /\b(characterbody|rigidbody|staticbody|area)\b/i,
      /\b(layer|mask|collision.?layer)\b/i,
      /\b(gravity|yerçekimi|velocity|hız)\b/i,
      /\b(impulse|force|kuvvet|torque)\b/i,
      /\b(bounce|friction|joint|spring|damp)\b/i,
      /\b(trigger|tetikle|one.?way)\b/i,
    ],
    contextClues: [
      'fizik nasıl çalışır', 'çarpışma shape', 'raycast kullan',
      'collision layer', 'yerçekimi', 'zıplama mekaniği', 'fizik materyali',
      'one-way platform', 'trigger area', 'fizik joint',
    ],
    description: 'Collision, RigidBody, CharacterBody, Area, fizik kalıpları',
  },
  {
    id: 'animation',
    name: 'Animasyon',
    file: 'animation.md',
    keywords: [
      'animation', 'animasyon', 'keyframe', 'track', 'tween', 'easing',
      'animationplayer', 'animationtree', 'statemachine', 'blend',
      'root motion', 'squash', 'stretch', 'procedural', 'bob', 'shake',
      'idle', 'walk', 'run', 'jump', 'attack', 'hurt', 'death',
      'sprite sheet', 'flip', 'rotation', 'scale', 'position',
      'transition', 'crossfade', 'interpolate', 'lerp',
    ],
    patterns: [
      /\b(animation|animasyon)\b/i,
      /\b(animationplayer|animationtree)\b/i,
      /\b(keyframe|track|tween)\b/i,
      /\b(animasyon.*oluştur|animation.*create)\b/i,
      /\b(squash|stretch|bob|shake)\b/i,
      /\b(root.?motion|blend|statemachine)\b/i,
      /\b(tween|easing|interpolate|lerp)\b/i,
      /\b(spritesheet|sprite.?sheet|flipbook)\b/i,
    ],
    contextClues: [
      'animasyon nasıl yapılır', 'animasyon oluştur', 'tween kullan',
      'animasyon blend', 'state machine', 'root motion', 'squash stretch',
      'keyframe ekle', 'animasyon geçişi', 'procedural animation',
    ],
    description: 'AnimationPlayer, AnimationTree, tween, procedural animasyon',
  },
  {
    id: 'audio',
    name: 'Ses',
    file: 'audio.md',
    keywords: [
      'audio', 'ses', 'sound', 'music', 'müzik', 'sfx', 'sound effect',
      'bus', 'volume', 'ses seviyesi', 'mute', 'sustur', 'fade', 'crossfade',
      'audioplayer', 'audiostream', 'wav', 'ogg', 'mp3',
      'positional', 'konum', '2d audio', '3d audio', 'attenuation',
      'reverb', 'echo', 'efekt', 'effect', 'compressor', 'limiter',
      'footstep', 'adım sesi', 'ambient', 'ortam sesi', 'bgm',
      'ducking', 'dialogue', 'diyalog',
    ],
    patterns: [
      /\b(audio|ses|sound)\b/i,
      /\b(bus|volume|mute|fade|crossfade)\b/i,
      /\b(music|müzik|sfx|sound.?effect)\b/i,
      /\b(audioplayer|audiostream)\b/i,
      /\b(positional|konum|2d.?audio|3d.?audio)\b/i,
      /\b(footstep|adım|ambient|ortam)\b/i,
      /\b(reverb|echo|compressor|limiter)\b/i,
      /\b(ducking|dialogue|diyalog)\b/i,
    ],
    contextClues: [
      'ses nasıl eklenir', 'müzik çal', 'ses efekti', 'audio bus',
      'konum bazlı ses', '3d ses', 'ses ayarları', 'fade in out',
      'footstep sesi', 'dialogue ses', 'ambient ses',
    ],
    description: 'Audio bus, müzik crossfade, positional ses, ducking',
  },
  {
    id: 'networking',
    name: 'Networking',
    file: 'networking.md',
    keywords: [
      'network', 'networking', 'multiplayer', 'çoklu oyuncu', 'online',
      'server', 'sunucu', 'client', 'istemci', 'peer', 'host',
      'rpc', 'remote', 'sync', 'senkronizasyon', 'replicate',
      'enet', 'websocket', 'lobby', 'odası', 'matchmaking',
      'authority', 'otonomi', 'player id', 'peer id',
      'interpolation', 'extrapolation', 'lag', 'latency', 'ping',
      'packet', 'reliable', 'unreliable', 'channel',
      'dedicated', 'listen', 'p2p', 'peer to peer',
    ],
    patterns: [
      /\b(network|networking|multiplayer)\b/i,
      /\b(server|sunucu|client|istemci|peer|host)\b/i,
      /\b(rpc|remote|sync|senkron)\b/i,
      /\b(enet|websocket|lobby|matchmaking)\b/i,
      /\b(authority|otonomi|multiplayer.?authority)\b/i,
      /\b(interpolation|extrapolation|lag|latency)\b/i,
      /\b(dedicated|listen|p2p)\b/i,
    ],
    contextClues: [
      'multiplayer nasıl yapılır', 'sunucu kur', 'rpc çağır',
      'pozisyon sync', 'lag compensation', 'multiplayer lobby',
      'enet', 'websocket', 'multiplayer authority',
    ],
    description: 'Multiplayer, RPC, state sync, lag compensation',
  },
  {
    id: 'export',
    name: 'Export',
    file: 'export.md',
    keywords: [
      'export', 'dışa aktar', 'build', 'derle', 'compile', 'package',
      'release', 'yayın', 'publish', 'deploy', 'deploy Et',
      'windows', 'linux', 'macos', 'android', 'ios', 'web', 'html5',
      'template', 'şablon', 'preset', 'applayout', 'icon',
      'pck', 'zip', 'installer', 'setup',
      'ci/cd', 'github actions', 'pipeline', 'otomatik build',
      'version', 'versiyon', 'semver', 'changelog', 'release notes',
      'code sign', 'notarize', 'provisioning', 'keystore',
    ],
    patterns: [
      /\b(export|dışa aktar|build|derle)\b/i,
      /\b(release|yayın|publish|deploy)\b/i,
      /\b(windows|linux|macos|android|ios|web|html5)\b/i,
      /\b(template|preset|şablon)\b/i,
      /\b(pck|installer|setup|package)\b/i,
      /\b(ci\/cd|github.?actions|pipeline)\b/i,
      /\b(version|versiyon|semver|changelog)\b/i,
      /\b(code.?sign|notarize|provisioning|keystore)\b/i,
      /\b(export.*preset|dışa.*aktar.*ayar)\b/i,
    ],
    contextClues: [
      'export nasıl yapılır', 'build al', 'windows için derle',
      'android export', 'ios export', 'web export', 'pck oluştur',
      'version bump', 'release', 'ci/cd', 'otomatik build',
    ],
    description: 'Platform ayarları, export, CI/CD, version yönetimi',
  },
];

let skillsCache: Map<string, string> = new Map();

function loadSkillContent(skill: SkillDefinition): string {
  if (skillsCache.has(skill.id)) {
    return skillsCache.get(skill.id)!;
  }
  try {
    const filePath = join(SKILLS_DIR, skill.file);
    const content = readFileSync(filePath, 'utf-8');
    skillsCache.set(skill.id, content);
    return content;
  } catch {
    return '';
  }
}

function normalizeText(text: string): string {
  return text.toLowerCase().replace(/[^\wğüşıöçĞÜŞİÖÇ\s]/g, ' ').replace(/\s+/g, ' ').trim();
}

function calculateScore(query: string, skill: SkillDefinition): SkillMatch {
  const normalizedQuery = normalizeText(query);
  const queryWords = normalizedQuery.split(' ');
  let score = 0;
  const matchedKeywords: string[] = [];

  for (const keyword of skill.keywords) {
    if (normalizedQuery.includes(keyword.toLowerCase())) {
      const weight = keyword.length > 4 ? 3 : keyword.length > 2 ? 2 : 1;
      score += weight;
      matchedKeywords.push(keyword);
    }
  }

  for (const pattern of skill.patterns) {
    const matches = normalizedQuery.match(pattern);
    if (matches) {
      score += 5 * matches.length;
      for (const match of matches) {
        if (!matchedKeywords.includes(match)) {
          matchedKeywords.push(match);
        }
      }
    }
  }

  for (const clue of skill.contextClues) {
    const clueWords = normalizeText(clue).split(' ');
    const matchCount = clueWords.filter(w => normalizedQuery.includes(w)).length;
    if (matchCount > 0) {
      score += matchCount * 2;
    }
  }

  const consecutiveBonus = queryWords.length > 2;
  if (consecutiveBonus && matchedKeywords.length >= 2) {
    score += matchedKeywords.length;
  }

  return { skill, score, matchedKeywords };
}

export function findRelevantSkills(query: string, maxSkills: number = 3, minScore: number = 5): SkillMatch[] {
  const matches: SkillMatch[] = [];

  for (const skill of SKILL_REGISTRY) {
    const match = calculateScore(query, skill);
    if (match.score >= minScore) {
      matches.push(match);
    }
  }

  matches.sort((a, b) => b.score - a.score);
  return matches.slice(0, maxSkills);
}

export function getSkillContent(skillId: string): string {
  const skill = SKILL_REGISTRY.find(s => s.id === skillId);
  if (!skill) return '';
  return loadSkillContent(skill);
}

export function getMatchedSkillsContext(query: string): string {
  const matches = findRelevantSkills(query);
  if (matches.length === 0) return '';

  const contexts: string[] = [];
  for (const match of matches) {
    const content = loadSkillContent(match.skill);
    if (content) {
      contexts.push(`## ${match.skill.name} (Relevance: ${match.score})\n\n${content}`);
    }
  }

  if (contexts.length === 0) return '';

  return `# Relevant Godot Skills\n\nThe following skill modules are relevant to this query:\n\n${contexts.join('\n\n---\n\n')}`;
}

export function listAvailableSkills(): SkillDefinition[] {
  return SKILL_REGISTRY.map(s => ({
    id: s.id,
    name: s.name,
    file: s.file,
    description: s.description,
    keywords: s.keywords,
    patterns: [],
    contextClues: [],
  }));
}
