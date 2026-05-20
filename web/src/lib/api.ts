const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://besafe.org.pl/api/v1';

class ApiService {
  private token: string | null = null;

  setToken(token: string | null) {
    this.token = token;
    if (token) {
      if (typeof window !== 'undefined') localStorage.setItem('jwt_token', token);
    } else {
      if (typeof window !== 'undefined') localStorage.removeItem('jwt_token');
    }
  }

  getToken(): string | null {
    if (this.token) return this.token;
    if (typeof window !== 'undefined') {
      this.token = localStorage.getItem('jwt_token');
    }
    return this.token;
  }

  private async request<T = Record<string, unknown>>(
    method: string,
    path: string,
    body?: Record<string, unknown> | FormData,
    isMultipart = false
  ): Promise<T & { error?: string }> {
    const headers: Record<string, string> = {};
    const token = this.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
    if (!isMultipart) headers['Content-Type'] = 'application/json';

    try {
      const res = await fetch(`${API_BASE}${path}`, {
        method,
        headers,
        body: body
          ? isMultipart
            ? (body as FormData)
            : JSON.stringify(body)
          : undefined,
      });

      const text = await res.text();
      if (res.status >= 400 || (!text.startsWith('{') && !text.startsWith('['))) {
        try {
          const json = JSON.parse(text);
          return { ...json, error: json.error || json.message || `HTTP ${res.status}` } as T & { error: string };
        } catch {
          return { error: `HTTP ${res.status}` } as T & { error: string };
        }
      }

      return JSON.parse(text) as T & { error?: string };
    } catch (err) {
      return { error: err instanceof Error ? err.message : 'Network error' } as T & { error: string };
    }
  }

  get<T = Record<string, unknown>>(path: string) {
    return this.request<T>('GET', path);
  }

  post<T = Record<string, unknown>>(path: string, body?: Record<string, unknown>) {
    return this.request<T>('POST', path, body);
  }

  patch<T = Record<string, unknown>>(path: string, body?: Record<string, unknown>) {
    return this.request<T>('PATCH', path, body);
  }

  delete<T = Record<string, unknown>>(path: string) {
    return this.request<T>('DELETE', path);
  }

  async multipart<T = Record<string, unknown>>(path: string, formData: FormData) {
    return this.request<T>('POST', path, formData, true);
  }
}

export const api = new ApiService();
export default api;
