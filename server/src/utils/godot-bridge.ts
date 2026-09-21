import WebSocket from 'ws';
import { EventEmitter } from 'events';
import * as fs from 'fs';
import * as path from 'path';
import { logger } from './logger.js';
import type {
  GodotCommand,
  GodotResponse,
  WebSocketConfig,
  HandshakeInfo,
  GodotConnectionState,
} from '../types.js';

const DEFAULT_CONFIG: WebSocketConfig = {
  host: '127.0.0.1',
  port: 6505,
  reconnectAttempts: 5,
  reconnectDelay: 2000,
  pingInterval: 30000,
  commandTimeout: 30000,
};

export class GodotBridge extends EventEmitter {
  private ws: WebSocket | null = null;
  private config: WebSocketConfig;
  private pendingRequests = new Map<
    string,
    {
      resolve: (value: unknown) => void;
      reject: (reason: Error) => void;
      timer: ReturnType<typeof setTimeout>;
    }
  >();
  private reconnectCount = 0;
  private pingTimer: ReturnType<typeof setInterval> | null = null;
  private state: GodotConnectionState = 'disconnected';
  private handshakeInfo: HandshakeInfo | null = null;
  private sessionToken = '';
  private handshakePromise: Promise<void> | null = null;

  constructor(config: Partial<WebSocketConfig> = {}) {
    super();
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.loadSessionToken();
  }

  get connected(): boolean {
    return this.state === 'connected';
  }

  get connectionState(): GodotConnectionState {
    return this.state;
  }

  getHandshakeInfo(): HandshakeInfo | null {
    return this.handshakeInfo;
  }

  hasCapability(capability: string): boolean {
    return this.handshakeInfo?.capabilities?.includes(capability) ?? false;
  }

  getEngineVersion(): string {
    return this.handshakeInfo?.engine?.string ?? 'Unknown';
  }

  getStatus(): Record<string, unknown> {
    if (!this.connected && this.state === 'disconnected') {
      this.reconnectCount = 0;
      this.connect().catch(() => {});
    }
    return {
      connected: this.connected,
      state: this.state,
      host: this.config.host,
      port: this.config.port,
      protocol_version: this.handshakeInfo?.protocol_version ?? 'unknown',
      engine: this.handshakeInfo?.engine ?? null,
      capabilities: this.handshakeInfo?.capabilities ?? [],
      project_name: this.handshakeInfo?.project_name ?? null,
      reconnect_attempts: this.config.reconnectAttempts,
      reconnect_count: this.reconnectCount,
      reconnect_delay_ms: this.config.reconnectDelay,
      ping_interval_ms: this.config.pingInterval,
      command_timeout_ms: this.config.commandTimeout,
      pending_requests: this.pendingRequests.size,
    };
  }

  private loadSessionToken(): void {
    if (this.config.sessionToken) {
      this.sessionToken = this.config.sessionToken;
      return;
    }
    const searchDirs = [
      process.env.GODOT_PROJECT_PATH,
      process.cwd(),
      '/Volumes/Depo/Projects/tidesofwar',
      '/Volumes/Depo/Projects/godot-mcp',
    ].filter(Boolean) as string[];

    for (const dir of searchDirs) {
      const keyPath = path.resolve(dir, '.godot/mcp_session.key');
      if (fs.existsSync(keyPath)) {
        try {
          this.sessionToken = fs.readFileSync(keyPath, 'utf8').trim();
          logger.debug('bridge', `Loaded session key from ${keyPath}`);
          return;
        } catch (err) {
          logger.warn('bridge', `Failed to read session key from ${keyPath}`, { error: String(err) });
        }
      }
    }
  }

  async connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      const url = `ws://${this.config.host}:${this.config.port}`;
      this.state = 'connecting';
      logger.info('bridge', `Connecting to Godot at ${url}`);

      this.ws = new WebSocket(url);

      this.ws.on('open', async () => {
        this.reconnectCount = 0;
        this.state = 'handshaking';
        logger.info('bridge', 'Socket open, negotiating Godot MCP v2 handshake...');
        this.startPing();

        this.handshakePromise = this.performHandshake();
        try {
          await this.handshakePromise;
          this.state = 'connected';
          logger.info('bridge', `Connected and ready. Godot: ${this.getEngineVersion()}`);
          this.emit('connected', this.handshakeInfo);
          resolve();
        } catch (err) {
          logger.warn('bridge', `Handshake warning (continuing with v1 compatibility): ${String(err)}`);
          this.state = 'connected';
          this.emit('connected');
          resolve();
        } finally {
          this.handshakePromise = null;
        }
      });

      this.ws.on('message', (data: WebSocket.Data) => {
        try {
          const response = JSON.parse(data.toString()) as GodotResponse;
          this.handleResponse(response);
        } catch (err) {
          logger.error('bridge', 'Failed to parse message', { error: String(err) });
        }
      });

