const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://besafe.org.pl/api/v1';

/** API types describe the contract, not a guarantee about a network response. */
export function asArray<T>(value: T[] | null | undefined): T[] {
  return Array.isArray(value) ? value.filter((item) => item != null) : [];
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

const textFields = new Set([
  'username',
  'email',
  'phone',
  'avatar_url',
  'title',
  'name',
  'description',
  'content',
  'body',
  'image_url',
  'author_username',
  'reporter_username',
  'viewer_username',
  'owner_username',
  'invite_code',
  'referral_code',
  'reason',
  'ban_reason',
  'created_at',
  'starts_at',
  'ends_at',
  'recorded_at',
  'day',
  'status',
  'category',
  'role',
  'app_mode',
  'notes',
  'species',
  'breed',
  'color',
  'lost_description',
]);

const numberFields = new Set([
  'reputation_score',
  'confirms',
  'denies',
  'trust_score',
  'alert_count',
  'total_confirms',
  'referrals_count',
  'alert_radius_m',
  'members_count',
  'reports_count',
  'reports_pending',
  'n',
  'banned',
  'admins',
  'new_week',
  'active',
  'new_24h',
  'today',
  'week',
  'total',
  'count',
  'ok_count',
  'latency_ms',
  'recipients',
  'radius_m',
  'threshold_m',
  'battery_level',
  'age',
  'distance_m',
]);

function validDisplayFields(value: Record<string, unknown>): boolean {
  return Object.entries(value).every(([key, field]) => {
    if (field == null) return true;
    if (textFields.has(key)) return typeof field === 'string';
    if (numberFields.has(key))
      return (
        (typeof field === 'number' || typeof field === 'string') && Number.isFinite(Number(field))
      );
    if (['author', 'user'].includes(key)) return isRecord(field) && validDisplayFields(field);
    // Arbitrary configuration/audit/notification payloads are not presentation models.
    if (['value', 'payload', 'data', 'visibility', 'capabilities', 'updated'].includes(key))
      return true;
    if (isRecord(field)) return validDisplayFields(field);
    if (Array.isArray(field))
      return field.every((item) => !isRecord(item) || validDisplayFields(item));
    return true;
  });
}

export function normalizeResponse(path: string, value: unknown, method = 'GET') {
  const invalid = { error: 'Serwer zwrócił niepełne dane. Spróbuj odświeżyć widok.' };
  if (!isRecord(value)) return invalid;
  if (!validDisplayFields(value)) return invalid;
  if (value.error || method !== 'GET') return value;
  const route = path.split('?')[0];
  const lists: [RegExp, string[]][] = [
    [/^\/family\/groups$/, ['groups']],
    [/^\/family\/groups\/[^/]+\/(members|checkins\/today)$/, ['members']],
    [/\/(messages|geofences|events|history|safe-routes)$/, []],
    [/^\/family\/pings\/pending$/, ['pings']],
    [/^\/family\/groups\/[^/]+\/pings\/pending$/, ['pings']],
    [/\/visibility-matrix\/[^/]+$/, ['matrix']],
    [/^\/escort\/active$/, ['sessions']],
    [/^\/notifications$/, ['notifications']],
    [/^\/alerts\/(nearby|mine|new)$/, ['alerts']],
    [/\/alerts-near$/, ['alerts']],
    [/^\/alerts\/[^/]+\/comments$/, ['comments']],
    [/^\/pets\/(mine|lost\/nearby)$/, ['pets']],
    [/^\/aeds\/nearby$/, ['aeds']],
    [/^\/aqi\/nearby$/, ['stations']],
    [/^\/users\/ranking$/, ['ranking']],
    [/^\/me\/badges$/, ['earned', 'available']],
    [/^\/posts$/, ['posts']],
    [/^\/alerts\/stats$/, ['by_category', 'trend']],
    [/^\/admin\/(users|alerts|reports|groups|config|flags)$/, []],
    [/^\/admin\/audit-log$/, ['entries']],
    [/^\/admin\/analytics$/, ['series']],
    [/^\/admin\/integrations\/health$/, ['checks']],
  ];
  const match = lists.find(([pattern]) => pattern.test(route));
  if (match) {
    const last = route.split('/').at(-1)!;
    const fields = match[1].length ? match[1] : [last === 'safe-routes' ? 'routes' : last];
    for (const field of fields) {
      if (!Array.isArray(value[field])) return { ...invalid, [field]: [] };
      // A malformed row must not reach JSX or a nested property access.
      if (value[field].some((row: unknown) => !isRecord(row) || !validDisplayFields(row)))
        return invalid;
    }
    if (Array.isArray(value.routes)) {
      value.routes = value.routes.map((row) => ({
        ...row,
        points: Array.isArray(row.points)
          ? row.points.filter(
              (point: unknown) =>
                Array.isArray(point) &&
                point.length === 2 &&
                point.every((n) => Number.isFinite(Number(n))),
            )
          : [],
      }));
    }
  }
  if (route === '/alerts/stats' && !isRecord(value.totals)) return invalid;
  if (
    route === '/admin/stats' &&
    ['users', 'alerts', 'groups', 'pets'].some((key) => !isRecord(value[key]))
  )
    return invalid;
  if (Array.isArray(value.matrix) && value.matrix.some((row) => !isRecord(row.visibility)))
    return invalid;
  if (route === '/permissions' && !isRecord(value.capabilities)) return invalid;
  if (route === '/users/me' && !value.id) return invalid;
  if (/^\/(escort|family\/pings)\/[^/]+$/.test(route) && !match && !value.id) return invalid;
  return value;
}

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
    isMultipart = false,
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
        body: body ? (isMultipart ? (body as FormData) : JSON.stringify(body)) : undefined,
      });

      const text = (await res.text()).trim();
      if (res.status === 401 && !path.startsWith('/auth/') && typeof window !== 'undefined')
        window.dispatchEvent(new Event('besafe:session-expired'));
      if (res.status === 204) return normalizeResponse(path, {}, method) as T & { error?: string };
      if (res.status >= 400 || (!text.startsWith('{') && !text.startsWith('['))) {
        try {
          const json = JSON.parse(text);
          return {
            ...json,
            error:
              typeof json.error === 'string'
                ? json.error
                : typeof json.message === 'string'
                  ? json.message
                  : `HTTP ${res.status}`,
            httpStatus: res.status,
            retryAfter: res.headers.get('Retry-After') || undefined,
          } as T & { error: string; httpStatus: number };
        } catch {
          return {
            error: `HTTP ${res.status}`,
            httpStatus: res.status,
            retryAfter: res.headers.get('Retry-After') || undefined,
          } as unknown as T & { error: string; httpStatus: number };
        }
      }

      return normalizeResponse(path, JSON.parse(text), method) as T & { error?: string };
    } catch (err) {
      return {
        error:
          err instanceof Error && err.name === 'TimeoutError'
            ? 'Serwer nie odpowiedział na czas. Wynik operacji może być niepewny.'
            : 'Brak połączenia z serwerem. Sprawdź internet i spróbuj ponownie.',
        httpStatus: 0,
      } as T & { error: string; httpStatus: number };
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
