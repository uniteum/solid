# Clones

> Minimal ERC-1167 proxy implementation for deterministic deployments

## Overview

This is a stripped-down version of OpenZeppelin's Clones library, focused exclusively on deterministic CREATE2-based deployments with value support. It provides gas-efficient minimal proxy (clone) deployments following the [EIP-1167](https://eips.ethereum.org/EIPS/eip-1167) standard.

## What's Included

This library contains only two functions:

1. **`cloneDeterministic(address implementation, bytes32 salt, uint256 value)`** - Deploys a minimal proxy clone to a deterministic address using CREATE2, optionally sending ETH during deployment
2. **`predictDeterministicAddress(address implementation, bytes32 salt, address deployer)`** - Computes the address where a clone will be deployed

## What's Been Removed

Compared to the full OpenZeppelin Clones library, this version omits:

- `clone()` - Non-deterministic deployment using CREATE
- `cloneDeterministic(address, bytes32)` - Zero-value overload (use the 3-parameter version with `value = 0`)
- `predictDeterministicAddress(address, bytes32)` - msg.sender overload (use the 3-parameter version explicitly)

## Usage

### Deploying a Clone

```solidity
import {Clones} from "./Clones.sol";

contract Factory {
    address public immutable implementation;

    constructor(address implementation_) {
        implementation = implementation_;
    }

    function createClone(bytes32 salt) external returns (address clone) {
        clone = Clones.cloneDeterministic(
            implementation,
            salt,
            0  // no ETH sent during deployment
        );
        // Initialize the clone...
    }
}
```

### Deploying a Clone with ETH

```solidity
function createCloneWithValue(bytes32 salt) external payable returns (address clone) {
    clone = Clones.cloneDeterministic(
        implementation,
        salt,
        msg.value  // forward ETH to clone during deployment
    );
}
```

### Predicting Clone Address

```solidity
function getCloneAddress(bytes32 salt) external view returns (address predicted) {
    predicted = Clones.predictDeterministicAddress(
        implementation,
        salt,
        address(this)  // deployer address
    );
}
```

## Key Features

- **Deterministic Addresses**: Same `implementation`, `salt`, and `deployer` always produce the same address
- **Gas Efficient**: Minimal proxy pattern deploys only 45 bytes of bytecode
- **Value Support**: Can send ETH to clones during deployment (requires factory to be payable)
- **Idempotent Checks**: Deploying to an address with existing code will revert

## Important Notes

1. **Deployment Reverts on Duplicate**: Using the same `implementation` and `salt` twice will revert since CREATE2 cannot deploy to the same address twice
2. **Factory Balance Required**: When deploying with `value > 0`, the factory contract must have sufficient balance
3. **No Initialization**: Clones are deployed uninitialized. You must call an initialization function separately
4. **Delegate All Calls**: Clones delegate all calls to the implementation contract via DELEGATECALL

## EIP-1167 Minimal Proxy

The deployed bytecode follows the EIP-1167 standard:

```
363d3d373d3d3d363d73{implementation}5af43d82803e903d91602b57fd5bf3
```

This bytecode:
1. Copies calldata to memory
2. Delegates call to implementation address
3. Copies return data back
4. Returns (or reverts) based on call success

## License

MIT (inherited from OpenZeppelin Contracts v5.3.0)

## Source

Derived from [OpenZeppelin Contracts v5.3.0](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.3.0/contracts/proxy/Clones.sol)

Modified to include only deterministic deployment functions with explicit value parameter support.
