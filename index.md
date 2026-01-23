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

### Write Operations

1. **make** - Call [make(name, symbol)](https://etherscan.io/token/{{site.data.solids.NOTHING.address}}#writeContract#F3){:target="_blank"} on any Solid to create a new one
2. **buy** - Send ETH when calling [buy()](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F2){:target="_blank"} to receive Solid tokens from the pool
3. **sell** - Call [sell(amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F4){:target="_blank"} to exchange Solid tokens back for ETH
4. **sellFor** - Call [sellFor(solid, amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F5){:target="_blank"} to swap one Solid for another in a single transaction (no approval needed)

### Read Operations

1. **pool** - Call [pool()](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F9){:target="_blank"} to get the current pool state (Solid balance, virtual ETH balance)
2. **buys** - Call [buys(ethAmount)](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F5){:target="_blank"} to preview how many tokens you'd receive for a given ETH amount
3. **sells** - Call [sells(solidAmount)](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F10){:target="_blank"} to preview how much ETH you'd receive for selling tokens
4. **sellsFor** - Call [sellsFor(solid, amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F11){:target="_blank"} to preview a Solid-to-Solid swap
5. **made** - Call [made(name, symbol)](https://etherscan.io/token/{{site.data.solids.NOTHING}}#readContract#F7){:target="_blank"} to check if a Solid exists and get its address

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
