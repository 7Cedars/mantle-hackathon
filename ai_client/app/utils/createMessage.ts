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



-- due to issues with the MCP server from alchemy. For now we'll return a random category. 

*/

export function createAddressAnalysisMessage(address: `0x${string}`): string {
  // const categoryList = categories.map(cat => `${cat.id}. **${cat.title}** - ${cat.description}`).join('\n');
  const categoryList = categories.map(cat => `${cat.id}. ${cat.title}`).join('\n');
  
  return `Please analyze the on-chain history of the Ethereum address ${address} over the last six months and identify which of the following user types best fits this address:

    ${categoryList}

    Limit any queries to the last 6 months and to maximum 50 of the most recent transactions on eth-mainnet. 

    IMPORTANT: You must respond with a valid JSON object containing:
    - "category": A number between 1 and ${categories.length} representing the best matching category
    - "explanation": A brief explanation (max 255 characters) of why this address fits the chosen category

    Example response format:
    {
      "category": 3,
      "explanation": "This address shows frequent DeFi interactions with multiple protocols."
    }`;
}

