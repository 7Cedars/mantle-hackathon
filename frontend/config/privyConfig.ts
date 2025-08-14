export const privyConfig = {
  appId: process.env.NEXT_PUBLIC_PRIVY_APP_ID || '',
  config: {
    loginMethods: ['email', 'wallet'],
    appearance: {
      theme: 'dark',
      accentColor: '#6366f1',
      showWalletLoginFirst: true,
    },
    supportedChains: [
      {
        id: 11155111, // Sepolia
        name: 'Sepolia',
        network: 'sepolia',
        nativeCurrency: {
          name: 'Sepolia Ether',
          symbol: 'SEP',
          decimals: 18,
        },
        rpcUrls: {
          default: {
            http: [process.env.NEXT_PUBLIC_ALCHEMY_SEPOLIA_HTTPS || ''],
          },
          public: {
            http: [process.env.NEXT_PUBLIC_ALCHEMY_SEPOLIA_HTTPS || ''],
          },
        },
        blockExplorers: {
          default: {
            name: 'Sepolia Etherscan',
            url: 'https://sepolia.etherscan.io',
          },
        },
      },
      {
        id: 5003, // Mantle Sepolia Testnet
        name: 'Mantle Sepolia Testnet',
        network: 'mantle-sepolia-testnet',
        nativeCurrency: {
          name: 'Mantle Sepolia Testnet',
          symbol: 'MNT',
          decimals: 18,
        },
        rpcUrls: {
          default: {
            http: [process.env.NEXT_PUBLIC_ALCHEMY_MANTLE_SEPOLIA_HTTPS || ''],
          },
          public: {
            http: [process.env.NEXT_PUBLIC_ALCHEMY_MANTLE_SEPOLIA_HTTPS || ''],
          },
        },
        blockExplorers: {
          default: {
            name: 'Mantle Sepolia Testnet Explorer',
            url: 'https://explorer.sepolia.mantle.xyz',
          },
        },
      },
    ],
  },
};
