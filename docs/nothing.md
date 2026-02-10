---
layout: page
title: NOTHING
permalink: /nothing
---

**NOTHING** is the canonical implementation contract for the Solid protocol.

All Solids are deployed as minimal proxy clones of NOTHING.

## What NOTHING is

NOTHING is an **ERC-20 implementation contract** that defines the complete on-chain behavior of a Solid.

It is deployed once and never used directly as a user-facing token.  
Instead, it serves as the **proto-implementation** from which every Solid is made.

When a new Solid is made, the protocol:

1. deploys an **ERC-1167 minimal proxy** that delegates to NOTHING  
   ([EIP-1167 specification](https://eips.ethereum.org/EIPS/eip-1167))
2. initializes the clone with a name and symbol
3. initializes its pool state

From that point on, the clone is an independent Solid with its own storage, balances, and trading pool.

---

## Why everything is a clone of NOTHING

Using NOTHING as the shared implementation ensures:

- identical behavior across all Solids
- a minimal and auditable code surface
- uniform economic guarantees
- no special cases or privileged logic

Each Solid has:
- its own independent state
- its own pool and balances

But **no Solid has its own logic**.

There is exactly one place where Solid behavior is defined: NOTHING.

---

## ERC-1167 and shared logic

Solids use the standard **ERC-1167 minimal proxy pattern**.

- Specification:  
  [https://eips.ethereum.org/EIPS/eip-1167](https://eips.ethereum.org/EIPS/eip-1167)
- Common implementation:  
  [https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones)

This pattern means:

- runtime code is shared
- storage is per-Solid
- gas costs are predictable and low
- behavior cannot drift between Solids

Because all Solids delegate to NOTHING:
- fixes or upgrades are impossible without deploying a new protocol
- existing Solids remain forever governed by the same rules

This irreversibility is intentional.

---

## NOTHING and irreversibility

NOTHING has:
- no owner
- no admin
- no upgrade mechanism

Because all Solids derive their behavior from NOTHING, this guarantees that:

- no Solid can be individually upgraded
- no Solid can be patched after the fact
- no Solid can be subtly altered via governance

Trust is not placed in operators or processes.  
It is embedded in the implementation itself.

---

## NOTHING as canonical absence

In addition to being the implementation contract, NOTHING also serves as a canonical reference for absence within the protocol.

Conceptually:

- before a Solid exists, it is NOTHING
- after it is made, it is no longer NOTHING

The protocol can therefore:

- check whether a name or symbol already maps to a Solid
- expose existence checks directly on-chain
- avoid implicit nulls or zero-address sentinels

Absence is represented explicitly, using a real contract with a defined meaning.

---

## Why not use the zero address?

The zero address is a convention, not a concept.

It has no semantics, no behavior, and no identity.

By contrast, NOTHING:

- has a name
- has a real address
- has a defined role in the protocol
- can be referenced, linked, and inspected

This makes the protocol easier to understand and harder to misuse.

---

## NOTHING is not a user token

NOTHING is not intended to be:

- traded
- promoted
- or treated as a value-bearing asset

It exists so that other Solids can exist.

Its purpose is structural, not economic.

---

## Why the name NOTHING

The name is deliberate.

NOTHING is:

- the thing from which all Solids are made
- the reference state before anything exists
- the implementation that is never itself instantiated as a real economy

There is no hidden factory.  
There is no privileged constructor.

Everything begins from NOTHING.
