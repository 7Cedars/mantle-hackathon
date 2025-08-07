// Alchemy MCP Server Integration
// This file provides integration with Alchemy's blockchain APIs

export interface AlchemyConfig {
  apiKey: string;
  rpcUrl: string;
  network: 'mainnet' | 'sepolia' | 'arbitrum' | 'polygon' | 'mantle' | 'mantle-testnet';
}

export interface TokenPrice {
  symbol: string;
  price: number;
  timestamp: number;
}

export interface TokenBalance {
  contractAddress: string;
  symbol: string;
  balance: string;
  decimals: number;
}

export interface NFTMetadata {
  contractAddress: string;
  tokenId: string;
  name: string;
  description: string;
  imageUrl: string;
}

// Alchemy API client class
export class AlchemyClient {
  private config: AlchemyConfig;

  constructor(config: AlchemyConfig) {
    this.config = config;
  }

  // Get token price by symbol
  async getTokenPrice(symbol: string): Promise<TokenPrice | null> {
    try {
      const response = await fetch(`${this.config.rpcUrl}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'alchemy_getTokenPrices',
          params: [symbol],
        }),
      });

      const data = await response.json();
      if (data.result && data.result.length > 0) {
        return {
          symbol: data.result[0].symbol,
          price: parseFloat(data.result[0].price),
          timestamp: Date.now(),
        };
      }
      return null;
    } catch (error) {
      console.error('Error fetching token price:', error);
      return null;
    }
  }

  // Get token balances for an address
  async getTokenBalances(address: string): Promise<TokenBalance[]> {
    try {
      const response = await fetch(`${this.config.rpcUrl}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'alchemy_getTokenBalances',
          params: [address],
        }),
      });

      const data = await response.json();
      if (data.result && data.result.tokenBalances) {
        return data.result.tokenBalances.map((token: { contractAddress: string; symbol?: string; balance: string; decimals?: number }) => ({
          contractAddress: token.contractAddress,
          symbol: token.symbol || 'Unknown',
          balance: token.balance,
          decimals: token.decimals || 18,
        }));
      }
      return [];
    } catch (error) {
      console.error('Error fetching token balances:', error);
      return [];
    }
  }

  // Get NFTs owned by an address
  async getNFTs(address: string): Promise<NFTMetadata[]> {
    try {
      const response = await fetch(`${this.config.rpcUrl}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'alchemy_getNFTs',
          params: [address],
        }),
      });

      const data = await response.json();
      if (data.result && data.result.ownedNfts) {
        return data.result.ownedNfts.map((nft: { contract: { address: string }; id: { tokenId: string }; title?: string; description?: string; media?: Array<{ gateway: string }> }) => ({
          contractAddress: nft.contract.address,
          tokenId: nft.id.tokenId,
          name: nft.title || 'Unknown',
          description: nft.description || '',
          imageUrl: nft.media?.[0]?.gateway || '',
        }));
      }
      return [];
    } catch (error) {
      console.error('Error fetching NFTs:', error);
      return [];
    }
  }

  // Get transaction history for an address
  async getTransactionHistory(address: string, limit: number = 10): Promise<Array<{ hash: string; from: string; to: string; value: string; category: string }>> {
    try {
      const response = await fetch(`${this.config.rpcUrl}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'alchemy_getAssetTransfers',
          params: [{
            fromBlock: '0x0',
            toBlock: 'latest',
            fromAddress: address,
            maxCount: limit.toString(),
            category: ['external', 'internal', 'erc20', 'erc721', 'erc1155'],
          }],
        }),
      });

      const data = await response.json();
      return data.result?.transfers || [];
    } catch (error) {
      console.error('Error fetching transaction history:', error);
      return [];
    }
  }

  // Get current gas price
  async getGasPrice(): Promise<string | null> {
    try {
      const response = await fetch(`${this.config.rpcUrl}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'eth_gasPrice',
          params: [],
        }),
      });

      const data = await response.json();
      return data.result || null;
    } catch (error) {
      console.error('Error fetching gas price:', error);
      return null;
    }
  }
}

// Create default Alchemy client instances for different networks
export const alchemyClients = {
  mainnet: new AlchemyClient({
    apiKey: process.env.ALCHEMY_API_KEY!,
    rpcUrl: process.env.ALCHEMY_RPC_URL!,
    network: 'mainnet',
  }),
  sepolia: new AlchemyClient({
    apiKey: process.env.ALCHEMY_API_KEY!,
    rpcUrl: process.env.ALCHEMY_SEPOLIA_RPC_URL!,
    network: 'sepolia',
  }),
  arbitrum: new AlchemyClient({
    apiKey: process.env.ALCHEMY_API_KEY!,
    rpcUrl: process.env.ALCHEMY_ARBITRUM_RPC_URL!,
    network: 'arbitrum',
  }),
  polygon: new AlchemyClient({
    apiKey: process.env.ALCHEMY_API_KEY!,
    rpcUrl: process.env.ALCHEMY_POLYGON_RPC_URL!,
    network: 'polygon',
  }),
  mantle: new AlchemyClient({
    apiKey: process.env.ALCHEMY_API_KEY!,
    rpcUrl: process.env.ALCHEMY_MANTLE_RPC_URL!,
    network: 'mantle',
  }),
  mantleTestnet: new AlchemyClient({
    apiKey: process.env.ALCHEMY_API_KEY!,
    rpcUrl: process.env.ALCHEMY_MANTLE_TESTNET_RPC_URL!,
    network: 'mantle-testnet',
  }),
};

// Utility function to check if Alchemy is configured
export function isAlchemyConfigured(): boolean {
  return !!process.env.ALCHEMY_API_KEY && 
         process.env.ALCHEMY_API_KEY !== 'your_alchemy_api_key_here';
} 