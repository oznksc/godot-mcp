export declare enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3
}
export declare function setLogLevel(level: LogLevel): void;
export declare const logger: {
    debug: (scope: string, message: string, data?: unknown) => void;
    info: (scope: string, message: string, data?: unknown) => void;
    warn: (scope: string, message: string, data?: unknown) => void;
    error: (scope: string, message: string, data?: unknown) => void;
};
//# sourceMappingURL=logger.d.ts.map