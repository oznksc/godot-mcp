export var LogLevel;
(function (LogLevel) {
    LogLevel[LogLevel["DEBUG"] = 0] = "DEBUG";
    LogLevel[LogLevel["INFO"] = 1] = "INFO";
    LogLevel[LogLevel["WARN"] = 2] = "WARN";
    LogLevel[LogLevel["ERROR"] = 3] = "ERROR";
})(LogLevel || (LogLevel = {}));
const LEVEL_LABELS = {
    [LogLevel.DEBUG]: 'DEBUG',
    [LogLevel.INFO]: 'INFO',
    [LogLevel.WARN]: 'WARN',
    [LogLevel.ERROR]: 'ERROR',
};
let currentLevel = LogLevel.INFO;
export function setLogLevel(level) {
    currentLevel = level;
}
function log(level, scope, message, data) {
    if (level < currentLevel)
        return;
    const timestamp = new Date().toISOString();
    const label = LEVEL_LABELS[level];
    const prefix = `[${timestamp}] [${label}] [${scope}]`;
    const suffix = data !== undefined ? ` ${JSON.stringify(data)}` : '';
    process.stderr.write(`${prefix} ${message}${suffix}\n`);
}
export const logger = {
    debug: (scope, message, data) => log(LogLevel.DEBUG, scope, message, data),
    info: (scope, message, data) => log(LogLevel.INFO, scope, message, data),
    warn: (scope, message, data) => log(LogLevel.WARN, scope, message, data),
    error: (scope, message, data) => log(LogLevel.ERROR, scope, message, data),
};
//# sourceMappingURL=logger.js.map