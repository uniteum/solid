---
layout: home
title: Home
nav_order: 1
---

# Solid Protocol

Solids are Ethereum tokens that literally sell themselves and have uniquely powerful properties:
- **Immediately Tradeable** - Each Solid contains its own ETH liquidity pool with automatic market making
- **Fair Launch** - 100% of supply goes to the liquidity pool upon creation
- **Price Floor** - Virtual 1 ETH ensures tokens always have minimum value
- **Permissionless and Inexpensive** - Anyone can make a new Solid for the cost of gas
- **Easy to Make** - Go [here](https://etherscan.io/address/{{site.data.contracts.contracts.NOTHING}}#writeContract#F3){:target="_blank"}, connect to web3, specify the name and symbol, click 'Write', and approve the transaction
- **Deterministic** - Token addresses are predictable via CREATE2 based on name and symbol

## Deployed Contracts

### Mainnet

* {% include contract.html address=site.data.contracts.contracts.NOTHING text="NOTHING" %}

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

## How It Works

Each Solid token is an ERC-20 with a built-in constant-product AMM:

1. **Create** - Call `make(name, symbol)` on any Solid to create a new one
2. **Buy** - Send ETH to `buy()` to receive Solid tokens from the pool
3. **Sell** - Call `sell(amount)` to exchange Solid tokens back for ETH

The protocol uses the constant product formula (`x * y = k`) for pricing, ensuring liquidity is always available.

## Key Properties

| Property | Value |
|:---------|:------|
| Total Supply | 6.02214076 × 10²³ (Avogadro's number) |
| Starting Price | ~602,214 solids per ETH |
| Price Floor | Guaranteed by virtual 1 ETH |
| Decimals | 18 |

## Resources

- [GitHub Repository](https://github.com/uniteum/solid)
- [Foundry Book](https://book.getfoundry.sh/)
