'use client';
import { useState } from 'react';
import api from '@/lib/api';
import type { FamilyGroup } from '@/types';
import type { Pet } from '@/lib/api/pets';
import { speciesLabels } from '@/lib/api/pets';
import type { Place } from '@/lib/location';
import { useMutation } from '@/hooks/useApiResource';
import { MapProvider } from '@/components/map/MapProvider';
import { LocationPicker } from '@/components/map/LocationPicker';
import { Button } from '@/components/ui/Button';
import { TextField, TextArea, Select } from '@/components/ui/FormField';
import { Dialog } from '@/components/ui/Dialog';
import { ErrorState } from '@/components/ui/ErrorState';
export function PetForm({ groups, onClose, onDone }: { groups: FamilyGroup[]; onClose: () => void; onDone: () => Promise<void> }) {
  const [groupId, setGroupId] = useState(groups[0]?.id || ''); const [name, setName] = useState(''); const [species, setSpecies] = useState('dog'); const [breed, setBreed] = useState(''); const [color, setColor] = useState(''); const [age, setAge] = useState(''); const [chip, setChip] = useState(''); const [notes, setNotes] = useState(''); const [home, setHome] = useState<Place | null>(null); const mutation = useMutation();
  async function save(e: React.FormEvent) { e.preventDefault(); await mutation.run(() => api.post<Pet>('/pets', { group_id: groupId, name: name.trim(), species, breed, color, age_years: age ? Number(age) : null, microchip: chip, notes, ...(home ? { home_lat: home.lat, home_lng: home.lng } : {}) }), async r => { if (r.id) await onDone(); }); }
  return <Dialog open title="Dodaj zwierzę" onClose={() => { if (!mutation.busy) onClose(); }}><form className="space-y-4" onSubmit={save}><Select label="Grupa" value={groupId} onChange={e => setGroupId(e.target.value)}>{groups.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}</Select><TextField label="Imię" maxLength={80} required value={name} onChange={e => setName(e.target.value)} /><Select label="Gatunek" value={species} onChange={e => setSpecies(e.target.value)}>{Object.entries(speciesLabels).map(([value, label]) => <option value={value} key={value}>{label}</option>)}</Select><TextField label="Rasa (opcjonalnie)" value={breed} onChange={e => setBreed(e.target.value)} /><TextField label="Kolor (opcjonalnie)" value={color} onChange={e => setColor(e.target.value)} /><TextField label="Wiek w latach (opcjonalnie)" type="number" min={0} max={100} step="0.1" value={age} onChange={e => setAge(e.target.value)} /><TextField label="Mikroczip (opcjonalnie)" value={chip} onChange={e => setChip(e.target.value)} /><TextArea label="Notatki (opcjonalnie)" rows={3} value={notes} onChange={e => setNotes(e.target.value)} /><details><summary className="min-h-12 cursor-pointer py-3">Miejsce zamieszkania (opcjonalnie)</summary><MapProvider><LocationPicker value={home} onChange={setHome} /></MapProvider>{home && <Button variant="quiet" onClick={() => setHome(null)}>Usuń miejsce</Button>}</details>{mutation.error && <ErrorState message={mutation.error} />}<Button type="submit" loading={mutation.busy} disabled={!name.trim() || !groupId}>Zapisz zwierzę</Button></form></Dialog>;
}
export function PetLocationAction({ pet, kind, onClose, onDone }: { pet: Pet; kind: 'lost' | 'sighting'; onClose: () => void; onDone: () => Promise<void> }) {
  const [place, setPlace] = useState<Place | null>(null); const [text, setText] = useState(''); const mutation = useMutation();
  return <Dialog open title={kind === 'lost' ? `Zaginięcie: ${pet.name}` : `Zauważone zwierzę: ${pet.name}`} onClose={() => { if (!mutation.busy) onClose(); }}><div className="space-y-4"><p>Wskaż miejsce, w którym zwierzę było ostatnio widziane.</p><MapProvider><LocationPicker value={place} onChange={setPlace} /></MapProvider><TextArea label="Opis sytuacji (opcjonalnie)" rows={3} value={text} onChange={e => setText(e.target.value)} />{mutation.error && <ErrorState message={mutation.error} />}<Button loading={mutation.busy} disabled={!place} onClick={() => { if (place) void mutation.run(() => api.post(`/pets/${pet.id}/${kind}`, { lat: place.lat, lng: place.lng, [kind === 'lost' ? 'description' : 'note']: text }), onDone); }}>Potwierdź i wyślij</Button></div></Dialog>;
}
