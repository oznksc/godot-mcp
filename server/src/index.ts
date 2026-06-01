#!/usr/bin/env node

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { GodotBridge } from './utils/godot-bridge.js';
import { logger, setLogLevel, LogLevel } from './utils/logger.js';
import { registerAllTools } from './tools/index.js';
import { registerResources } from './resources/index.js';
import { registerPrompts } from './prompts/index.js';

const SCOPE = 'main';

async function main(): Promise<void> {
  const logLevel = process.env.LOG_LEVEL === 'debug' ? LogLevel.DEBUG
    : process.env.LOG_LEVEL === 'warn' ? LogLevel.WARN
    : process.env.LOG_LEVEL === 'error' ? LogLevel.ERROR
    : LogLevel.INFO;
  setLogLevel(logLevel);

  const wsPort = parseInt(process.env.GODOT_WS_PORT || '6505', 10);
  const wsHost = process.env.GODOT_WS_HOST || '127.0.0.1';

  logger.info(SCOPE, 'Starting Godot MCP Server');

  const bridge = new GodotBridge({ host: wsHost, port: wsPort });

  const server = new McpServer({
    name: 'godot-mcp',
    version: '1.0.0',
  });

  registerAllTools(server, bridge);
  registerResources(server, bridge);
  registerPrompts(server);

  bridge.on('connected', () => {
    logger.info(SCOPE, 'Bridge connected to Godot editor');
  });

  bridge.on('disconnected', () => {
    logger.warn(SCOPE, 'Bridge disconnected from Godot editor');
  });

  bridge.on('reconnect_failed', () => {
    logger.error(SCOPE, 'Failed to reconnect to Godot editor after max attempts');
  });

  bridge.on('error', (err: Error) => {
    logger.error(SCOPE, 'Bridge error', { error: err.message });
  });

  // Connect to Godot (non-blocking — server can start without Godot)
  bridge.connect().catch((err: Error) => {
    logger.warn(SCOPE, `Could not connect to Godot at startup: ${err.message}`);
    logger.info(SCOPE, 'Server will wait for Godot to connect');
  });

  // Start MCP server over stdio
  const transport = new StdioServerTransport();
  await server.connect(transport);

  logger.info(SCOPE, 'MCP Server started on stdio');

  // Graceful shutdown
  process.on('SIGINT', async () => {
    logger.info(SCOPE, 'Shutting down...');
    await bridge.disconnect();
    await server.close();
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    logger.info(SCOPE, 'Received SIGTERM, shutting down...');
    await bridge.disconnect();
    await server.close();
    process.exit(0);
  });
}

main().catch((err) => {
  logger.error(SCOPE, 'Fatal error', { error: String(err) });
  process.exit(1);
});
