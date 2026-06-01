import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerParticlesTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'particles_create',
    'Create a GPU particles node',
    {
      type: z.enum(['GPUParticles2D', 'GPUParticles3D', 'CPUParticles2D', 'CPUParticles3D']).describe('Particle node type'),
      name: z.string().describe('Node name'),
      parent: z.string().optional().describe('Parent node path'),
    },
    async ({ type, name, parent }) => {
      const result = await bridge.sendCommand('particles_create', { type, name, parent });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'particles_set_material',
    'Set the particle process material',
    {
      path: z.string().describe('Particles node path'),
      material_path: z.string().describe('ParticleProcessMaterial path (res://...)'),
    },
    async ({ path, material_path }) => {
      const result = await bridge.sendCommand('particles_set_material', { path, material_path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'particles_configure',
    'Configure particle properties',
    {
      path: z.string().describe('Particles node path'),
      amount: z.number().optional().describe('Number of particles'),
      lifetime: z.number().optional().describe('Particle lifetime in seconds'),
      one_shot: z.boolean().optional().describe('Emit once then stop'),
      emitting: z.boolean().optional().describe('Start/stop emitting'),
      explosiveness: z.number().optional().describe('Explosiveness ratio (0-1)'),
      randomness: z.number().optional().describe('Randomness ratio (0-1)'),
      fixed_fps: z.number().optional().describe('Fixed FPS (0 for no cap)'),
    },
    async ({ path, amount, lifetime, one_shot, emitting, explosiveness, randomness, fixed_fps }) => {
      const result = await bridge.sendCommand('particles_configure', {
        path, amount, lifetime, one_shot, emitting, explosiveness, randomness, fixed_fps,
      });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
