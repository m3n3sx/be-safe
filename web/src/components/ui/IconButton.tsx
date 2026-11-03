import { Button, type ButtonProps } from './Button';
export function IconButton({ label, ...props }: ButtonProps & { label: string }) {
  return <Button variant="quiet" {...props} aria-label={label} title={label} />;
}
