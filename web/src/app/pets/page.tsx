'use client';

import React, { useEffect, useState } from 'react';
import api from '@/lib/api';

interface Pet {
  id: string;
  group_id: string;
  name: string;
  species: string;
  breed?: string | null;
  color?: string | null;
  age_years?: number | null;
  microchip?: string | null;
  photo_url?: string | null;
  notes?: string | null;
  is_lost: boolean;
  lost_since?: string | null;
  lost_lat?: number | null;
  lost_lng?: number | null;
  owner_username?: string;
}

interface Group {
  id: string;
  name: string;
}

const SPECIES = [
  { value: 'dog', label: '🐕 Pies' },
  { value: 'cat', label: '🐈 Kot' },
  { value: 'bird', label: '🦜 Ptak' },
  { value: 'rabbit', label: '🐇 Królik' },
  { value: 'other', label: '🐾 Inny' },
];

export default function PetsPage() {
  const [pets, setPets] = useState<Pet[]>([]);
  const [lostNearby, setLostNearby] = useState<Pet[]>([]);
  const [groups, setGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [tab, setTab] = useState<'mine' | 'lost'>('mine');

  const load = async () => {
    setLoading(true);
    const [petsRes, groupsRes] = await Promise.all([
      api.get('/pets/mine'),
      api.get('/family/groups'),
    ]);
    setPets((petsRes.pets as Pet[]) || []);
    setGroups((groupsRes.groups as Group[]) || []);
    // Lost nearby — needs geolocation
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(async pos => {
        const r = await api.get(`/pets/lost/nearby?lat=${pos.coords.latitude}&lng=${pos.coords.longitude}&radius_m=20000`);
        setLostNearby((r.pets as Pet[]) || []);
      });
    }
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const markLost = async (pet: Pet) => {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(async pos => {
      await api.post(`/pets/${pet.id}/lost`, {
        lat: pos.coords.latitude,
        lng: pos.coords.longitude,
      });
      load();
    });
  };

  const markFound = async (pet: Pet) => {
    await api.post(`/pets/${pet.id}/found`, {});
    load();
  };

  const remove = async (pet: Pet) => {
    if (!confirm(`Usunąć ${pet.name}?`)) return;
    await api.delete(`/pets/${pet.id}`);
    load();
  };

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 px-4 py-6 max-w-3xl mx-auto">
      <div className="flex items-center justify-between mb-4">
        <h1 className="text-2xl font-light text-neutral-900 dark:text-white">🐾 Zwierzaki</h1>
        {groups.length > 0 && (
          <button
            onClick={() => setShowCreate(true)}
            className="px-4 py-2 rounded-xl bg-[#9DF4CB] text-[#1A2027] text-sm font-semibold hover:opacity-90"
          >
            + Dodaj
          </button>
        )}
      </div>

      <div className="flex gap-2 mb-4">
        <button
          onClick={() => setTab('mine')}
          className={`px-4 py-2 rounded-full text-sm font-medium ${tab === 'mine' ? 'bg-[#1A2027] text-white' : 'bg-white dark:bg-neutral-800 text-neutral-600 dark:text-neutral-300'}`}
        >
          Moje ({pets.length})
        </button>
        <button
          onClick={() => setTab('lost')}
          className={`px-4 py-2 rounded-full text-sm font-medium ${tab === 'lost' ? 'bg-[#FF7A7A] text-white' : 'bg-white dark:bg-neutral-800 text-neutral-600 dark:text-neutral-300'}`}
        >
          Zaginione w okolicy ({lostNearby.length})
        </button>
      </div>

      {loading && <p className="text-center text-neutral-500 py-12">Ładowanie...</p>}

      {tab === 'mine' && !loading && (
        <>
          {pets.length === 0 && groups.length === 0 && (
            <div className="bg-white dark:bg-neutral-900 rounded-2xl p-8 text-center">
              <p className="text-neutral-600 dark:text-neutral-300">Musisz najpierw dołączyć do grupy rodziny.</p>
            </div>
          )}
          {pets.length === 0 && groups.length > 0 && (
            <div className="bg-white dark:bg-neutral-900 rounded-2xl p-8 text-center">
              <div className="text-5xl mb-3">🐕</div>
              <p className="text-neutral-600 dark:text-neutral-300 mb-4">Nie masz jeszcze żadnych pupili. Dodaj pierwszego!</p>
              <button
                onClick={() => setShowCreate(true)}
                className="px-5 py-2 rounded-xl bg-[#1A2027] text-white text-sm font-semibold"
              >
                Dodaj zwierzaka
              </button>
            </div>
          )}
          <div className="grid sm:grid-cols-2 gap-3">
            {pets.map(p => (
              <PetCard key={p.id} pet={p} onMarkLost={() => markLost(p)} onMarkFound={() => markFound(p)} onRemove={() => remove(p)} />
            ))}
          </div>
        </>
      )}

      {tab === 'lost' && !loading && (
        <div className="space-y-3">
          {lostNearby.length === 0 && (
            <div className="bg-white dark:bg-neutral-900 rounded-2xl p-8 text-center">
              <div className="text-5xl mb-3">✓</div>
              <p className="text-neutral-600 dark:text-neutral-300">Nie ma zaginionych zwierzaków w pobliżu.</p>
            </div>
          )}
          {lostNearby.map(p => (
            <LostPetCard key={p.id} pet={p} />
          ))}
        </div>
      )}

      {showCreate && (
        <CreatePetModal
          groups={groups}
          onClose={() => setShowCreate(false)}
          onCreated={() => { setShowCreate(false); load(); }}
        />
      )}
    </div>
  );
}

