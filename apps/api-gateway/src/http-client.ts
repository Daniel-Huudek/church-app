import { createHttpClient } from './shared/index.js';

const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://auth-service:3001';
const MEMBER_SERVICE_URL = process.env.MEMBER_SERVICE_URL || 'http://member-service:3006';
const SCHEDULE_SERVICE_URL = process.env.SCHEDULE_SERVICE_URL || 'http://schedule-service:3003';
const EVENT_SERVICE_URL = process.env.EVENT_SERVICE_URL || 'http://event-service:3004';
const NOTIFICATION_SERVICE_URL = process.env.NOTIFICATION_SERVICE_URL || 'http://notification-service:3005';
const PRAYER_SERVICE_URL = process.env.PRAYER_SERVICE_URL || 'http://prayer-service:3007';
const FINANCIAL_SERVICE_URL = process.env.FINANCIAL_SERVICE_URL || 'http://financial-service:3008';

export const authClient = createHttpClient(AUTH_SERVICE_URL);
export const memberClient = createHttpClient(MEMBER_SERVICE_URL);
export const scheduleClient = createHttpClient(SCHEDULE_SERVICE_URL);
export const eventClient = createHttpClient(EVENT_SERVICE_URL);
export const notificationClient = createHttpClient(NOTIFICATION_SERVICE_URL);
export const prayerClient = createHttpClient(PRAYER_SERVICE_URL);
export const financialClient = createHttpClient(FINANCIAL_SERVICE_URL);

export function getServiceClient(service: string) {
  switch (service) {
    case 'auth': return authClient;
    case 'member': return memberClient;
    case 'schedule': return scheduleClient;
    case 'event': return eventClient;
    case 'notification': return notificationClient;
    case 'prayer': return prayerClient;
    case 'financial': return financialClient;
    default: throw new Error(`Unknown service: ${service}`);
  }
}
