import { ToolDirectory } from '@/components/safety/ToolDirectory';
export default function Page() { return <ToolDirectory title="Ochrona dziecka w sieci" description="Zewnętrzne narzędzia do ustawiania limitów i ochrony treści. be:Safe nie zarządza telefonem dziecka." tools={[
  { title: 'Google Family Link', desc: 'Ustawienia konta dziecka, aplikacji i czasu korzystania.', url: 'https://families.google.com/familylink/' },
  { title: 'Apple — Czas przed ekranem', desc: 'Limity aplikacji i treści na urządzeniach Apple.', url: 'https://support.apple.com/pl-pl/HT208982' },
  { title: 'Qustodio', desc: 'Zewnętrzne narzędzie kontroli rodzicielskiej. Zakres i opłaty sprawdź u dostawcy.', url: 'https://www.qustodio.com/pl/' },
  { title: 'Bark', desc: 'Narzędzia dla opiekunów w języku angielskim. Dostępność zależy od kraju i urządzenia.', url: 'https://www.bark.us/' },
  { title: 'Dyżurnet.pl', desc: 'Zgłaszanie nielegalnych treści, szczególnie dotyczących dzieci.', url: 'https://dyzurnet.pl/' },
  { title: 'Fundacja Dajemy Dzieciom Siłę', desc: 'Materiały edukacyjne i pomoc dla dzieci oraz opiekunów.', url: 'https://fdds.pl/' },
]} tips={['Ustalcie razem zasady i wyjaśnij dziecku ustawienia prywatności.', 'Zachęcaj do rozmowy o niepokojących treściach i kontaktach.', 'Dzieci i młodzież mogą zadzwonić pod numer 116 111.']} />; }