function PetCard({ pet, onMarkLost, onMarkFound, onRemove }: {
  pet: Pet; onMarkLost: () => void; onMarkFound: () => void; onRemove: () => void;
}) {
  return (
    <div className={`bg-white dark:bg-neutral-900 rounded-2xl p-4 border ${pet.is_lost ? 'border-[#FF7A7A]' : 'border-neutral-200 dark:border-neutral-800'}`}>
      <div className="flex items-start gap-3">
        <div className="w-14 h-14 rounded-2xl bg-[#9EEBEC]/30 flex items-center justify-center text-2xl flex-shrink-0">
          {pet.species === 'dog' ? '🐕' : pet.species === 'cat' ? '🐈' : pet.species === 'bird' ? '🦜' : pet.species === 'rabbit' ? '🐇' : '🐾'}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-neutral-900 dark:text-white truncate">{pet.name}</h3>
            {pet.is_lost && <span className="text-[10px] px-2 py-0.5 rounded-full bg-[#FF7A7A] text-white font-bold">ZAGINIONY</span>}
          </div>
          <p className="text-xs text-neutral-500 mt-0.5">
            {pet.breed || '—'}{pet.color ? ` · ${pet.color}` : ''}{pet.age_years ? ` · ${pet.age_years} lat` : ''}
          </p>
          {pet.microchip && <p className="text-[10px] text-neutral-400 mt-1">Chip: {pet.microchip}</p>}
        </div>
      </div>
      <div className="flex gap-2 mt-3">
        {pet.is_lost ? (
          <button onClick={onMarkFound} className="flex-1 px-3 py-2 rounded-xl bg-[#9DF4CB] text-[#1A2027] text-xs font-semibold">
            ✓ Znaleziony
          </button>
        ) : (
          <button onClick={onMarkLost} className="flex-1 px-3 py-2 rounded-xl bg-[#FF7A7A] text-white text-xs font-semibold">
            🚨 Oznacz zaginionego
          </button>
        )}
        <button onClick={onRemove} className="px-3 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-neutral-500 text-xs hover:bg-red-100 dark:hover:bg-red-900/30 hover:text-red-500">
          Usuń
        </button>
      </div>
    </div>
  );
}

