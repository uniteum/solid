---
layout: page
title: Protocol
permalink: /protocol
---

This page describes how the Solid protocol works, the economic rules it enforces, and the design choices behind it.

Solid is intentionally small. Its behavior is defined by a handful of invariants that apply to every Solid equally.

## What is a Solid?

A **Solid** is an ERC-20 token paired with a permanent, self-contained trading pool.

Each Solid:
- has a fixed total supply
- has its own pool backed by the network’s native currency
- can always be bought or sold against that pool
- has no owner, admin, or upgrade path

Once a Solid is made, its rules cannot change.

All Solids share the same logic. Differences between Solids are limited to name, symbol, and pool state.

---

## Making a Solid

New Solids are made using the `make(name, symbol)` function.

Making a Solid is not minting in the traditional sense:
- there is no privileged issuer
- no allocation is reserved for the maker
- no tokens are granted for free

When a Solid is made:
- 100% of its supply is placed into its trading pool
- the pool is initialized with both real and virtual reserves
- a fair starting price and a permanent price floor are established

The maker participates in the market the same way as anyone else: by buying from the pool.

This is why the protocol uses the word **make** rather than *create*.

---

## Tokenomics and economic invariants

Solid does not define value. It defines constraints.

Every Solid follows the same economic rules:

### Always tradeable

Each Solid has its own pool backed by the network’s native currency.

Buying and selling never requires:
- an external exchange
- a counterparty
- a market maker
- a governance decision

Liquidity is built in, not negotiated.

---

### Fair from the start

At initialization:
- the entire supply is in the pool
- no participant has an informational or allocation advantage

This avoids the asymmetries common in token launches, pre-mints, or airdrops.

---

### Permanent price floor

Each pool includes a **virtual reserve** in addition to its real reserve.

The virtual reserve ensures:
- the price asymptotically approaches zero
- but never reaches it
- regardless of how many tokens are sold

This means:
- Solids can lose value
- but they cannot become worthless

The virtual reserve does not inject value into the system.  
It reshapes the pricing curve.

---

## Pool design

Each Solid pool combines two components:

- **Real reserve**  
  The actual native currency held by the pool.

- **Virtual reserve**  
  A fixed, non-withdrawable quantity used only for pricing.

The pool uses a continuous pricing function that:
- allows unrestricted buying and selling
- reflects supply and demand
- preserves a minimum value per token

The virtual reserve:
- cannot be drained
- does not belong to anyone
- exists only to enforce the invariant

There is no mechanism to remove the price floor once a Solid is made.

---

## Cloning and shared logic

All Solids are deployed as minimal clones of a single implementation.

This design choice ensures:

- identical behavior across all Solids
- a small, auditable code surface
- predictable gas costs
- consistent economic guar
