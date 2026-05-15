type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogContext {
  service?: string;
  [key: string]: unknown;
}

class Logger {
  private service: string;

  constructor(service: string = 'app') {
    this.service = service;
  }

  private format(level: LogLevel, message: string, context?: LogContext): string {
    const timestamp = new Date().toISOString();
    const log = {
      timestamp,
      level: level.toUpperCase(),
      service: this.service,
      message,
      ...context,
    };
    return JSON.stringify(log);
  }

  debug(message: string, context?: LogContext): void {
    if (process.env.LOG_LEVEL === 'debug') {
      console.log(this.format('debug', message, context));
    }
  }

  info(message: string, context?: LogContext): void {
    console.log(this.format('info', message, context));
  }

  warn(message: string, context?: LogContext): void {
    console.warn(this.format('warn', message, context));
  }

  error(message: string, error?: Error, context?: LogContext): void {
    const errorContext = error
      ? { ...context, error: { message: error.message, stack: error.stack } }
      : context;
    console.error(this.format('error', message, errorContext));
  }
}

export function createLogger(service: string): Logger {
  return new Logger(service);
}

export const logger = createLogger('app');