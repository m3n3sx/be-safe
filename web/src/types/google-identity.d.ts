/* eslint-disable @typescript-eslint/no-explicit-any */

interface GoogleAccountsId {
  initialize: (config: {
    client_id: string;
    callback: (response: { credential: string }) => void;
  }) => void;
  prompt: (notification?: (notification: any) => void) => void;
  renderButton: (element: HTMLElement, config: any) => void;
  disableAutoSelect: () => void;
}

interface GoogleAccounts {
  id: GoogleAccountsId;
}

interface Google {
  accounts: GoogleAccounts;
}

declare global {
  interface Window {
    google: typeof google & {
      accounts: GoogleAccounts;
    };
  }
}

export {};
