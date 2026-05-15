import axios from 'axios';

const API_URL = 'http://10.0.2.2:3000';

export const api = axios.create({ baseURL: API_URL });

api.interceptors.request.use((config) => {
  const authHeader = config.headers.Authorization;
  const token = typeof authHeader === 'string' ? authHeader.replace('Bearer ', '') : undefined;
  if (!token && config.url !== '/auth/login' && config.url !== '/auth/register') {
    return config;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      console.log('Unauthorized');
    }
    return Promise.reject(error);
  }
);