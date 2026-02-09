---
layout: home
title: Home
nav_order: 1
---

# Solid Protocol

**Make a token that starts fair, stays tradeable, and never goes to zero.**

Solid is a protocol for making tokens that are immediately usable as real economic objects — not promises, not IOUs, not hype vehicles.

You pick a name and a symbol.  
In a single transaction, the protocol makes the token, its trading pool, a fair starting price, and a permanent price floor.

No launch.  
No listing.  
No operator.

---

## Why this is interesting

Most tokens depend on people behaving well.
Solid tokens don’t.

Every Solid is governed entirely by on-chain rules that make certain outcomes unavoidable:

- Tokens are **always tradeable**
- Makers receive **no free allocation**
- Prices can rise, but **never collapse to zero**
- No one can freeze, pause, or rewrite the rules

This makes Solids useful as *economic building blocks*, not just speculative assets.

---

## What can you make?

Solid doesn’t prescribe meaning — it provides structure.

People are already experimenting with:

- **Personal gift certificates**  
  Tokens backed by real currency that gently encourage spending without deadlines or penalties.

- **Game currencies**  
  Energy, life, time, or reputation modeled as scarce economic resources instead of arbitrary counters.

- **Small community or experimental economies**  
  Transparent value systems with fixed rules and no central issuer.

See [Use Cases]({{ site.baseurl }}/use-cases) for full narratives and concrete examples.

---

## Why Solid works

Every Solid has the same invariant structure:

- **Always tradeable**  
  Each Solid has its own pool backed by the network’s native currency. You can buy or sell at any time — no counterparty required.

- **Fair from the start**  
  100% of the supply begins in the pool. The maker buys in like everyone else.

- **Permanent price floor**  
  A virtual reserve ensures the Solid always retains some minimum value.

- **No one controls it**  
  Once made, a Solid cannot be modified, frozen, or revoked.

- **Permissionless**  
  You don’t need a custom app. Solids can be made directly through a block explorer.

These rules are enforced by math, not governance.

---

## Try it directly on-chain

You can interact with any Solid using standard tools like  
[Etherscan](https://etherscan.io){:target="_blank"} or  
[Blockscout](https://eth.blockscout.com){:target="_blank"}.

The links below reference  
[Uniteum 1 (1)](https://etherscan.io/token/{{site.data.solids.1.address}}){:target="_blank"}  
as a live example. Any Solid works the same way.

### Make and trade

| Action | What it does |
|:-------|:-------------|
| [make(name, symbol)](https://etherscan.io/token/{{site.data.solids.NOTHING.address}}#writeContract#F3){:target="_blank"} | Make a new Solid |
| [buy()](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F2){:target="_blank"} | Buy tokens from the pool |
| [sell(amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F4){:target="_blank"} | Sell tokens back to the pool |
| [sellFor(solid, amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#writeContract#F5){:target="_blank"} | Swap one Solid for another |

### Inspect prices and state

| Action | What it shows |
|:-------|:--------------|
| [buys(ethAmount)](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F5){:target="_blank"} | Tokens received for a given input |
| [sells(amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F10){:target="_blank"} | Currency received for selling |
| [sellsFor(solid, amount)](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F11){:target="_blank"} | Preview a Solid-to-Solid swap |
| [pool()](https://etherscan.io/token/{{site.data.solids.1.address}}#readContract#F9){:target="_blank"} | Current pool balances |
| [made(name, symbol)](https://etherscan.io/token/{{site.data.solids.NOTHING.address}}#readContract#F7){:target="_blank"} | Check if a Solid already exists |

If you’d like to support continued development, acquiring some  
[Uniteum 1]({{ site.baseurl }}/uniteum-1)  
is a simple way to do so.

---

## Resources

- [GitHub Repository](https://github.com/uniteum/solid)
- [Use Cases]({{ site.baseurl }}/use-cases)
