import { ToolDirectory } from '@/components/safety/ToolDirectory';
export default function Page() { return <ToolDirectory title="Bezpieczeństwo w sieci" description="Sprawdź dane i zgłoś podejrzaną wiadomość." tools={[
  { title: 'Zastrzeż PESEL', desc: 'Sprawdź, jak zastrzec numer PESEL w mObywatelu.', url: 'https://www.gov.pl/web/mobywatel/zastrzezenia' },
  { title: 'Bezpieczne dane', desc: 'Informacje o wyciekach i ochronie danych.', url: 'https://bezpiecznedane.gov.pl' },
  { title: 'Have I Been Pwned', desc: 'Sprawdź adres e-mail w bazie ujawnionych wycieków.', url: 'https://haveibeenpwned.com' },
  { title: 'Zgłoś incydent do CERT Polska', desc: 'Podejrzana strona, phishing lub oszustwo.', url: 'https://incydent.cert.pl' },
  { title: 'Podejrzany SMS — 8080', desc: 'Przekaż oryginalną podejrzaną wiadomość na numer 8080 do CERT Polska.', url: 'sms:8080' },
]} tips={['Używaj różnych haseł i menedżera haseł.', 'Włącz uwierzytelnianie dwuskładnikowe, szczególnie w poczcie i banku.', 'Nie podawaj kodów BLIK, PIN ani haseł osobie, która do Ciebie dzwoni.', 'Zamiast otwierać link z wiadomości, samodzielnie wpisz znany adres serwisu.', 'Rozłącz podejrzaną rozmowę i skontaktuj się z bankiem przez oficjalny numer.', 'Nie publikuj zdjęć dokumentów. Aktualizuj system i aplikacje.']} />; }
