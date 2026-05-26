export const logger = {
  info: (message: string, data?: Record<string, unknown>) => console.log(JSON.stringify({ timestamp: new Date().toISOString(), level: 'INFO', message, ...data })),
  error: (message: string, error?: Error, data?: Record<string, unknown>) => console.error(JSON.stringify({ timestamp: new Date().toISOString(), level: 'ERROR', message, error: error?.message, ...data })),
  warn: (message: string, data?: Record<string, unknown>) => console.warn(JSON.stringify({ timestamp: new Date().toISOString(), level: 'WARN', message, ...data })),
};
