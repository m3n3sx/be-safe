import { Button } from './Button';
export function ErrorState({ message = 'Nie udało się pobrać danych.', onRetry }: { message?: string; onRetry?: () => void }) { return <div role="alert" className="p-4 border border-danger rounded-xl space-y-3"><p className="text-danger">{message}</p>{onRetry && <Button variant="secondary" onClick={onRetry}>Spróbuj ponownie</Button>}</div>; }
