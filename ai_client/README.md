# Mantle Hackathon AI Client

A TypeScript Next.js React application with Google Gemini AI integration and Alchemy blockchain data access.

## 🚀 Features

- **AI Chat Interface**: Simple and intuitive chat interface powered by Google Gemini 2.5 Pro
- **Blockchain Integration**: Alchemy MCP server integration for blockchain data access
- **Multi-Network Support**: Support for Ethereum, Arbitrum, Polygon, and Mantle networks
- **Real-time Chat**: Live chat with AI assistant
- **API Key Management**: Secure environment-based configuration
- **Responsive Design**: Modern UI with Tailwind CSS

## 🛠️ Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **AI**: Google Gemini 2.5 Pro
- **Blockchain**: Alchemy APIs
- **Package Manager**: Yarn

## 📦 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mantle-hackathon/ai_client
   ```

2. **Install dependencies**
   ```bash
   yarn install
   ```

3. **Configure environment variables**
   ```bash
   cp .env.local.example .env.local
   # Edit .env.local with your API keys
   ```

4. **Start the development server**
   ```bash
   yarn dev
   ```

5. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## 🔧 Configuration

### Environment Variables

Create a `.env.local` file in the root directory:

```bash
# Google Gemini API Configuration
GOOGLE_GEMINI_API_KEY=your_gemini_api_key_here

# Alchemy API Configuration
ALCHEMY_API_KEY=your_alchemy_api_key_here
ALCHEMY_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your_alchemy_api_key_here

# Optional: Additional Alchemy endpoints for different networks
ALCHEMY_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_alchemy_api_key_here
ALCHEMY_ARBITRUM_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/your_alchemy_api_key_here
ALCHEMY_POLYGON_RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/your_alchemy_api_key_here
ALCHEMY_MANTLE_RPC_URL=https://rpc.mantle.xyz
ALCHEMY_MANTLE_TESTNET_RPC_URL=https://rpc.testnet.mantle.xyz

# Development settings
NODE_ENV=development
NEXT_PUBLIC_APP_NAME=Mantle Hackathon AI Client
```

### Getting API Keys

1. **Google Gemini API Key**:
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Add it to your `.env.local` file

2. **Alchemy API Key**:
   - Visit [Alchemy](https://www.alchemy.com/)
   - Create an account and get your API key
   - Add it to your `.env.local` file

## 🏗️ Project Structure

```
ai_client/
├── src/
│   ├── app/                 # Next.js App Router
│   │   ├── api/            # API routes
│   │   │   └── chat/       # Chat API endpoint
│   │   └── page.tsx        # Main page
│   ├── components/         # React components
│   │   └── ChatInterface.tsx
│   └── lib/               # Utility libraries
│       ├── gemini.ts      # Gemini AI integration
│       └── alchemy.ts     # Alchemy blockchain integration
├── public/                # Static assets
├── .env.local            # Environment variables
└── package.json          # Dependencies
```

## 🧪 Available Scripts

```bash
# Development
yarn dev          # Start development server
yarn build        # Build for production
yarn start        # Start production server
yarn lint         # Run ESLint

# Type checking
yarn type-check   # Run TypeScript compiler
```

## 🔌 API Integration

### Gemini AI Integration

The app uses Google's Gemini 2.5 Pro model for AI chat functionality:

```typescript
import { generateResponse, ChatSession } from '@/lib/gemini';

const chatSession = new ChatSession();
const response = await generateResponse("Hello!", chatSession);
```

### Alchemy Blockchain Integration

The app includes Alchemy client for blockchain data access:

```typescript
import { alchemyClients } from '@/lib/alchemy';

// Get token balances
const balances = await alchemyClients.mainnet.getTokenBalances(address);

// Get NFTs
const nfts = await alchemyClients.mainnet.getNFTs(address);

// Get transaction history
const history = await alchemyClients.mainnet.getTransactionHistory(address);
```

## 🎨 UI Components

### ChatInterface

The main chat component features:

- **Real-time messaging**: Live chat with AI assistant
- **Message history**: Persistent chat history
- **Loading states**: Visual feedback during AI processing
- **Error handling**: Graceful error display
- **Connection status**: API key configuration indicators
- **Responsive design**: Works on desktop and mobile

## 🔒 Security

- API keys are stored server-side only
- Environment variables for sensitive configuration
- No client-side exposure of API keys
- Secure API routes for AI interactions

## 🚀 Deployment

### Vercel (Recommended)

1. **Connect your repository** to Vercel
2. **Add environment variables** in Vercel dashboard
3. **Deploy automatically** on push to main branch

### Manual Deployment

```bash
# Build the application
yarn build

# Start production server
yarn start
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🔗 Links

- [Next.js Documentation](https://nextjs.org/docs)
- [Google Gemini API](https://ai.google.dev/)
- [Alchemy Documentation](https://docs.alchemy.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Mantle Network](https://mantle.xyz/)

## 🆘 Support

For issues and questions:
- Check the [Next.js documentation](https://nextjs.org/docs)
- Review [Google Gemini API docs](https://ai.google.dev/docs)
- Open an issue in this repository
