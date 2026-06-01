import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import {
  findRelevantExamples,
  listRepositories,
  getExamplesByDifficulty,
  getExamplesByType,
} from './example-router.js';

export function registerExampleTools(server: McpServer): void {
  server.tool(
    'example_find',
    'Find real open-source Godot game code examples matching a natural language query',
    {
      query: z.string().describe('Natural language description of what you need (e.g., "2D platformer player controller with double jump")'),
      max_results: z.number().default(5).describe('Maximum number of examples to return'),
    },
    async ({ query, max_results }) => {
      const matches = findRelevantExamples(query, max_results);
      if (matches.length === 0) {
        return {
          content: [{ type: 'text' as const, text: `No examples found for: "${query}"\n\nTry broader terms or use example_list_repos to see all available repositories.` }],
        };
      }

      const results = matches.map((m, i) => {
        return [
          `### ${i + 1}. ${m.example.path}`,
          `**Repository:** ${m.repo.name} (${m.repo.stars}★)`,
          `**Type:** ${m.example.type}`,
          `**Difficulty:** ${m.example.difficulty}`,
          `**Description:** ${m.example.description}`,
          `**Source:** ${m.repo.url}/blob/main/${m.example.path}`,
          `**License:** ${m.repo.license}`,
          '',
        ].join('\n');
      }).join('\n');

      return {
        content: [{ type: 'text' as const, text: `# Relevant Open-Source Godot Examples\n\n${results}` }],
      };
    }
  );

  server.tool(
    'example_list_repos',
    'List all open-source Godot game repositories in the examples library',
    {},
    async () => {
      const repos = listRepositories();
      const list = repos.map(r =>
        `- **${r.name}** (${r.stars}★) — ${r.description}\n  URL: ${r.url}\n  License: ${r.license} | Examples: ${r.examples.length}`
      ).join('\n\n');
      return {
        content: [{ type: 'text' as const, text: `# Open-Source Godot Game Repositories\n\nTotal: ${repos.length} repositories\n\n${list}` }],
      };
    }
  );

  server.tool(
    'example_get_by_type',
    'Get examples filtered by type (player, enemy, combat, inventory, etc.)',
    {
      type: z.enum([
        'player_controller_2d', 'player_controller_3d', 'player_platformer',
        'player_3d_tps', 'enemy_patrol', 'enemy_simple', 'combat_system',
        'game_manager', 'state_machine', 'health_component', 'inventory_system',
        'save_system', 'multiplayer', 'rts_unit', 'space_movement',
        'physics_piece', 'game_state', 'simulation_system', 'movement_component',
        'grapple_physics', 'idle_progression', 'mechanic_examples',
      ]).describe('Example type to filter by'),
    },
    async ({ type }) => {
      const matches = getExamplesByType(type);
      if (matches.length === 0) {
        return { content: [{ type: 'text' as const, text: `No examples of type: ${type}` }] };
      }

      const results = matches.map(m =>
        `- **${m.example.path}** (${m.repo.name}) — ${m.example.description}\n  ${m.repo.url}/blob/main/${m.example.path}`
      ).join('\n');

      return {
        content: [{ type: 'text' as const, text: `# Examples: ${type}\n\n${results}` }],
      };
    }
  );

  server.tool(
    'example_get_by_difficulty',
    'Get examples filtered by difficulty level',
    {
      difficulty: z.enum(['beginner', 'intermediate', 'advanced', 'expert']).describe('Difficulty level'),
    },
    async ({ difficulty }) => {
      const matches = getExamplesByDifficulty(difficulty);
      if (matches.length === 0) {
        return { content: [{ type: 'text' as const, text: `No examples at difficulty: ${difficulty}` }] };
      }

      const results = matches.map(m =>
        `- **${m.example.path}** (${m.repo.name}) — ${m.example.description}`
      ).join('\n');

      return {
        content: [{ type: 'text' as const, text: `# ${difficulty.charAt(0).toUpperCase() + difficulty.slice(1)} Examples\n\n${results}` }],
      };
    }
  );
}
