# <div align="center">Mantle Hackathon Project</div>



### <div align="center">Mantle Hackathon</div>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/7Cedars/mantle_hackathon"> 
    <img src="frontend/public/bg-circular.png" alt="Mantle Hackathon" width="240" height="240" style="border-radius: 50%; object-fit: cover; display: block; margin: 0 auto;">
  </a>

<h3 align="center">Powers</h3>
  <p align="center">
    An AI-powered cross-chain address analysis system that integrates with the Powers governance protocol  
    <br />
    <!--NB: TO DO -->  
    <a href="/contracts">Solidity protocol</a> ·
    <a href="https://sepolia.mantlescan.xyz/address/0xe9D450BBcE3f1c4524FcAC0190C9F75b6c67833B">Proof of Concept (mantle)</a> ·
    <a href="https://mantle-ai-powers.vercel.app/">Live Demo</a>
  </p>
</div>

<div align="center">
  For an introduction into the protocol, see
   <a href="https://www.tella.tv/video/powers-1-aijc"><b> the 2 minute project pitch</b>. </a>
</div>

## About

This project demonstrates a sophisticated cross-chain architecture that combines AI analysis with blockchain governance. It analyzes user wallet addresses across multiple chains, categorizes their on-chain behavior, and assigns appropriate governance roles through the Powers protocol on Mantle Network.

## Use Cases

The system enables three key patterns that solve common DAO and governance challenges:

**🔍 Cross-Chain Identity Analysis**: Analyze user behavior across multiple blockchain networks to create comprehensive user profiles. The AI agent examines transaction history, DeFi interactions, NFT holdings, and social patterns to categorize users into meaningful governance roles.

**🌐 Cross-Chain Communication**: Leverage Chainlink CCIP to enable secure, trustless communication between Mantle Network and other EVM chains. This allows the system to gather data from multiple sources while maintaining security and decentralization.

**⚡ AI-Enhanced Governance**: Integrate AI analysis with the Powers governance protocol to automatically assign roles based on user behavior patterns. This creates a more dynamic and responsive governance system that adapts to user activity.

## Deploy locally

### Prerequisites

1. **Install Foundry** - Required for smart contract development  
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Install Node.js dependencies**  
   ```bash
   yarn install
   cd frontend && yarn install
   cd ../ai_client && yarn install
   ```

### Setup and Deployment

1. **Clone and setup the repository**  
   ```bash
   git clone <repository-url>
   cd mantle-hackathon
   ```

2. **Configure environment variables**  
   ```bash
   cp contracts/.env.example contracts/.env
   cp frontend/.env.example frontend/.env
   cp ai_client/.env.example ai_client/.env
   ```
   
   Fill in the required environment variables for RPC endpoints, API keys, and contract addresses.

3. **Start local development chain**  
   ```bash
   anvil
   ```

4. **Deploy contracts**  
   ```bash
   cd contracts
   make anvilDeployAll
   ```
   This deploys all contracts to your local Anvil chain.

5. **Start the AI client**  
   ```bash
   cd ai_client
   yarn dev
   ```

6. **Start the frontend application**  
   ```bash
   cd frontend
   yarn dev
   ```

7. **Access the application**  
   - Frontend: Open your browser and navigate to `http://localhost:3000`
   - AI Client: Available at `http://localhost:3001`
   - Select "Anvil" from the chain dropdown for local development

## Address Analysis System Architecture Flow

The system implements a sophisticated cross-chain architecture that combines AI analysis with blockchain governance:

