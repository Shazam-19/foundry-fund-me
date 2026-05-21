# Fund Me

A decentralized crowdfunding smart contract built with Solidity and Foundry, using Chainlink price feeds for real-time ETH/USD conversion.

---

## Table of Contents

- [About The Project](#about-the-project)
- [Built With](#built-with)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Run Tests](#run-tests)
  - [Deploy](#deploy)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## About The Project

FundMe is a smart contract that allows users to fund a contract with ETH, enforcing a minimum USD value using Chainlink's ETH/USD price feed. The owner can withdraw all collected funds.

Key features:
- Minimum funding threshold enforced in USD, not ETH
- Real-time price conversion via Chainlink Data Feeds
- Owner-only withdrawal
- Fully tested with Foundry (unit + integration)
- Deployable to local Anvil, Sepolia testnet, and mainnet

---

## Built With

- [Solidity](https://soliditylang.org/)
- [Foundry](https://getfoundry.sh/)
- [Chainlink Data Feeds](https://docs.chain.link/data-feeds)
- [forge-std](https://github.com/foundry-rs/forge-std)
- [foundry-devops](https://github.com/Cyfrin/foundry-devops)

---

## Project Structure

```
├── script
│   ├── DeployFundMe.s.sol      # Deployment script
│   ├── HelperConfig.s.sol      # Network config (Sepolia / Anvil)
│   └── Interactions.s.sol      # Fund & withdraw interaction scripts
├── src
│   ├── FundMe.sol              # Core contract
│   └── PriceConverter.sol      # Chainlink price conversion library
├── test
│   ├── Integration
│   │   └── InteractionsTest.t.sol
│   ├── mocks
│   │   └── MockV3Aggregator.sol
│   └── unit
│       └── FundMeTest.t.sol
├── foundry.toml                # Foundry configuration
└── Makefile                    # Deployment and test commands
```

---

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- [Git](https://git-scm.com/)
- An RPC URL (e.g. from [Alchemy](https://alchemy.com/) or [Infura](https://infura.io/))
- A funded wallet private key (for testnet deployment)
- An [Etherscan API key](https://etherscan.io/myapikey) (for contract verification)

### Installation

1. Clone the repo

```bash
git clone git@github.com:Shazam-19/foundry-fund-me.git
cd foundry-fund-me
```

2. Install dependencies

```bash
forge install
```

3. Set up your environment variables

```bash
mkdir .env
```

Then fill in your `.env`:

```
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=0xYOUR_PRIVATE_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
```

> ⚠️ Never commit your `.env` file. It is already listed in `.gitignore`.

---

## Usage

### Run Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvvv

# Run a specific test
forge test --match-test testFundUpdatesFundedDataStructure
```

### Deploy

**Local (Anvil):**

```bash
make deploy
```

**Sepolia testnet:**

```bash
make deploy-sepolia
```

---

## Roadmap

- [x] Core FundMe contract
- [x] Chainlink price feed integration
- [x] Unit and integration tests
- [x] Sepolia deployment with verification
- [ ] Frontend interface
- [ ] Multi-token support

---

## Contributing

Contributions are welcome. If you have a suggestion or find a bug, feel free to open an issue or submit a pull request.

1. Fork the project
2. Create your branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## License

Distributed under the MIT License. See `LICENSE` for more information.

---

## Acknowledgments

- [Patrick Collins / Cyfrin Updraft](https://updraft.cyfrin.io/) — course and project inspiration
- [Chainlink Docs](https://docs.chain.link/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template)