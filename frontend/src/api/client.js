const BASE_URL = import.meta.env.VITE_API_URL || '/api';

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

export async function get(endpoint) {
  const response = await fetch(`${BASE_URL}${endpoint}`, {
    method: 'GET',
    headers: getHeaders(),
  });
  return handleResponse(response);
}

export async function post(endpoint, body) {
  const response = await fetch(`${BASE_URL}${endpoint}`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify(body),
  });
  return handleResponse(response);
}

export async function put(endpoint, body) {
  const response = await fetch(`${BASE_URL}${endpoint}`, {
    method: 'PUT',
    headers: getHeaders(),
    body: JSON.stringify(body),
  });
  return handleResponse(response);
}

export async function del(endpoint) {
  const response = await fetch(`${BASE_URL}${endpoint}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  return handleResponse(response);
}

const apiClient = { get, post, put, del };
export default apiClient;