```mermaid
sequenceDiagram
    participant User as 👤 User
    participant UI as 🖥️ Frontend UI
    participant API as 🔌 API Layer
    participant AA as 📋 AddressAnalysis.sol<br/>(Mantle)
    participant Router as 🌐 CCIP Router
    participant AICP as 🤖 AiCCIPProxy.sol<br/>(Sepolia)
    participant AI as 🧠 AI Agent<br/>(Vercel)
    participant Powers as ⚡ Powers Protocol

    Note over User, Powers: Address Analysis Request Flow

    %% Step 1: User initiates request
    User->>UI: Clicks "Claim" button
    UI->>API: POST /api/address-analysis<br/>{address: userAddress}
    
    %% Step 2: API processes and calls contract
    API->>AA: handleRequest(caller, powers, lawId, calldata, nonce)
    Note right of AA: Creates actionId and stores<br/>pending request
    
    %% Step 3: AddressAnalysis triggers CCIP
    AA->>AA: _replyPowers() called
    AA->>Router: ccipSend(destinationChainSelector, evm2AnyMessage)
    Note right of AA: Message contains:<br/>- receiver: AiCCIPProxy address<br/>- data: caller address<br/>- feeToken: LINK
    
    %% Step 4: CCIP Router forwards to Sepolia
    Router->>AICP: _ccipReceive(any2EvmMessage)
    Note right of AICP: Decodes caller address<br/>from message data
    
    %% Step 5: AiCCIPProxy calls AI Agent
    AICP->>AI: HTTP POST /api/analyze<br/>{address: callerAddress}
    Note right of AI: AI analyzes transaction<br/>history and categorizes user
    
    %% Step 6: AI Agent responds with analysis
    AI->>AICP: {category: number, explanation: string}
    Note right of AICP: Encodes response for<br/>cross-chain return
    
    %% Step 7: AiCCIPProxy sends response back via CCIP
    AICP->>Router: ccipSend(sourceChainSelector, responseMessage)
    Note right of AICP: Response contains:<br/>- category<br/>- explanation
    
    %% Step 8: CCIP Router forwards back to Mantle
    Router->>AA: _ccipReceive(any2EvmMessage)
    Note right of AA: Decodes analysis results<br/>and stores in addressAnalyses mapping
    
    %% Step 9: AddressAnalysis fulfills Powers protocol
    AA->>Powers: fulfill(lawId, actionId, targets, values, calldatas)
    Note right of Powers: Assigns role based on<br/>category to user address
    
    %% Step 10: Frontend receives completion
    API->>UI: Analysis complete<br/>{category, explanation, roleId}
    UI->>User: Display results and<br/>assigned powers

    Note over User, Powers: Flow Complete - User has been analyzed and assigned powers
```

### System Components

**🔗 Cross-Chain Communication**
- **Mantle → Sepolia**: CCIP Router handles cross-chain message passing
- **LINK Tokens**: Used for paying CCIP fees
- **Message Encoding**: ABI encoding for contract-to-contract communication

**🧠 AI Analysis Process**
1. **Address Input**: User's wallet address
2. **Transaction History**: AI fetches and analyzes on-chain activity
3. **Categorization**: Assigns one of 7 categories (DeFi, Gaming, Social, etc.)
4. **Explanation**: Provides reasoning for the categorization

**⚡ Powers Protocol Integration**
- **Role Assignment**: Category becomes roleId in Powers protocol
- **Governance Rights**: User gains specific powers based on their category
- **On-Chain Verification**: All assignments are recorded on Mantle blockchain

## Important files and folders

```
.
├── contracts/         # Smart contract development
│   ├── src/          # Solidity contracts and interfaces
│   │   ├── AddressAnalysis.sol      # Main analysis contract on Mantle
│   │   ├── AiCCIPProxy.sol          # CCIP proxy for AI integration
│   │   ├── AiProxy.sol              # AI service proxy
│   │   ├── CCIPSendReceive.sol      # CCIP sender/receiver contracts
│   │   ├── CCIPReceiveSend.sol      # Cross-chain communication
│   │   ├── abstracts/               # Abstract contract implementations
│   │   ├── interfaces/              # Contract interfaces
│   │   └── libraries/               # Shared libraries
│   ├── test/         # Foundry test files
│   ├── script/       # Deployment scripts
│   ├── broadcast/    # Deployment artifacts
│   └── foundry.toml  # Foundry configuration
│
├── frontend/         # Next.js dApp workspace
│   ├── app/          # Next.js app router pages and components
│   ├── components/   # Reusable React components
│   ├── config/       # Configuration files and ABIs
│   ├── hooks/        # Custom React hooks
│   ├── public/       # Static assets for the dApp
│   ├── utils/        # Utility functions
│   └── package.json  # Frontend dependencies
│
├── ai_client/        # AI analysis service
│   ├── app/          # Next.js API routes
│   ├── ai_context/   # AI prompt templates and context
│   ├── components/   # AI service components
│   └── package.json  # AI service dependencies
│
├── .gitmodules       # Git submodule configuration
└── README.md         # This file
```

## Built With

### Smart Contracts
- **Solidity 0.8.26** - Smart contract development
- **Foundry 0.2.0** - Development framework
- **OpenZeppelin 5.0.2** - Security libraries
- **Chainlink CCIP** - Cross-chain communication
- **Powers Protocol** - Governance framework

### Frontend
- **React 18** - UI framework
- **NextJS 14** - Full-stack framework
- **Tailwind CSS** - Styling
- **Wagmi / Viem** - Ethereum interactions
- **Privy.io** - Authentication

### AI Service
- **Google Gemini** - AI analysis engine
- **Model Context Protocol** - AI integration
- **Next.js API Routes** - Backend services

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

## Contact

Seven Cedars - [Github profile](https://github.com/7Cedars) - cedars7@proton.me
