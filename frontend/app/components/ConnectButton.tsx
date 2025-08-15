'use client';

import { usePrivy } from '@privy-io/react-auth';
import { useAccount, useDisconnect } from 'wagmi';

export default function ConnectButton() {
  const { login, logout, authenticated, user, ready } = usePrivy();
  const { address } = useAccount();
  const { disconnect } = useDisconnect();

  const handleLogin = () => {
    console.log("handleLogin");
    login();
  };

  const handleLogout = () => {
    console.log("handleLogout");
    logout();
    disconnect();
  };

  if (!ready) {
    return (
      <button className="bg-gray-600 text-white px-8 py-2 rounded-lg font-medium transition-colors w-32 cursor-not-allowed">
        Loading...
      </button>
    );
  }

  if (authenticated && user) {
    return (
      <button 
        onClick={handleLogout}
        className="bg-primary-dark hover:bg-primary text-white px-4 py-2 rounded-lg font-medium transition-colors w-40"
      >
        {user.wallet?.address ? 
          `${user.wallet.address.slice(0, 6)}...${user.wallet.address.slice(-4)}` : 
          'Connected'
        }
      </button>
    );
  }

  return (
    <button 
      onClick={handleLogin}
      className="bg-primary-dark hover:bg-primary text-white px-8 py-2 rounded-lg font-medium transition-colors w-32"
    >
      Connect
    </button>
  );
}