      this.ws.on('close', (code: number, reason: Buffer) => {
        this.state = 'disconnected';
        this.stopPing();
        this.handshakeInfo = null;
        logger.warn('bridge', `Connection closed: ${code} ${reason.toString()}`);
        this.emit('disconnected');
        this.rejectAllPending(new Error('Connection closed'));
        this.tryReconnect();
      });

      this.ws.on('error', (err: Error) => {
        logger.error('bridge', 'WebSocket error', { error: err.message });
        if (this.state === 'connecting') {
          reject(err);
        }
        this.emit('error', err);
      });

      this.ws.on('pong', () => {
        logger.debug('bridge', 'Received pong');
      });
    });
  }

  private async performHandshake(): Promise<void> {
    this.loadSessionToken();
    const result = (await this.rawSendCommand('system_handshake', {
      protocol_version: '2.0.0',
      session_token: this.sessionToken,
    })) as HandshakeInfo;

    this.handshakeInfo = result;
    if (result.session_token && !this.sessionToken) {
      this.sessionToken = result.session_token;
    }
  }

  async disconnect(): Promise<void> {
    this.reconnectCount = this.config.reconnectAttempts;
    this.stopPing();
    this.rejectAllPending(new Error('Disconnected'));
    if (this.ws) {
      this.ws.close(1000, 'Client disconnect');
      this.ws = null;
    }
    this.state = 'disconnected';
  }

  async sendCommand(method: string, params: Record<string, unknown> = {}): Promise<unknown> {
    if (!this.connected || !this.ws) {
      if (this.state === 'disconnected') {
        this.reconnectCount = 0;
        try {
          await this.connect();
        } catch {
          // Error handled in connection state check
        }
      }
    }
    if (method !== 'system_handshake') {
      if (this.state === 'connecting' || this.state === 'handshaking') {
        try {
          await this.waitForReady(5000);
        } catch {
          // If timed out waiting, check condition below
        }
      }
    }
    if (!this.connected || !this.ws) {
      throw new Error('Not connected to Godot');
    }
    return this.rawSendCommand(method, params);
  }

  private async waitForReady(timeoutMs: number): Promise<void> {
    if (this.connected) return;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        cleanup();
        reject(new Error(`Timed out waiting for Godot connection (${timeoutMs}ms)`));
      }, timeoutMs);

      const onConnected = () => {
        cleanup();
        resolve();
      };
      const onError = (err: Error) => {
        cleanup();
        reject(err);
      };

      const cleanup = () => {
        clearTimeout(timer);
        this.off('connected', onConnected);
        this.off('error', onError);
        this.off('disconnected', onError);
      };

      this.once('connected', onConnected);
      this.once('error', onError);
      this.once('disconnected', onError);
    });
  }

  private async rawSendCommand(method: string, params: Record<string, unknown> = {}): Promise<unknown> {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      throw new Error('WebSocket is not open');
    }

    const id = crypto.randomUUID();
    const command: GodotCommand = {
      id,
      method,
      params,
      token: this.sessionToken,
    };

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pendingRequests.delete(id);
        reject(new Error(`Command timed out: ${method}`));
      }, this.config.commandTimeout);

      this.pendingRequests.set(id, { resolve, reject, timer });
      logger.debug('bridge', `Sending command: ${method}`, { id, params });
      this.ws!.send(JSON.stringify(command));
    });
  }

  private handleResponse(response: GodotResponse): void {
    const pending = this.pendingRequests.get(response.id);
    if (!pending) {
      logger.debug('bridge', 'Received response for unknown request', { id: response.id });
      return;
    }

    clearTimeout(pending.timer);
    this.pendingRequests.delete(response.id);

    if (response.error) {
      logger.error('bridge', `Command error: ${response.error.message}`, response.error);
      pending.reject(new Error(response.error.message));
    } else {
      logger.debug('bridge', `Command success: ${response.id}`);
      pending.resolve(response.result);
    }
  }

  private rejectAllPending(error: Error): void {
    for (const [id, pending] of this.pendingRequests) {
      clearTimeout(pending.timer);
      pending.reject(error);
    }
    this.pendingRequests.clear();
  }

  private startPing(): void {
    this.pingTimer = setInterval(() => {
      if (this.ws && (this.state === 'connected' || this.state === 'handshaking')) {
        this.ws.ping();
      }
    }, this.config.pingInterval);
  }

  private stopPing(): void {
    if (this.pingTimer) {
      clearInterval(this.pingTimer);
      this.pingTimer = null;
    }
  }

  private tryReconnect(): void {
    if (this.reconnectCount >= this.config.reconnectAttempts) {
      logger.error('bridge', 'Max reconnection attempts reached');
      this.emit('reconnect_failed');
      return;
    }

    this.reconnectCount++;
    logger.info(
      'bridge',
      `Reconnecting in ${this.config.reconnectDelay}ms (attempt ${this.reconnectCount}/${this.config.reconnectAttempts})`
    );

    setTimeout(() => {
      this.connect().catch(() => {
        // Error handled in connect()
      });
    }, this.config.reconnectDelay);
  }
}
