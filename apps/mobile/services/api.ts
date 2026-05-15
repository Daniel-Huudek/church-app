import axios from 'axios';

const getApiUrl = () => {
  if (typeof window !== 'undefined') {
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
      return 'http://localhost:3000';
    }
  }
  if (__DEV__) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
};

const API_URL = getApiUrl();

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