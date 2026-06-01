export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

const LEVEL_LABELS: Record<LogLevel, string> = {
  [LogLevel.DEBUG]: 'DEBUG',
  [LogLevel.INFO]: 'INFO',
  [LogLevel.WARN]: 'WARN',
  [LogLevel.ERROR]: 'ERROR',
};

let currentLevel: LogLevel = LogLevel.INFO;

export function setLogLevel(level: LogLevel): void {
  currentLevel = level;
}

function log(level: LogLevel, scope: string, message: string, data?: unknown): void {
  if (level < currentLevel) return;
  const timestamp = new Date().toISOString();
  const label = LEVEL_LABELS[level];
  const prefix = `[${timestamp}] [${label}] [${scope}]`;
  const suffix = data !== undefined ? ` ${JSON.stringify(data)}` : '';
  process.stderr.write(`${prefix} ${message}${suffix}\n`);
}

export const logger = {
  debug: (scope: string, message: string, data?: unknown) => log(LogLevel.DEBUG, scope, message, data),
  info: (scope: string, message: string, data?: unknown) => log(LogLevel.INFO, scope, message, data),
  warn: (scope: string, message: string, data?: unknown) => log(LogLevel.WARN, scope, message, data),
  error: (scope: string, message: string, data?: unknown) => log(LogLevel.ERROR, scope, message, data),
};
