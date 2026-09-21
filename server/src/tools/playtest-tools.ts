import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerPlaytestTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'playtest_run_flow',
    'Execute an autonomous end-to-end playtest flow: runs the game/scene, executes scripted input steps, captures visual screenshots, asserts game state, and verifies error-free execution',
    {
      scene: z.string().optional().describe('Scene path to run (defaults to main scene)'),
      wait_initial_seconds: z.number().default(1.0).describe('Seconds to wait after launch before executing steps'),
      auto_stop: z.boolean().default(true).describe('Automatically stop the game when the flow finishes'),
      steps: z
        .array(
          z.object({
            type: z.enum(['wait', 'key', 'action', 'mouse', 'screenshot', 'assert_node']),
            seconds: z.number().optional().describe('Wait duration in seconds (for wait step)'),
            duration: z.number().optional().describe('Key/action hold duration in seconds'),
            key: z.string().optional().describe('Key name to press (for key step)'),
            action: z.string().optional().describe('Action name to trigger (for action step)'),
            strength: z.number().optional().describe('Action strength (for action step)'),
            position: z.tuple([z.number(), z.number()]).optional().describe('Coordinates for mouse step'),
            tag: z.string().optional().describe('Tag/label for screenshot capture step'),
            node_path: z.string().optional().describe('Node path for property assertion'),
            property: z.string().optional().describe('Property name to assert'),
            expected: z.any().optional().describe('Expected exact property value'),
            min: z.number().optional().describe('Minimum acceptable numeric value'),
            max: z.number().optional().describe('Maximum acceptable numeric value'),
          })
        )
        .describe('Sequence of playtest steps to execute sequentially'),
    },
    async ({ scene, wait_initial_seconds, auto_stop, steps }) => {
      const result = await bridge.sendCommand('playtest_run_flow', {
        scene,
        wait_initial_seconds,
        auto_stop,
        steps,
      });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
