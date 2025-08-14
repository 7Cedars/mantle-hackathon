'use client';

import { usePrivy } from '@privy-io/react-auth';
import { useAccount, useDisconnect } from 'wagmi';
import { useEffect, useState } from 'react';

export default function ConnectButton() {
  const { login, logout, authenticated, user, ready } = usePrivy();
  const { address, isConnected } = useAccount();
  const { disconnect } = useDisconnect();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <button className="bg-primary-dark hover:bg-primary text-white px-8 py-2 rounded-lg font-medium transition-colors w-32">
        Loading...
      </button>
    );
  }

  if (!ready) {
    return (
      <button className="bg-primary-dark hover:bg-primary text-white px-8 py-2 rounded-lg font-medium transition-colors w-32">
        Loading...
      </button>
    );
  }

  if (authenticated && isConnected) {
    return (
      <div className="flex items-center gap-3">
        <div className="text-sm text-gray-300">
          {address ? `${address.slice(0, 6)}...${address.slice(-4)}` : 'Connected'}
        </div>
        <button
          onClick={() => {
            logout();
            disconnect();
          }}
          className="bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded-lg font-medium transition-colors"
        >
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <button
      onClick={login}
      className="bg-primary-dark hover:bg-primary text-white px-8 py-2 rounded-lg font-medium transition-colors w-32"
    >
      Connect
    </button>
  );
}
