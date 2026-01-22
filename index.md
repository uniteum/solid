---
layout: home
title: Home
nav_order: 1
---

# Solid Protocol

Solid is a universally compatible Ethereum token with a uniquely powerful set of properties:

- **Self-liquifying** - Each Solid contains its own ETH liquidity pool with automatic market making
- **Deterministic** - Token addresses are predictable via CREATE2 based on name and symbol
- **Fair Launch** - No pre-mine, no team allocation - 100% of supply goes to the liquidity pool
- **Price Floor** - Virtual 1 ETH ensures tokens always have minimum value
- **Permissionless** - Anyone can create new Solids for free

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
