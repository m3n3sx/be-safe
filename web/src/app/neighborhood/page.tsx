'use client';
import { useState } from 'react';
import { PageHeader } from '@/components/layout/PageHeader';
import { AreaControl, defaultArea } from '@/components/map/AreaControl';
import { Chat } from '@/components/community/Chat';
export default function Page() {
  const [area, setArea] = useState(defaultArea);
  return (
    <div className="page-container space-y-5">
      <PageHeader
        title="Czat sąsiedzki"
        description="Rozmowy w promieniu 2 km od wybranego obszaru. Wiadomość zostanie przypisana do tego obszaru."
      />
      <AreaControl area={area} onChange={setArea} />
      <Chat
        key={`${area.lat},${area.lng}`}
        path="/neighborhood/messages"
        query={`&lat=${area.lat}&lng=${area.lng}&radius_m=2000`}
        location={area}
      />
    </div>
  );
}
