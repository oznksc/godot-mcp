import WebSocket from 'ws';
import { EventEmitter } from 'events';
import { logger } from './logger.js';
const DEFAULT_CONFIG = {
    host: '127.0.0.1',
    port: 6505,
    reconnectAttempts: 5,
    reconnectDelay: 2000,
    pingInterval: 30000,
};
export class GodotBridge extends EventEmitter {
    ws = null;
    config;
    pendingRequests = new Map();
    reconnectCount = 0;
    pingTimer = null;
    _connected = false;
    constructor(config = {}) {
        super();
        this.config = { ...DEFAULT_CONFIG, ...config };
    }
    get connected() {
        return this._connected;
    }
    async connect() {
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
            this.ws.on('message', (data) => {
                try {
                    const response = JSON.parse(data.toString());
                    this.handleResponse(response);
                }
                catch (err) {
                    logger.error('bridge', 'Failed to parse message', { error: String(err) });
                }
            });
            this.ws.on('close', (code, reason) => {
                this._connected = false;
                this.stopPing();
                logger.warn('bridge', `Connection closed: ${code} ${reason.toString()}`);
                this.emit('disconnected');
                this.rejectAllPending(new Error('Connection closed'));
                this.tryReconnect();
            });
            this.ws.on('error', (err) => {
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
    async disconnect() {
        this.reconnectCount = this.config.reconnectAttempts;
        this.stopPing();
        this.rejectAllPending(new Error('Disconnected'));
        if (this.ws) {
            this.ws.close(1000, 'Client disconnect');
            this.ws = null;
        }
        this._connected = false;
    }
    async sendCommand(method, params = {}) {
        if (!this._connected || !this.ws) {
            throw new Error('Not connected to Godot');
        }
        const id = crypto.randomUUID();
        const command = { id, method, params };
        return new Promise((resolve, reject) => {
            const timer = setTimeout(() => {
                this.pendingRequests.delete(id);
                reject(new Error(`Command timed out: ${method}`));
            }, 30000);
            this.pendingRequests.set(id, { resolve, reject, timer });
            logger.debug('bridge', `Sending command: ${method}`, { id, params });
            this.ws.send(JSON.stringify(command));
        });
    }
    handleResponse(response) {
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
        }
        else {
            logger.debug('bridge', `Command success: ${response.id}`);
            pending.resolve(response.result);
        }
    }
    rejectAllPending(error) {
        for (const [id, pending] of this.pendingRequests) {
            clearTimeout(pending.timer);
            pending.reject(error);
        }
        this.pendingRequests.clear();
    }
    startPing() {
        this.pingTimer = setInterval(() => {
            if (this.ws && this._connected) {
                this.ws.ping();
            }
        }, this.config.pingInterval);
    }
    stopPing() {
        if (this.pingTimer) {
            clearInterval(this.pingTimer);
            this.pingTimer = null;
        }
    }
    tryReconnect() {
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
//# sourceMappingURL=godot-bridge.js.map