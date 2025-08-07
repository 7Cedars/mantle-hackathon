# Mantle Hackathon Solidity Project

A comprehensive Solidity development environment for the Mantle Hackathon, featuring Foundry, Powers Protocol integration, and OpenZeppelin contracts.

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/) - Smart contract development toolkit
- [Git](https://git-scm.com/) - Version control
- [Node.js](https://nodejs.org/) (optional) - For additional tooling

### Installation

1. **Clone and setup the repository**
   ```bash
   git clone <repository-url>
   cd mantle-hackathon/contracts
   ```

2. **Install dependencies**
   ```bash
   make install-deps
   # or
   forge install
   ```

3. **Setup environment**
   ```bash
   make setup-env
   # Edit .env with your configuration
   ```

4. **Build contracts**
   ```bash
   make build
   ```

## 📁 Project Structure

```
contracts/
├── foundry.toml          # Foundry configuration
├── Makefile              # Build and deployment commands
├── .env.example          # Environment template
├── README.md             # This file
├── src/                  # Smart contracts
│   ├── interfaces/       # Interface definitions
│   ├── libraries/        # Reusable libraries
│   ├── abstracts/        # Abstract contracts
│   └── *.sol            # Main contracts
├── test/                 # Test files
│   ├── unit/            # Unit tests
│   ├── integration/     # Integration tests
│   ├── fuzz/           # Fuzz tests
│   ├── invariant/       # Invariant tests
│   ├── fork/           # Fork tests
│   └── utils/          # Test utilities
├── script/              # Deployment scripts
├── lib/                 # Dependencies
│   ├── powers/         # Powers Protocol
│   ├── openzeppelin-contracts/ # OpenZeppelin
│   └── forge-std/      # Foundry standard library
└── out/                 # Compiled artifacts
```

## 🛠️ Available Commands

### Development Commands

```bash
# Build and test
make build              # Compile contracts
make test               # Run all tests
make test-verbose       # Run tests with verbose output
make test-fuzz          # Run fuzz tests
make test-invariant     # Run invariant tests
make coverage           # Generate coverage report
make lint               # Run linter

# Local development
make anvil              # Start local Anvil chain
make deploy-anvil       # Deploy to local chain
make clean              # Clean build artifacts
```

### Deployment Commands

```bash
# Testnet deployments
make deploy-sepolia      # Deploy to Sepolia
make deploy-mantle       # Deploy to Mantle testnet

# Verification
make verify              # Verify contracts on Etherscan

# Dry runs
make deploy-sepolia-dry  # Simulate Sepolia deployment
make deploy-mantle-dry   # Simulate Mantle deployment
```

### Advanced Commands

```bash
# Documentation
make doc                 # Generate documentation
make doc-serve          # Serve documentation

# Analysis
make gas-report          # Generate gas report
make size                # Analyze contract sizes
make security            # Security analysis

# Debugging
make debug-test TEST=testName
make trace TX_HASH=0x...
```

## 🔧 Configuration

### Foundry Configuration

The `foundry.toml` file includes:

- **Remappings**: Easy imports for Powers and OpenZeppelin
- **Compiler settings**: Optimized for gas efficiency
- **Testing configuration**: Fuzz and invariant testing setup
- **Network endpoints**: Support for multiple networks
- **Verification settings**: Etherscan integration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Required for deployment
PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=https://...
ETHERSCAN_API_KEY=...

# Optional for additional networks
MANTLE_RPC_URL=https://rpc.mantle.xyz
MANTLE_TESTNET_RPC_URL=https://rpc.testnet.mantle.xyz
```

## 🧪 Testing

### Test Types

1. **Unit Tests**: Basic functionality testing
   ```bash
   make test
   ```

2. **Fuzz Tests**: Property-based testing
   ```bash
   make test-fuzz
   ```

3. **Invariant Tests**: State consistency testing
   ```bash
   make test-invariant
   ```

4. **Fork Tests**: Integration with existing protocols
   ```bash
   make test-fork
   ```

### Test Naming Conventions

- `test_FunctionName_Condition` - Unit tests
- `testFuzz_FunctionName` - Fuzz tests
- `invariant_PropertyName` - Invariant tests
- `testFork_Scenario` - Fork tests

## 📦 Dependencies

### Powers Protocol

The [Powers Protocol](https://github.com/7Cedars/powers) is integrated for governance functionality:

```solidity
import {ILaw} from "@powers/ILaw.sol";
import {IOrganization} from "@powers/IOrganization.sol";
```

### OpenZeppelin

Latest OpenZeppelin contracts for security and standards:

```solidity
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
```

## 🚀 Deployment

### Local Development

1. Start Anvil chain:
   ```bash
   make anvil
   ```

2. Deploy contracts:
   ```bash
   make deploy-anvil
   ```

### Testnet Deployment

1. Configure environment variables
2. Deploy to testnet:
   ```bash
   make deploy-sepolia
   make deploy-mantle
   ```

### Verification

After deployment, verify contracts:
```bash
make verify CONTRACT_ADDRESS=0x... CONTRACT_NAME=MyContract CHAIN_ID=11155111
```

## 🔍 Development Workflow

### Standard Workflow

```bash
# 1. Make changes to contracts
# 2. Run tests
make test

# 3. Check linting
make lint

# 4. Build contracts
make build

# 5. Deploy (if needed)
make deploy-anvil
```

### CI/CD Workflow

```bash
# Complete CI/CD pipeline
make ci
```

## 📚 Documentation

### Generated Documentation

```bash
make doc          # Generate documentation
make doc-serve    # Serve documentation locally
```

### Code Coverage

```bash
make coverage     # Generate coverage report
make coverage-html # Generate HTML coverage report
```

## 🛡️ Security

### Best Practices

- All contracts follow CEI (Checks-Effects-Interactions) pattern
- Reentrancy protection where applicable
- Access control patterns implemented
- Comprehensive input validation
- Gas optimization considerations

### Security Analysis

```bash
make lint-high    # High severity linting
make security     # Security analysis
```

## 🤝 Contributing

1. Follow the established naming conventions
2. Write comprehensive tests for all functionality
3. Include NatSpec documentation
4. Run the full test suite before submitting
5. Follow security best practices

## 📄 License

This project is licensed under the MIT License.

## 🔗 Links

- [Foundry Book](https://book.getfoundry.sh/)
- [Powers Protocol](https://github.com/7Cedars/powers)
- [OpenZeppelin](https://openzeppelin.com/)
- [Mantle Network](https://mantle.xyz/)

## 🆘 Support

For issues and questions:
- Check the [Foundry Book](https://book.getfoundry.sh/)
- Review [Powers Protocol documentation](https://github.com/7Cedars/powers)
- Open an issue in this repository
