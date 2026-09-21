import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';
import type { ViewportCaptureResult } from '../types.js';

export function registerViewportTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'viewport_capture_editor',
    'Capture a screenshot of the Godot editor viewport (2D canvas or 3D scene) for visual inspection and layout analysis',
    {
      view: z.enum(['2d', '3d', 'main', 'active']).default('main').describe('Target viewport to capture'),
      max_width: z.number().default(1280).describe('Maximum image width (auto-scaled)'),
      max_height: z.number().default(720).describe('Maximum image height (auto-scaled)'),
    },
    async ({ view, max_width, max_height }) => {
      const result = (await bridge.sendCommand('viewport_capture_editor', {
        view,
        max_width,
        max_height,
      })) as ViewportCaptureResult;

      if (result && result.base64) {
        return {
          content: [
            {
              type: 'image' as const,
              data: result.base64,
              mimeType: 'image/png',
            },
            {
              type: 'text' as const,
              text: JSON.stringify(
                {
                  view: result.view,
                  width: result.width,
                  height: result.height,
                  original_width: result.original_width,
                  original_height: result.original_height,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'viewport_capture_game',
    'Capture a live frame from the currently running game window',
    {
      max_width: z.number().default(1280).describe('Maximum image width'),
      max_height: z.number().default(720).describe('Maximum image height'),
    },
    async ({ max_width, max_height }) => {
      const result = (await bridge.sendCommand('viewport_capture_game', {
        max_width,
        max_height,
      })) as ViewportCaptureResult;

      if (result && result.base64) {
        return {
          content: [
            {
              type: 'image' as const,
              data: result.base64,
              mimeType: 'image/png',
            },
            {
              type: 'text' as const,
              text: JSON.stringify(
                {
                  view: result.view,
                  width: result.width,
                  height: result.height,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'viewport_set_debug_draw',
    'Set visual debug drawing modes (wireframe, overdraw, collision shapes, navigation polygons)',
    {
      mode: z
        .enum(['normal', 'wireframe', 'overdraw', 'unshaded', 'lighting', 'collision', 'navigation'])
        .default('normal')
        .describe('Debug draw mode to activate'),
    },
    async ({ mode }) => {
      const result = await bridge.sendCommand('viewport_set_debug_draw', { mode });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
