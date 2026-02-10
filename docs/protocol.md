---
layout: page
title: Protocol
permalink: /protocol
nav_order: 4
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

## NOTHING and the implementation

All Solids are deployed as minimal proxy clones of a single implementation contract named **NOTHING**.

NOTHING is the canonical implementation of Solid behavior:
- it defines all ERC-20 logic
- it defines pool mechanics and pricing
- it enforces all economic invariants

Individual Solids do not have their own logic contracts.  
They delegate all behavior to NOTHING while maintaining independent state.

For details on NOTHING itself, see  
[What is NOTHING?]({{ site.baseurl }}/nothing)

---

## Making a Solid

New Solids are typically made by calling the `make(name, symbol)` function on **NOTHING**.

Calling make or made on any Solid will behave identically to calling it on NOTHING. In practice, these functions are conceptually associated with NOTHING, and calling them on other Solids is supported but unconventional.

Making a Solid is not minting in the traditional sense:
- there is no privileged issuer
- no allocation is reserved for the maker
- no tokens are granted for free

When `make(name, symbol)` is called on NOTHING:

- a new Solid is deployed as a minimal clone
- 100% of its supply is placed into its trading pool
- the pool is initialized with both real and virtual reserves
- a fair starting price and a permanent price floor are established

The maker participates in the market the same way as anyone else: by buying from the pool.

This is why the protocol uses the word **make** rather than *create*.

---

## Existence checks

The protocol exposes the function `made(name, symbol)` **on NOTHING**.

This function allows anyone to determine whether a Solid with a given name and symbol already exists.

If a Solid has not been made, the lookup resolves to **NOTHING**.  
If it has been made, the lookup resolves to the address of that Solid.

This makes existence:
- explicit
- on-chain
- and inspectable via standard tools

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

All Solids are deployed as **ERC-1167 minimal proxy clones** of NOTHING.

This design ensures:

- identical behavior across all Solids
- a small, auditable code surface
- predictable gas costs
- consistent economic guarantees

Each Solid has its own independent storage, but **no Solid has its own logic**.

Behavior is fixed at the implementation level.  
If rules change, a new protocol is required.

---

## What Solid does not do

Solid is intentionally limited.

It does **not** provide:
- governance
- admin controls
- upgrade mechanisms
- oracle integrations
- guarantees of profit or stability
- protection from bad ideas

Solid enforces rules.  
It does not judge outcomes.

---

## Why this design

Solid explores a simple question:

> What kinds of economic behavior emerge when fairness, liquidity, and irreversibility are enforced at the protocol level?

By removing:
- discretionary control
- issuance privilege
- and conditional liquidity

Solid becomes a neutral substrate for experimentation.

Some Solids will be useful.  
Some will fail.  
All will follow the same rules.

That symmetry is the point.
