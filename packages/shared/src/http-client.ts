import { AppError } from './errors.js';
import { logger } from './logger.js';

interface HttpClientOptions {
  baseUrl: string;
  timeout?: number;
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  headers?: Record<string, string>;
  body?: unknown;
  timeout?: number;
}

export class HttpClient {
  private baseUrl: string;
  private timeout: number;

  constructor(options: HttpClientOptions) {
    this.baseUrl = options.baseUrl;
    this.timeout = options.timeout ?? 10000;
  }

  private async request<T>(path: string, options: RequestOptions = {}): Promise<T> {
    const { method = 'GET', headers = {}, body } = options;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    try {
      const response = await fetch(`${this.baseUrl}${path}`, {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
        body: body ? JSON.stringify(body) : undefined,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      const data = await response.json();

      if (!response.ok) {
        logger.error(`HTTP ${response.status}`, undefined, {
          path,
          method,
          status: response.status,
        });
        throw new AppError(
          data.message || 'Request failed',
          response.status,
          data.code
        );
      }

      return data;
    } catch (error) {
      clearTimeout(timeoutId);
      if (error instanceof AppError) throw error;
      logger.error('Request failed', error as Error, { path, method });
      throw new AppError('Request failed', 500);
    }
  }

  async get<T>(path: string, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(path, { method: 'GET', headers });
  }

  async post<T>(path: string, body?: unknown, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(path, { method: 'POST', body, headers });
  }

  async put<T>(path: string, body?: unknown, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(path, { method: 'PUT', body, headers });
  }

  async patch<T>(path: string, body?: unknown, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(path, { method: 'PATCH', body, headers });
  }

  async delete<T>(path: string, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(path, { method: 'DELETE', headers });
  }
}

export function createHttpClient(baseUrl: string, timeout?: number): HttpClient {
  return new HttpClient({ baseUrl, timeout });
}

export function getAuthHeader(request: { headers: Record<string, string | string[] | undefined> }): Record<string, string> {
  const authorization = request.headers.authorization;
  if (Array.isArray(authorization)) {
    return { Authorization: authorization[0] };
  }
  if (authorization) {
    return { Authorization: authorization };
  }
  return {};
}