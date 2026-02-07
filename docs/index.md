---
layout: home
title: Home
nav_order: 1
---

# Solid Protocol

Solid lets anyone create a token that's instantly tradeable, backed by real value, and fully owned by no one.

There's no launch process. No exchange listing. No middleman. You pick a name and a symbol, and the protocol does the rest — your token gets its own trading pool, a fair starting price, and a built-in price floor, all in a single transaction.

## What can you do with it?

Solid is a building block. The protocol doesn't tell you *what* to create — it just makes certain kinds of value transfer simple, transparent, and trustworthy.

Here are some things people are already exploring:

- **Personal gift certificates** — Back a token with real currency and send it to friends. The trading curve gently encourages them to actually use it, without deadlines or penalties.
- **Game currencies** — Model energy, life, time, and reputation as real economic resources instead of arbitrary numbers.

These are just the beginning. See [Use Cases]({{ site.baseurl }}/use-cases) for the full stories and emerging ideas.

## Why it works

Every Solid token has a few properties that make it different from most tokens:

- **Always tradeable.** Each token has its own pool backed by the network's native currency. You can buy or sell at any time — no exchange or counterparty needed.
- **Fair from the start.** When a token is created, 100% of the supply goes into the trading pool. The creator doesn't get free tokens — they buy in like everyone else.
- **Price floor built in.** The pool includes a virtual reserve, which means tokens always have a minimum value. The price can go up, but it can never collapse to zero.
- **No one controls it.** Once created, a Solid can't be frozen, modified, or revoked. The rules are set by math, not by an operator.
- **Anyone can create one.** Making a new Solid is inexpensive and permissionless. You don't need a custom app — you can do it directly through a block explorer.

## Try it

You can interact with any Solid directly on [Etherscan](https://etherscan.io){:target="_blank"} or [Blockscout](https://eth.blockscout.com){:target="_blank"} — no special interface required.

The links below point to [Uniteum 1 (1)](https://etherscan.io/token/{{site.data.solids.1.address}}){:target="_blank"} as an example. To work with a different Solid, just navigate to that token's page on the block explorer.

### Create and trade

| Action | What it does |
|:-------|:-------------|
| [make(name, symbol)](https://etherscan.io/token/{{site.data.solids.NOTHING.address}}#writeContract#F3){:target="_blank"} | Create a new Solid with your chosen name and symbol |
| [buy()](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F2){:target="_blank"} | Send native currency to receive tokens from the pool |
| [sell(amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F4){:target="_blank"} | Return tokens to the pool and receive native currency |
| [sellFor(solid, amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F5){:target="_blank"} | Swap one Solid for another in a single step |

### Check prices and status

| Action | What it does |
|:-------|:-------------|
| [buys(ethAmount)](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F5){:target="_blank"} | Preview how many tokens you'd get for a given amount |
| [sells(amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F10){:target="_blank"} | Preview how much you'd receive for selling tokens |
| [sellsFor(solid, amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F11){:target="_blank"} | Preview a Solid-to-Solid swap |
| [pool()](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F9){:target="_blank"} | See the current token and currency balances in the pool |
| [made(name, symbol)](https://etherscan.io/token/{{site.data.solids.NOTHING.address}}#readContract#F7){:target="_blank"} | Check if a Solid already exists and find its address |

If you'd like to support continued development of this protocol, buying some [Uniteum 1]({{ site.baseurl }}/uniteum-1) is a simple way to do so.

## Resources

- [GitHub Repository](https://github.com/uniteum/solid)
- [Use Cases]({{ site.baseurl }}/use-cases)
