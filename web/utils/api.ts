// Simple API client for Rupaya web app
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://api.rupaya.in';

export async function apiRequest<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
    credentials: 'include',
  });
  if (!res.ok) {
    const error = await res.text();
    throw new Error(error || 'API error');
  }
  return res.json();
}

export async function login(email: string, password: string) {
  return apiRequest<{ token: string }>('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
}

export async function signup(name: string, email: string, password: string) {
  return apiRequest<{ token: string }>('/api/auth/signup', {
    method: 'POST',
    body: JSON.stringify({ name, email, password }),
  });
}

export async function getDashboard() {
  return apiRequest<any>('/api/dashboard');
}

export async function getTransactions() {
  return apiRequest<any[]>('/api/transactions');
}

export async function getAccounts() {
  return apiRequest<any[]>('/api/accounts');
}

export async function getAnalytics() {
  return apiRequest<any>('/api/analytics');
}

export async function getCategories() {
  return apiRequest<any[]>('/api/categories');
}
