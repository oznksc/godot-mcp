import WebSocket from 'ws';
import { EventEmitter } from 'events';
import { logger } from './logger.js';
import type { GodotCommand, GodotResponse, WebSocketConfig } from '../types.js';

const DEFAULT_CONFIG: WebSocketConfig = {
  host: '127.0.0.1',
  port: 6505,
  reconnectAttempts: 5,
  reconnectDelay: 2000,
  pingInterval: 30000,
};

export class GodotBridge extends EventEmitter {
  private ws: WebSocket | null = null;
  private config: WebSocketConfig;
  private pendingRequests = new Map<string, {
    resolve: (value: unknown) => void;
    reject: (reason: Error) => void;
    timer: ReturnType<typeof setTimeout>;
  }>();
  private reconnectCount = 0;
  private pingTimer: ReturnType<typeof setInterval> | null = null;
  private _connected = false;

  constructor(config: Partial<WebSocketConfig> = {}) {
    super();
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  get connected(): boolean {
    return this._connected;
  }

  async connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      const url = `ws://${this.config.host}:${this.config.port}`;
      logger.info('bridge', `Connecting to Godot at ${url}`);

      this.ws = new WebSocket(url);

      this.ws.on('open', () => {
        this._connected = true;
        this.reconnectCount = 0;
        logger.info('bridge', 'Connected to Godot');
        this.startPing();
        this.emit('connected');
        resolve();
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
        this._connected = false;
        this.stopPing();
        logger.warn('bridge', `Connection closed: ${code} ${reason.toString()}`);
        this.emit('disconnected');
        this.rejectAllPending(new Error('Connection closed'));
        this.tryReconnect();
      });

      this.ws.on('error', (err: Error) => {
        logger.error('bridge', 'WebSocket error', { error: err.message });
        if (!this._connected) {
          reject(err);
        }
        this.emit('error', err);
      });

      this.ws.on('pong', () => {
        logger.debug('bridge', 'Received pong');
      });
    });
  }

  async disconnect(): Promise<void> {
    this.reconnectCount = this.config.reconnectAttempts;
    this.stopPing();
    this.rejectAllPending(new Error('Disconnected'));
    if (this.ws) {
      this.ws.close(1000, 'Client disconnect');
      this.ws = null;
    }
    this._connected = false;
  }

  async sendCommand(method: string, params: Record<string, unknown> = {}): Promise<unknown> {
    if (!this._connected || !this.ws) {
      throw new Error('Not connected to Godot');
    }

    const id = crypto.randomUUID();
    const command: GodotCommand = { id, method, params };

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pendingRequests.delete(id);
        reject(new Error(`Command timed out: ${method}`));
      }, 30000);

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
      if (this.ws && this._connected) {
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
    logger.info('bridge', `Reconnecting in ${this.config.reconnectDelay}ms (attempt ${this.reconnectCount}/${this.config.reconnectAttempts})`);

    setTimeout(() => {
      this.connect().catch(() => {
        // Error handled in connect()
      });
    }, this.config.reconnectDelay);
  }
}
