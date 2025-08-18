import { categories } from './categories';

/**
 * Generates a message for AI analysis of an Ethereum address
 * @param address - The Ethereum address to analyze (0x format)
 * @returns A formatted message for the AI client to analyze the address
 */

// Function to fetch asset transfers from Alchemy API for a specific network
async function fetchAssetTransfersForNetwork(address: string, network: string) {
  const alchemyApiKey = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY;
  
  if (!alchemyApiKey) {
    console.error("ALCHEMY_API_KEY environment variable is not set");
    return [];
  }

  // Map network names to Alchemy endpoints
  const networkEndpoints = {
    'ethereum': `https://eth-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
    'arbitrum': `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
    'optimism': `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
    'mantle': `https://mantle-mainnet.g.alchemy.com/v2/${alchemyApiKey}`
  };

  const endpoint = networkEndpoints[network as keyof typeof networkEndpoints];
  if (!endpoint) {
    console.error(`Unsupported network: ${network}`);
    return [];
  }

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "alchemy_getAssetTransfers",
        params: [
          {
            fromAddress: address,
            category: ["external", "erc20", "erc721", "erc1155"],
            maxCount: "0x32", // 50 transfers
            order: "desc"
          }
        ],
        id: 1
      })
    });

    if (!response.ok) {
      throw new Error(`Alchemy API error for ${network}: ${response.status}`);
    }

    const data = await response.json();
    console.log(`DATA for ${network}:`, data);
    return data.result?.transfers || [];
  } catch (error) {
    console.error(`Error fetching asset transfers for ${network}:`, error);
    return [];
  }
}

// Function to fetch asset transfers from all networks
async function fetchAllAssetTransfers(address: string) {
  const networks = ['ethereum', 'arbitrum', 'optimism', 'mantle'];
  const results: { [key: string]: any[] } = {};

  // Fetch data from all networks in parallel
  const promises = networks.map(async (network) => {
    const transfers = await fetchAssetTransfersForNetwork(address, network);
    return { network, transfers };
  });

  const networkResults = await Promise.all(promises);
  
  // Organize results by network
  networkResults.forEach(({ network, transfers }) => {
    results[network] = transfers;
  });

  return results;
}

export async function createAddressAnalysisMessage(address: `0x${string}`): Promise<string> {
  // Fetch asset transfers from all networks
  const allAssetTransfers = await fetchAllAssetTransfers(address);
  console.log("ALL ASSET TRANSFERS: ", allAssetTransfers);
  
  const categoryList = categories.map(cat => `${cat.id}. ${cat.title} - ${cat.description}`).join('\n');

  // Create a summary of transaction data from all networks
  const transactionSummary = Object.entries(allAssetTransfers).map(([network, transfers]) => {
    return `${network.toUpperCase()} NETWORK (${transfers.length} transfers):
${transfers.length > 0 ? JSON.stringify(transfers, null, 2) : "No recent transactions found"}`;
  }).join('\n\n');

  const message = `

    RECENT TRANSACTION DATA FROM ALL NETWORKS (Ethereum, Arbitrum, Optimism, Mantle):
    
    ${transactionSummary}

    Categories: 
    ${categoryList}

    Please analyze the above transaction data from all networks along with the address to determine the best category fit.

    Important: keep your explanation short and concise, a simple string of less than 250 characters.
    `;

  return message;
}

