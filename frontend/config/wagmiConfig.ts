import { createConfig, http, webSocket } from '@wagmi/core'
import { injected, coinbaseWallet } from '@wagmi/connectors'
import { foundry, sepolia, mantleSepoliaTestnet } from '@wagmi/core/chains' 

// [ = preferred ]
const isLocalhost = typeof window !== 'undefined' && window.location.hostname === 'localhost';

export const wagmiConfig = createConfig({
  chains: [
    sepolia, 
    mantleSepoliaTestnet,
    ...(isLocalhost ? [foundry] : [])
  ],
  // batch: { multicall: true }, 
  connectors: [injected(), coinbaseWallet()],
  transports: {
    [sepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_SEPOLIA_HTTPS), 
    [mantleSepoliaTestnet.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_MANTLE_SEPOLIA_HTTPS),
    // [baseSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_BASE_SEPOLIA_HTTPS),
    [foundry.id]: http("http://localhost:8545"),   
  },
  ssr: true,
  // storage: createStorage({
  //   storage: cookieStorage
  // })
})