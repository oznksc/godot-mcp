import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { findRelevantSkills, getSkillContent, getMatchedSkillsContext, listAvailableSkills } from './skill-router.js';

export function registerSkillTools(server: McpServer): void {
  server.tool(
    'skill_query',
    'Query Godot knowledge skills — finds relevant skill modules based on a natural language question about Godot development',
    {
      query: z.string().describe('Natural language question or topic about Godot development'),
      max_skills: z.number().default(3).describe('Maximum number of skills to return'),
    },
    async ({ query, max_skills }) => {
      const context = getMatchedSkillsContext(query);
      if (!context) {
        return {
          content: [{ type: 'text' as const, text: `No relevant skills found for: "${query}"\n\nAvailable skills: ${listAvailableSkills().map(s => s.name).join(', ')}` }],
        };
      }
      return { content: [{ type: 'text' as const, text: context }] };
    }
  );

  server.tool(
    'skill_get',
    'Get a specific Godot skill module by ID',
    {
      skill_id: z.enum([
        'gdscript', 'scene-architecture', 'signal-patterns', 'performance',
        '2d-patterns', '3d-patterns', 'ui-design', 'physics',
        'animation', 'audio', 'networking', 'export',
      ]).describe('Skill module ID'),
    },
    async ({ skill_id }) => {
      const content = getSkillContent(skill_id);
      if (!content) {
        return { content: [{ type: 'text' as const, text: `Skill not found: ${skill_id}` }] };
      }
      return { content: [{ type: 'text' as const, text: content }] };
    }
  );

  server.tool(
    'skill_list',
    'List all available Godot skill modules',
    {},
    async () => {
      const skills = listAvailableSkills();
      const list = skills.map(s =>
        `- **${s.id}** — ${s.name}: ${s.description}`
      ).join('\n');
      return { content: [{ type: 'text' as const, text: `# Available Godot Skills\n\n${list}` }] };
    }
  );
}