function LostPetCard({ pet }: { pet: Pet }) {
  return (
    <div className="bg-white dark:bg-neutral-900 rounded-2xl p-4 border border-[#FF7A7A]/30">
      <div className="flex items-start gap-3">
        <div className="w-14 h-14 rounded-2xl bg-[#FF7A7A]/20 flex items-center justify-center text-2xl flex-shrink-0">
          {pet.species === 'dog' ? '🐕' : pet.species === 'cat' ? '🐈' : pet.species === 'bird' ? '🦜' : pet.species === 'rabbit' ? '🐇' : '🐾'}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-neutral-900 dark:text-white">{pet.name}</h3>
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-[#FF7A7A] text-white font-bold">ZAGINIONY</span>
          </div>
          <p className="text-xs text-neutral-500 mt-0.5">
            {pet.breed || '—'}{pet.color ? ` · ${pet.color}` : ''} · właściciel: {pet.owner_username}
          </p>
          {pet.lost_since && <p className="text-[10px] text-neutral-400 mt-1">Zaginął: {new Date(pet.lost_since).toLocaleDateString('pl-PL')}</p>}
        </div>
      </div>
    </div>
  );
}

function CreatePetModal({ groups, onClose, onCreated }: {
  groups: Group[]; onClose: () => void; onCreated: () => void;
}) {
  const [name, setName] = useState('');
  const [species, setSpecies] = useState('dog');
  const [breed, setBreed] = useState('');
  const [color, setColor] = useState('');
  const [age, setAge] = useState('');
  const [chip, setChip] = useState('');
  const [groupId, setGroupId] = useState(groups[0]?.id || '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const save = async () => {
    if (!name || !groupId) { setError('Nazwa i grupa wymagane'); return; }
    setSaving(true);
    setError(null);
    const res = await api.post('/pets', {
      group_id: groupId, name, species,
      breed: breed || undefined,
      color: color || undefined,
      age_years: age ? Number(age) : undefined,
      microchip: chip || undefined,
    });
    setSaving(false);
    if (res.error) { setError(res.error); return; }
    onCreated();
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white dark:bg-neutral-900 rounded-3xl p-6 max-w-md w-full max-h-[90vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
        <h2 className="text-xl font-light mb-4">Dodaj zwierzaka</h2>
        <div className="space-y-3">
          <label className="block">
            <span className="text-xs text-neutral-500">Grupa rodzinna</span>
            <select value={groupId} onChange={e => setGroupId(e.target.value)} className="mt-1 w-full px-3 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-sm">
              {groups.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="text-xs text-neutral-500">Imię *</span>
            <input value={name} onChange={e => setName(e.target.value)} maxLength={80} className="mt-1 w-full px-3 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-sm" />
          </label>
          <label className="block">
            <span className="text-xs text-neutral-500">Gatunek</span>
            <select value={species} onChange={e => setSpecies(e.target.value)} className="mt-1 w-full px-3 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-sm">
              {SPECIES.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="text-xs text-neutral-500">Rasa</span>
            <input value={breed} onChange={e => setBreed(e.target.value)} className="mt-1 w-full px-3 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-sm" />
          </label>
          <label className="block">
            <span className="text-xs text-neutral-500">Kolor</span>
            <input value={color} onChange={e => setColor(e.target.value)} className="mt-1 w-full px-3 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-sm" />
          </label>
          <label className="block">
            <span className="text-xs text-neutral-500">Wiek (lata)</span>
            <input value={age} onChange={e => setAge(e.target.value)} type="number" min={0} max={50} className="mt-1 w-full px-3 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-sm" />
          </label>
          <label className="block">
            <span className="text-xs text-neutral-500">Chip (opcjonalnie)</span>
            <input value={chip} onChange={e => setChip(e.target.value)} className="mt-1 w-full px-3 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-sm" />
          </label>
          {error && <p className="text-sm text-red-500">{error}</p>}
          <div className="flex gap-2 pt-2">
            <button onClick={onClose} className="flex-1 py-2.5 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-sm">Anuluj</button>
            <button onClick={save} disabled={saving} className="flex-1 py-2.5 rounded-xl bg-[#1A2027] text-white text-sm font-semibold disabled:opacity-50">
              {saving ? '...' : 'Zapisz'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
