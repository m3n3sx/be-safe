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
  ): Promise<T & { error?: string; httpStatus?: number; retryAfter?: string }> {
    const headers: Record<string, string> = {};
    const token = this.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
    if (!isMultipart) headers['Content-Type'] = 'application/json';

    try {
      const res = await fetch(`${API_BASE}${path}`, {
        method,
        headers,
        signal: AbortSignal.timeout(30000),
        body: body
          ? isMultipart
            ? (body as FormData)
            : JSON.stringify(body)
          : undefined,
      });

      const text = await res.text();
      if (res.status === 401 && !path.startsWith('/auth/') && typeof window !== 'undefined') window.dispatchEvent(new Event('besafe:session-expired'));
      if (res.status === 204) return {} as T & { error?: string };
      if (res.status >= 400 || (!text.startsWith('{') && !text.startsWith('['))) {
        try {
          const json = JSON.parse(text);
          return { ...json, error: json.error || json.message || `HTTP ${res.status}`, httpStatus: res.status, retryAfter: res.headers.get('Retry-After') || undefined } as T & { error: string; httpStatus: number };
        } catch {
          return { error: `HTTP ${res.status}`, httpStatus: res.status, retryAfter: res.headers.get('Retry-After') || undefined } as unknown as T & { error: string; httpStatus: number };
        }
      }

      return JSON.parse(text) as T & { error?: string };
    } catch (err) {
      return { error: err instanceof Error && err.name === 'TimeoutError' ? 'Serwer nie odpowiedział na czas. Wynik operacji może być niepewny.' : 'Brak połączenia z serwerem. Sprawdź internet i spróbuj ponownie.', httpStatus: 0 } as T & { error: string; httpStatus: number };
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

  put<T = Record<string, unknown>>(path: string, body?: Record<string, unknown>) {
    return this.request<T>('PUT', path, body);
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
