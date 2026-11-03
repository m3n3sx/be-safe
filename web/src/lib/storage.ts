export function readSession<T>(key: string): T | null { try { return JSON.parse(sessionStorage.getItem(key) || 'null') as T | null; } catch { return null; } }
export function writeSession(key: string, value: unknown) { try { sessionStorage.setItem(key, JSON.stringify(value)); return true; } catch { return false; } }
export function removeSession(key: string) { try { sessionStorage.removeItem(key); } catch {} }
