---
layout: home
title: Home
nav_order: 1
---

# Solid Protocol

Solids are Ethereum tokens that literally sell themselves and have uniquely powerful properties:
- **Instantly Tradeable** - Each Solid has its own ETH liquidity pool with buy and sell functions
- **Fair Launch** - 100% of supply goes to the liquidity pool upon creation
- **Price Floor** - Virtual 1 ETH ensures tokens always have minimum value
- **Permissionless** - Anyone can make a new Solid: no exchange, operator, or custom UI is required
- **Easy to Make** - Anyone can make their own token in a few simple steps using major block explorers
- **Inexpensive** - Each token is deployed as a minimal proxy contract (clone), needing little gas
- **Deterministic** - Token addresses are predictable via CREATE2 based on name and symbol

## Deployed Contracts

### Mainnet

* {% include contract.html address=site.data.solids.NOTHING text="NOTHING" %}

## How It Works

Each Solid token is an ERC-20 with a built-in constant-product AMM:

1. **Make** - Call [make(name, symbol)](https://etherscan.io/token/{{site.data.contracts.contracts.NOTHING}}#writeContract#F3){:target="_blank"} on any Solid to create a new one
2. **Buy** - Send ETH when calling [buy()](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F2){:target="_blank"} to receive Solid tokens from the pool
3. **Sell** - Call [sell(amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F4){:target="_blank"} to exchange Solid tokens back for ETH

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
- [EIP-1167 Clones](https://eips.ethereum.org/EIPS/eip-1167)
