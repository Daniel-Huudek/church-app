import { createHttpClient } from './shared/index.js';

const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://auth-service:3001';
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://user-service:3002';
const SCHEDULE_SERVICE_URL = process.env.SCHEDULE_SERVICE_URL || 'http://schedule-service:3003';
const EVENT_SERVICE_URL = process.env.EVENT_SERVICE_URL || 'http://event-service:3004';
const NOTIFICATION_SERVICE_URL = process.env.NOTIFICATION_SERVICE_URL || 'http://notification-service:3005';

export const authClient = createHttpClient(AUTH_SERVICE_URL);
export const userClient = createHttpClient(USER_SERVICE_URL);
export const scheduleClient = createHttpClient(SCHEDULE_SERVICE_URL);
export const eventClient = createHttpClient(EVENT_SERVICE_URL);
export const notificationClient = createHttpClient(NOTIFICATION_SERVICE_URL);

export function getServiceClient(service: string) {
  switch (service) {
    case 'auth': return authClient;
    case 'user': return userClient;
    case 'schedule': return scheduleClient;
    case 'event': return eventClient;
    case 'notification': return notificationClient;
    default: throw new Error(`Unknown service: ${service}`);
  }
}