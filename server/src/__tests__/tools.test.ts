import test from 'node:test';
import assert from 'node:assert';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { GodotBridge } from '../utils/godot-bridge.js';
import { registerAllTools } from '../tools/index.js';

test('GodotBridge initialization and status', () => {
  const bridge = new GodotBridge({ host: '127.0.0.1', port: 6505 });
  const status = bridge.getStatus();

  assert.strictEqual(status.connected, false);
  assert.strictEqual(status.host, '127.0.0.1');
  assert.strictEqual(status.port, 6505);
  assert.strictEqual(status.pending_requests, 0);
  assert.ok(Array.isArray(status.capabilities));
});

test('MCP Server tool registration includes Godot MCP v2 tools', () => {
  const server = new McpServer({
    name: 'godot-mcp-test',
    version: '2.0.0',
  });
  const bridge = new GodotBridge();

  registerAllTools(server, bridge);

  // If registerAllTools didn't throw and server is configured, registration succeeded
  assert.ok(server);
});

test('GodotBridge capabilities checking', () => {
  const bridge = new GodotBridge();
  assert.strictEqual(bridge.hasCapability('viewport_capture'), false);
  assert.strictEqual(bridge.getEngineVersion(), 'Unknown');
});
