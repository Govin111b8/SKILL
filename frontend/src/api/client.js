const BASE_URL = import.meta.env.VITE_API_URL || '/api';

const REQUEST_TIMEOUT_MS = 30000;
const MAX_RETRIES = 2;
const RETRY_DELAY_MS = 1000;

function getHeaders() {
  const headers = { 'Content-Type': 'application/json' };
  const token = localStorage.getItem('token');
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}

async function handleResponse(response) {
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    const error = new Error(data?.message || `HTTP error ${response.status}`);
    error.status = response.status;
    error.data = data;
    throw error;
  }
  return data;
}

async function fetchWithTimeout(url, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    return response;
  } finally {
    clearTimeout(timeout);
  }
}

async function requestWithRetry(url, options = {}, retries = MAX_RETRIES) {
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const response = await fetchWithTimeout(url, options);

      // Don't retry client errors (4xx) except 408/429
      if (!response.ok && response.status < 500 && response.status !== 408 && response.status !== 429) {
        return response;
      }

      if (response.ok || attempt === retries) {
        return response;
      }
    } catch (err) {
      if (attempt === retries) throw err;
      // Don't retry user-initiated aborts
      if (err.name === 'AbortError' && attempt === 0) throw err;
    }

    // Exponential backoff: 1s, 2s
    await new Promise((r) => setTimeout(r, RETRY_DELAY_MS * Math.pow(2, attempt)));
  }
}

export async function get(endpoint) {
  const response = await requestWithRetry(`${BASE_URL}${endpoint}`, {
    method: 'GET',
    headers: getHeaders(),
  });
  return handleResponse(response);
}

export async function post(endpoint, body) {
  const response = await requestWithRetry(`${BASE_URL}${endpoint}`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify(body),
  });
  return handleResponse(response);
}

export async function put(endpoint, body) {
  const response = await requestWithRetry(`${BASE_URL}${endpoint}`, {
    method: 'PUT',
    headers: getHeaders(),
    body: JSON.stringify(body),
  });
  return handleResponse(response);
}

export async function del(endpoint) {
  const response = await requestWithRetry(`${BASE_URL}${endpoint}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  return handleResponse(response);
}

const apiClient = { get, post, put, del };
export default apiClient;
