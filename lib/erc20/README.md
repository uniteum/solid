# ERC20

Minimal ERC20 implementation extracted from OpenZeppelin Contracts.

## Overview

This is a lightweight port of OpenZeppelin's ERC20 token standard (v5.3.0), stripped down to core functionality. Part of the Uniteum library collection alongside [ierc20](https://github.com/uniteum/ierc20) and [clones](https://github.com/uniteum/clones).

## Features

- **Standard ERC20**: Full implementation of the ERC20 token standard
- **Minimal Dependencies**: Only depends on `ierc20` for interfaces and errors
- **Gas Optimized**: Inherits OpenZeppelin's gas optimizations
- **Solidity 0.8.30**: Modern Solidity with native overflow protection

## Installation

### Foundry

```bash
forge install uniteum/erc20
```

### Git Submodule

```bash
git submodule add https://github.com/uniteum/erc20 lib/erc20
```

## Usage

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "erc20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("My Token", "MTK") {
        _mint(msg.sender, 1_000_000e18);
    }
}
```

## What's Included

### ERC20.sol
Core ERC20 implementation with:
- `transfer()`, `transferFrom()`, `approve()`
- `balanceOf()`, `totalSupply()`, `allowance()`
- `name()`, `symbol()`, `decimals()`
- Internal `_mint()`, `_burn()`, `_transfer()`, `_approve()` helpers
- Customizable `_update()` hook for transfer logic

### Context.sol
Minimal context abstraction providing:
- `_msgSender()` - Returns `msg.sender`
- `_msgData()` - Returns `msg.data`
- Meta-transaction support via override

## Key Design Decisions

**Abstract Contract**: ERC20 is abstract - you must inherit and add supply mechanism via `_mint()`.

**Infinite Allowance**: Uses `type(uint256).max` as infinite approval (doesn't decrease on `transferFrom`).

**Gas Optimization**: `transferFrom` skips emitting `Approval` events when allowance doesn't change.

**Customization Point**: Override `_update()` for custom transfer logic (fees, hooks, etc).

## Dependencies

- [ierc20](https://github.com/uniteum/ierc20) - Interfaces (`IERC20`, `IERC20Metadata`) and errors (`IERC20Errors`)

## Differences from OpenZeppelin

This port removes:
- Extensions (ERC20Burnable, ERC20Pausable, etc)
- Permit/EIP-2612 support
- Flash minting
- Votes/governance features
- Extensive documentation and examples

What remains is the core ERC20 implementation suitable for basic token contracts and as a dependency for other protocols.

## License

MIT License - Copyright (c) 2026 Uniteum

Based on OpenZeppelin Contracts (MIT License)

## Related Libraries

- [ierc20](https://github.com/uniteum/ierc20) - ERC20 interfaces and errors
- [clones](https://github.com/uniteum/clones) - Minimal proxy deployment (EIP-1167)
- [imob](https://github.com/uniteum/imob) - Mob multisig interface

## Version

Ported from OpenZeppelin Contracts v5.3.0

Solidity: ^0.8.30
