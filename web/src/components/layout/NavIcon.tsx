export function NavIcon({ name }: { name: string }) {
  const paths: Record<string, string> = { map: 'm3 6 6-3 6 3 6-3v15l-6 3-6-3-6 3V6Zm6-3v15m6-12v15', people: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2m20 0v-2a4 4 0 0 0-3-3.87M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm8-7a4 4 0 0 1 0 8', plus: 'M12 5v14M5 12h14', help: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20Zm-3-14a3 3 0 0 1 6 0c0 2-3 2-3 5m0 3v1', user: 'M20 21v-2a7 7 0 0 0-14 0v2m6-10a4 4 0 1 0 0-8 4 4 0 0 0 0 8', bell: 'M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4' };
  return <svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d={paths[name] || paths.map} /></svg>;
}
