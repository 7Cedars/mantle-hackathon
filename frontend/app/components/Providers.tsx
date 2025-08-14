'use client';

import { PrivyProvider } from '@privy-io/react-auth';
import { PrivyWagmiConnector } from '@privy-io/wagmi-connector';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider } from 'wagmi';
import { privyConfig } from '../../config/privyConfig';
import { wagmiConfig } from '../../config/wagmiConfig';
import { useState } from 'react';

export default function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());

  return (
    <PrivyProvider config={privyConfig}>
      <PrivyWagmiConnector wagmiChainsConfig={wagmiConfig}>
        <WagmiProvider config={wagmiConfig}>
          <QueryClientProvider client={queryClient}>
            {children}
          </QueryClientProvider>
        </WagmiProvider>
      </PrivyWagmiConnector>
    </PrivyProvider>
  );
}
