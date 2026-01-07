# IERC20 Interfaces

Standalone ERC-20 interface files for Solidity projects.

## Purpose

This repository provides minimal, dependency-free ERC-20 interfaces. Use these to reduce external dependencies in your Solidity projects.

## Contents

- **[IERC20.sol](IERC20.sol)** - Core ERC-20 interface (v5.1.0)
- **[IERC20Metadata.sol](IERC20Metadata.sol)** - Optional metadata extension (v5.1.0)

## Source

These files are copied from [OpenZeppelin Contracts v5.1.0](https://github.com/OpenZeppelin/openzeppelin-contracts) with minimal modifications:

1. Formatted with `forge fmt` (Foundry's code formatter)
2. `IERC20Metadata.sol` modified to import from `./IERC20.sol` (relative path)

## License

MIT License (same as OpenZeppelin Contracts)

## Usage

### Foundry

```bash
forge install uniteum/ierc20
```

```solidity
import {IERC20} from "ierc20/IERC20.sol";
import {IERC20Metadata} from "ierc20/IERC20Metadata.sol";
```

### Hardhat / npm

```bash
npm install @uniteum/ierc20
```

```solidity
import {IERC20} from "@uniteum/ierc20/IERC20.sol";
import {IERC20Metadata} from "@uniteum/ierc20/IERC20Metadata.sol";
```

## Why This Repository?

Instead of importing the full OpenZeppelin Contracts library (hundreds of files), you can depend on just these two interface files. This reduces:

- Dependency bloat
- Build times
- Supply chain attack surface
- Version conflicts

## Maintenance

These interfaces are stable and rarely change. Updates will only be made to track new OpenZeppelin releases or fix critical issues.

## See Also

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [ERC-20 Token Standard](https://eips.ethereum.org/EIPS/eip-20)
