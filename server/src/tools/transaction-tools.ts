import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerTransactionTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'transaction_begin',
    'Begin an atomic multi-step operation in Godot with rollback capability and UndoRedo integration',
    {
      name: z.string().default('MCP Operation').describe('Human-readable description of this atomic transaction'),
      dry_run: z.boolean().default(false).describe('If true, records actions without committing permanent changes'),
    },
    async ({ name, dry_run }) => {
      const result = await bridge.sendCommand('transaction_begin', { name, dry_run });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'transaction_commit',
    'Commit the active transaction and finalize all file/node changes into an UndoRedo action',
    {
      transaction_id: z.string().optional().describe('ID of the transaction to commit (optional if single active transaction)'),
    },
    async ({ transaction_id }) => {
      const result = await bridge.sendCommand('transaction_commit', { transaction_id });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'transaction_rollback',
    'Rollback the active transaction: reverts all file changes, deletes newly created files, and discards uncommitted node actions',
    {
      transaction_id: z.string().optional().describe('ID of the transaction to rollback (optional if single active transaction)'),
    },
    async ({ transaction_id }) => {
      const result = await bridge.sendCommand('transaction_rollback', { transaction_id });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'transaction_status',
    'Check if a transaction is currently active and view recorded actions',
    {},
    async () => {
      const result = await bridge.sendCommand('transaction_get_status');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
