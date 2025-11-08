import axios from 'axios';

// Timeout and small retry wrapper to handle transient network errors from the backend/OpenAI
const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 60000, // 60s timeout to match backend tolerance
});

const withRetry = async (fn, attempts = 2, backoffMs = 500) => {
  let lastErr;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      lastErr = e;
      // if last attempt, break and throw
      if (i < attempts - 1) await new Promise((r) => setTimeout(r, backoffMs));
    }
  }
  throw lastErr;
};

export const setApiKey = async (apiKey) => {
  return withRetry(() => apiClient.post('/api-key', { api_key: apiKey }).then((r) => r.data));
};

export const checkApiKey = async () => {
  return withRetry(() => apiClient.get('/api-key').then((r) => r.data));
};

export const generatePlan = async (data) => {
  return withRetry(() => apiClient.post('/generate-plan', data).then((r) => r.data), 2, 1000);
};

export const getHistory = async () => {
  return withRetry(() => apiClient.get('/history').then((r) => r.data));
};

export default apiClient;