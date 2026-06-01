import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerLightingTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'lighting_create',
    'Create a light node (2D or 3D)',
    {
      type: z.enum(['DirectionalLight2D', 'PointLight2D', 'DirectionalLight3D', 'OmniLight3D', 'SpotLight3D']).describe('Light type'),
      name: z.string().describe('Node name'),
      parent: z.string().optional().describe('Parent node path'),
      color: z.string().optional().describe('Light color (hex, e.g., #ffffff)'),
      energy: z.number().optional().describe('Light energy/intensity'),
    },
    async ({ type, name, parent, color, energy }) => {
      const result = await bridge.sendCommand('lighting_create', { type, name, parent, color, energy });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'lighting_set_properties',
    'Set properties on a light node',
    {
      path: z.string().describe('Light node path'),
      color: z.string().optional().describe('Light color (hex)'),
      energy: z.number().optional().describe('Energy/intensity'),
      shadow_enabled: z.boolean().optional().describe('Enable shadows'),
      shadow_opacity: z.number().optional().describe('Shadow opacity (0-1)'),
      indirect_energy: z.number().optional().describe('Indirect energy'),
      volumetric_fog_energy: z.number().optional().describe('Volumetric fog energy'),
    },
    async ({ path, color, energy, shadow_enabled, shadow_opacity, indirect_energy, volumetric_fog_energy }) => {
      const result = await bridge.sendCommand('lighting_set_properties', {
        path, color, energy, shadow_enabled, shadow_opacity, indirect_energy, volumetric_fog_energy,
      });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'lighting_create_environment',
    'Create an Environment resource',
    {
      path: z.string().optional().describe('Save path (res://...)'),
      properties: z.record(z.any()).optional().describe('Environment properties'),
    },
    async ({ path, properties }) => {
      const result = await bridge.sendCommand('lighting_create_environment', { path, properties });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'lighting_configure_world',
    'Configure WorldEnvironment on a node',
    {
      node_path: z.string().describe('WorldEnvironment node path'),
      environment_path: z.string().describe('Environment resource path (res://...)'),
    },
    async ({ node_path, environment_path }) => {
      const result = await bridge.sendCommand('lighting_configure_world', { node_path, environment_path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
