export type Section = 'nearby' | 'family' | 'help' | 'profile';
export type RouteEntry = {
  href: string;
  label: string;
  section: Section;
  public?: boolean;
  permission?: string;
  dynamic?: boolean;
};
export const primaryNavigation = [
  { href: '/', label: 'W okolicy', section: 'nearby', icon: 'map' },
  { href: '/family', label: 'Bliscy', section: 'family', icon: 'people' },
  { href: '/report', label: 'Zgłoś', section: 'nearby', icon: 'plus' },
  { href: '/help', label: 'Pomoc', section: 'help', icon: 'help' },
  { href: '/profile', label: 'Profil', section: 'profile', icon: 'user' },
] as const;
export const routes: RouteEntry[] = [
  { href: '/', label: 'W okolicy', section: 'nearby', public: true },
  { href: '/report', label: 'Zgłoś zdarzenie', section: 'nearby' },
  { href: '/alerts/[alertId]', label: 'Szczegóły zgłoszenia', section: 'nearby', dynamic: true },
  { href: '/aqi', label: 'Jakość powietrza', section: 'nearby' },
  { href: '/stats', label: 'Statystyki okolicy', section: 'nearby' },
  { href: '/news', label: 'Aktualności', section: 'nearby' },
  { href: '/family', label: 'Grupy i bliscy', section: 'family' },
  { href: '/family/join', label: 'Dołącz do grupy', section: 'family' },
  { href: '/family/join/[code]', label: 'Dołącz do grupy', section: 'family', dynamic: true },
  { href: '/family/[groupId]', label: 'Przegląd grupy', section: 'family', dynamic: true },
  {
    href: '/family/[groupId]/geofences',
    label: 'Bezpieczne strefy',
    section: 'family',
    dynamic: true,
  },
  {
    href: '/family/[groupId]/members/[memberId]/history',
    label: 'Historia lokalizacji',
    section: 'family',
    dynamic: true,
  },
  {
    href: '/family/[groupId]/members/[memberId]/safe-routes',
    label: 'Bezpieczne trasy',
    section: 'family',
    dynamic: true,
  },
  {
    href: '/family/[groupId]/members/[memberId]/safe-routes/new',
    label: 'Nowa bezpieczna trasa',
    section: 'family',
    dynamic: true,
  },
  {
    href: '/family/[groupId]/members/[memberId]/safe-routes/[routeId]',
    label: 'Szczegóły trasy',
    section: 'family',
    dynamic: true,
  },
  {
    href: '/family/pings/[pingId]',
    label: 'Odpowiedź na prośbę o kontakt',
    section: 'family',
    dynamic: true,
  },
  {
    href: '/family/[groupId]/sos/[alertId]',
    label: 'SOS bliskiej osoby',
    section: 'family',
    dynamic: true,
  },
  { href: '/neighborhood', label: 'Czat sąsiedzki', section: 'nearby' },
  { href: '/family/[groupId]/chat', label: 'Czat grupy', section: 'family', dynamic: true },
  { href: '/family/[groupId]/planner', label: 'Plan rodzinny', section: 'family', dynamic: true },
  {
    href: '/family/[groupId]/members/[memberId]',
    label: 'Profil bliskiej osoby',
    section: 'family',
    dynamic: true,
  },
  { href: '/pets', label: 'Zwierzęta i zaginięcia', section: 'family' },
  { href: '/help', label: 'Pomoc', section: 'help', public: true },
  { href: '/sos', label: 'SOS — pilna pomoc', section: 'help', public: true },
  { href: '/emergency', label: 'Numery alarmowe', section: 'help', public: true },
  { href: '/sos/mental', label: 'Wsparcie w kryzysie', section: 'help', public: true },
  { href: '/aed', label: 'Znajdź defibrylator AED', section: 'help' },
  { href: '/escort', label: 'Bezpieczny powrót', section: 'help' },
  {
    href: '/escort/[sessionId]',
    label: 'Sesja bezpiecznego powrotu',
    section: 'help',
    dynamic: true,
  },
  { href: '/fakecall', label: 'Fałszywy telefon', section: 'help' },
  { href: '/guide', label: 'Poradnik bezpieczeństwa', section: 'help', public: true },
  { href: '/cyber', label: 'Bezpieczeństwo w sieci', section: 'help', public: true },
  { href: '/parental-controls', label: 'Ochrona dziecka w sieci', section: 'help', public: true },
  { href: '/landing', label: 'O aplikacji', section: 'help', public: true },
  { href: '/profile', label: 'Mój profil', section: 'profile' },
  { href: '/alerts/mine', label: 'Moje zgłoszenia', section: 'profile' },
  { href: '/alerts', label: 'Moje zgłoszenia — dawny adres', section: 'profile' },
  { href: '/settings', label: 'Ustawienia', section: 'profile' },
  { href: '/permissions', label: 'Uprawnienia urządzenia', section: 'profile' },
  { href: '/mode', label: 'Widok aplikacji', section: 'profile' },
  { href: '/onboarding', label: 'Wprowadzenie', section: 'profile' },
  { href: '/badges', label: 'Odznaki', section: 'profile' },
  { href: '/ranking', label: 'Ranking społeczności', section: 'profile' },
  { href: '/referral', label: 'Zaproś znajomych', section: 'profile' },
  { href: '/notifications', label: 'Powiadomienia', section: 'profile' },
  { href: '/privacy', label: 'Polityka prywatności', section: 'profile', public: true },
  { href: '/terms', label: 'Regulamin', section: 'profile', public: true },
  { href: '/verify-email', label: 'Weryfikacja e-maila', section: 'profile', public: true },
  { href: '/forgot-password', label: 'Odzyskaj hasło', section: 'profile', public: true },
  { href: '/reset-password', label: 'Ustaw nowe hasło z linku', section: 'profile', public: true },
  { href: '/login', label: 'Zaloguj się', section: 'profile', public: true },
  { href: '/register', label: 'Utwórz konto', section: 'profile', public: true },
  { href: '/admin', label: 'Administracja — przegląd', section: 'profile', permission: '' },
  { href: '/admin/users', label: 'Użytkownicy', section: 'profile', permission: 'users.read' },
  {
    href: '/admin/alerts',
    label: 'Moderacja alertów',
    section: 'profile',
    permission: 'alerts.read',
  },
  {
    href: '/admin/reports',
    label: 'Zgłoszenia nadużyć',
    section: 'profile',
    permission: 'reports.read',
  },
  { href: '/admin/groups', label: 'Grupy', section: 'profile', permission: 'groups.read' },
  { href: '/admin/control', label: 'Konfiguracja', section: 'profile', permission: 'config.read' },
  { href: '/admin/system', label: 'System', section: 'profile', permission: 'system.read' },
  { href: '/admin/audit', label: 'Dziennik działań', section: 'profile', permission: 'audit.read' },
];
export function routeFor(path: string) {
  return (
    routes.find((route) => !route.dynamic && route.href === path) ||
    routes.find(
      (route) =>
        route.dynamic && new RegExp(`^${route.href.replace(/\[[^\]]+\]/g, '[^/]+')}$`).test(path),
    )
  );
}
export function routeHref(template: string, params: Record<string, string>) {
  return template.replace(/\[([^\]]+)\]/g, (_, key: string) =>
    encodeURIComponent(params[key] || ''),
  );
}
