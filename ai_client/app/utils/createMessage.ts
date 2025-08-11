/**
 * Generates a message for AI analysis of an Ethereum address
 * @param address - The Ethereum address to analyze (0x format)
 * @returns A formatted message for the AI client to analyze the address
 * Note: at this time eth-mainnet and base-mainnet are the only networks supported. It seems. 
 * I need to write devs + maybe check out another MCP. 
 */
export function createAddressAnalysisMessage(address: `0x${string}`): string {
  return `Please analyze the on-chain history of the Ethereum address ${address} and identify which of the following user types best fits this address:

1. **Large Token Holder** - Address holds significant amounts of tokens, possibly a whale or institutional investor
2. **Active Governance Participant** - Address actively participates in DAO governance, voting, or proposal creation
3. **DeFi User** - Address engages in DeFi activities like lending, borrowing, yield farming, or trading
4. **Gaming User** - Address participates in blockchain games, NFTs, or gaming-related transactions
5. **Social User** - Address engages in social platforms, content creation, or community activities
6. **Institutional** - Address shows patterns typical of institutional investors, exchanges, or large organizations
7. **Other** - Address doesn't clearly fit into the above categories

Please provide:
- The most appropriate user type category by number. 
- A detailed explanation of why this address falls into this category based on its transaction patterns, token holdings, and on-chain behavior
- Which networks the address is active on.
- If the address falls into the "Other" category, please explain why it doesn't fit the other categories and what unique characteristics it has

Focus on analyzing:
- eth-mainnet and base-mainnet. 
- Transaction frequency and patterns.
- Token holdings and transfers.
- Contract interactions (DeFi protocols, DAOs, games, etc.).
- Gas usage patterns.
- Time-based activity patterns.
- Interaction with specific platforms or protocols.

Try to avoid the "Other" category unless the address truly doesn't fit any of the defined categories.`;
}

/**
 * Interface for the expected AI response structure
 */
export interface AddressAnalysisResponse {
  category: number;
  explanation: string;
  confidence: number;
  keyEvidence: string[];
}
