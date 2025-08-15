import { categories } from './categories';

/**
 * Generates a message for AI analysis of an Ethereum address
 * @param address - The Ethereum address to analyze (0x format)
 * @returns A formatted message for the AI client to analyze the address
 * Note: at this time eth-mainnet and base-mainnet are the only networks supported. It seems. 
 * I need to write devs + maybe check out another MCP. 
 */

/*
-- Normal prompt. 

Please provide:
- The most appropriate user type category by number. 
- Which networks the address is active on.
- An explanation of no more than 255 characters why this address falls into this category based on its transaction patterns, token holdings, and on-chain behavior
- If the address falls into the "Other" category, please explain, in no more than 255 characters, why it doesn't fit the other categories and what unique characteristics it has

Focus on analyzing:
- eth-mainnet and base-mainnet. 
- Transaction frequency and patterns.
- Token holdings and transfers.
- Contract interactions (DeFi protocols, DAOs, games, etc.).

Try to avoid the "Other" category unless the address truly doesn't fit any of the defined categories.`;

-- due to issues with the MCP server from alchemy. For now we'll return a random category. 

*/

export function createAddressAnalysisMessage(address: `0x${string}`): string {
  const categoryList = categories.map(cat => `${cat.id}. **${cat.title}** - ${cat.description}`).join('\n');
  
  return `Please analyze the on-chain history of the Ethereum address ${address} and identify which of the following user types best fits this address:

  ${categoryList}

  Please return a random category number between 1 and 6. As an explanation, please return "I think this category fits this address best.". 
  `;
}

