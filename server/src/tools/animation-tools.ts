import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerAnimationTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'animation_create',
    'Create a new animation on an AnimationPlayer node',
    {
      node_path: z.string().describe('AnimationPlayer node path'),
      anim_name: z.string().describe('Animation name'),
      duration: z.number().default(1.0).describe('Animation duration in seconds'),
    },
    async ({ node_path, anim_name, duration }) => {
      const result = await bridge.sendCommand('animation_create', { node_path, anim_name, duration });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'animation_list_keys',
    'List all keyframes in an animation',
    {
      node_path: z.string().describe('AnimationPlayer node path'),
      anim_name: z.string().describe('Animation name'),
    },
    async ({ node_path, anim_name }) => {
      const result = await bridge.sendCommand('animation_list_keys', { node_path, anim_name });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'animation_add_keyframe',
    'Add a keyframe to an animation track',
    {
      node_path: z.string().describe('AnimationPlayer node path'),
      anim_name: z.string().describe('Animation name'),
      track_type: z.string().describe('Track type (position, rotation, scale, property, method, etc.)'),
      target_path: z.string().describe('Target node path for this track'),
      time: z.number().describe('Keyframe time in seconds'),
      value: z.any().describe('Keyframe value'),
      transition: z.number().default(1.0).describe('Transition type'),
    },
    async ({ node_path, anim_name, track_type, target_path, time, value, transition }) => {
      const result = await bridge.sendCommand('animation_add_keyframe', {
        node_path, anim_name, track_type, target_path, time, value, transition,
      });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'animation_remove_keyframe',
    'Remove a keyframe from an animation track',
    {
      node_path: z.string().describe('AnimationPlayer node path'),
      anim_name: z.string().describe('Animation name'),
      track_index: z.number().describe('Track index'),
      time: z.number().describe('Keyframe time to remove'),
    },
    async ({ node_path, anim_name, track_index, time }) => {
      const result = await bridge.sendCommand('animation_remove_keyframe', { node_path, anim_name, track_index, time });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'animation_set_length',
    'Set the duration of an animation',
    {
      node_path: z.string().describe('AnimationPlayer node path'),
      anim_name: z.string().describe('Animation name'),
      duration: z.number().describe('New duration in seconds'),
    },
    async ({ node_path, anim_name, duration }) => {
      const result = await bridge.sendCommand('animation_set_length', { node_path, anim_name, duration });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'animation_get_library',
    'Get animation library information from an AnimationPlayer',
    {
      node_path: z.string().describe('AnimationPlayer node path'),
    },
    async ({ node_path }) => {
      const result = await bridge.sendCommand('animation_get_library', { node_path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
