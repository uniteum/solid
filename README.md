# Solid

Solid is a constant-product AMM protocol on Ethereum where Solid tokens are traded against ETH with deterministic deployment.

## Deployed Contracts

### Mainnet
- **NOTHING (Proto-factory)**: [0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE](https://etherscan.io/token/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#code){:target="_blank"}

## Overview

Solid is a constant-product AMM where:
- Each Solid token is a unique ERC-20 with built-in ETH liquidity pool
- Tokens are created via a factory pattern with deterministic addresses (CREATE2)
- Initial supply is 10 mols (6.02214076e24 tokens)
- Supply is dynamic: condense mints new tokens, vaporize burns tokens for ETH
- Makers receive 50% of supply, 50% goes to the liquidity pool
- Buy/sell operations use constant-product formula (x * y = k)

For comprehensive documentation, see [CLAUDE.md](CLAUDE.md).

## Quick Start

```bash
# Clone and install
git clone git@github.com:uniteum/solid.git
cd solid

# Build
forge build

# Test
forge test
```

## Environment Setup

### Environment Variables

Set these in your `.bashrc` or `.zshrc`:

```bash
# Required for deployment (keep secure!)
export tx_key=<YOUR_PRIVATE_WALLET_KEY>
export ETHERSCAN_API_KEY=<YOUR_ETHERSCAN_API_KEY>

# Chain selection (optional)
export chain=11155111  # Sepolia testnet
# export chain=1       # Ethereum mainnet
# export chain=8453    # Base
# export chain=137     # Polygon
```

Get your ETHERSCAN_API_KEY at [Etherscan](https://etherscan.io/myaccount).

## Development

### Build

```bash
forge build
```

### Test

```bash
# Run all tests
forge test

# Run specific test
forge test --match-test testForgeSimple

# Run with gas report
forge test --gas-report

# Run with verbosity
forge test -vvv
```

### Format

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

## Deployment

### Deploy to Testnet (Sepolia)

```bash
chain=11155111
forge script script/Solid.sol -f $chain --private-key $tx_key --broadcast --verify --delay 10 --retries 10
```

## Documentation

- [CLAUDE.md](CLAUDE.md) - Comprehensive protocol documentation
- [Foundry Book](https://book.getfoundry.sh/) - Foundry development framework

## Security

This codebase uses:
- Solidity 0.8.30+ with built-in overflow checks
- EIP-1153 transient storage for reentrancy protection
- Deterministic CREATE2 deployments

See [CLAUDE.md](CLAUDE.md) for detailed security considerations.
