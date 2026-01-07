# ISolid Interface

> Solidity interface for the Solid protocol - a constant-product AMM for ETH/SOL token pairs with deterministic deployment.

## Overview

ISolid is the canonical interface for the Solid protocol, a novel AMM (Automated Market Maker) design where:

- **SOL tokens** are traded against **ETH** using a constant-product formula
- Contracts are deployed **deterministically** using CREATE2
- A **factory pattern** creates new Solids from a base NOTHING instance
- **50% of supply** goes to the creator, **50% to the pool** on creation

## Installation

### Foundry

```bash
forge install uniteum/isolid
```

Add to your `remappings.txt`:

```
isolid/=lib/isolid/
```

### Usage in Solidity

```solidity
import {ISolid} from "isolid/ISolid.sol";

contract MyContract {
    ISolid public immutable NOTHING;

    constructor(ISolid nothing) {
        NOTHING = nothing;
    }

    function createHydrogen() external payable returns (ISolid H) {
        // Creates "Hydrogen" with symbol "H"
        H = NOTHING.make{value: 0.001 ether}("Hydrogen", "H");
    }
}
```

## Core Functions

### Factory Functions

#### `made(string name, string symbol) → (bool yes, address home, bytes32 salt)`

Checks if a Solid exists and computes its deterministic address.

```solidity
(bool exists, address addr, bytes32 salt) = NOTHING.made("Hydrogen", "H");

if (!exists) {
    ISolid H = NOTHING.make{value: 0.001 ether}("Hydrogen", "H");
    assert(address(H) == addr);  // Address is deterministic!
}
```

**Parameters:**
- `name` - Token name (must not be empty)
- `symbol` - Token symbol (must not be empty)

**Returns:**
- `yes` - True if Solid already exists
- `home` - Deterministic contract address
- `salt` - CREATE2 salt: `keccak256(abi.encode(name, symbol))`

#### `make(string name, string symbol) → ISolid sol`

Creates a new Solid with deterministic deployment.

```solidity
ISolid H = NOTHING.make{value: 0.001 ether}("Hydrogen", "H");
```

**Requirements:**
- `msg.value >= MAKER_FEE` (0.001 ether)
- Name and symbol must not be empty
- Solid with same name/symbol must not exist

**Effects:**
- Deploys new Solid at deterministic address
- Mints 50% of SUPPLY to `msg.sender`
- Mints 50% of SUPPLY to the pool
- Deposits `msg.value` as initial pool liquidity

### Trading Functions

#### `deposit() → uint256 sol`

Deposits ETH to receive SOL tokens from the pool.

```solidity
uint256 sol = H.deposit{value: 1 ether}();
```

**Formula:**
```
sol = solPool - solPool * (ethPool - eth) / ethPool
```

**Effects:**
- Transfers SOL from pool to caller
- Increases pool ETH by `msg.value`
- Decreases pool SOL by `sol`

#### `withdraw(uint256 sol) → uint256 eth`

Withdraws ETH by depositing SOL tokens to the pool.

```solidity
uint256 eth = H.withdraw(100 * 1e18);
```

**Formula:**
```
eth = ethPool - ethPool * solPool / (solPool + sol)
```

**Requirements:**
- Caller must have sufficient SOL balance
- Caller must have approved the contract

**Effects:**
- Transfers SOL from caller to pool
- Transfers ETH from pool to caller
- Protected by reentrancy guard

### Query Functions

#### `pool() → (uint256 solPool, uint256 ethPool)`

Returns current pool balances.

```solidity
(uint256 solPool, uint256 ethPool) = H.pool();
```

#### `NOTHING() → ISolid`

Returns the base NOTHING instance (the factory).

```solidity
ISolid factory = H.NOTHING();
```

#### `MAKER_FEE() → uint256`

Returns the minimum payment required to create a Solid (0.001 ether).

```solidity
uint256 fee = H.MAKER_FEE();
```

## Events

### `Make(ISolid indexed solid, string indexed name, string indexed symbol)`

Emitted when a new Solid is created.

```solidity
event Make(ISolid indexed solid, string indexed name, string indexed symbol);
```

### `Deposit(ISolid indexed solid, uint256 eth, uint256 sol)`

Emitted when ETH is deposited for SOL tokens.

```solidity
event Deposit(ISolid indexed solid, uint256 eth, uint256 sol);
```

### `Withdraw(ISolid indexed solid, uint256 sol, uint256 eth)`

Emitted when SOL is deposited for ETH.

```solidity
event Withdraw(ISolid indexed solid, uint256 sol, uint256 eth);
```

## Errors

### `Nothing()`

Thrown when name or symbol is empty in `made()` or `make()`.

### `WithdrawFailed()`

Thrown when ETH transfer to withdrawer fails.

### `PaymentLow(uint256 sent, uint256 required)`

Thrown when payment is less than MAKER_FEE in `make()`.

### `MadeAlready(string name, string symbol)`

Thrown when attempting to make a Solid that already exists.

## Constants

The ISolid interface extends `IERC20Metadata`, providing:

- `name()` - Token name
- `symbol()` - Token symbol
- `decimals()` - Token decimals (18)
- `totalSupply()` - Total supply (6.02214076e27)
- `balanceOf(address)` - Balance of account
- `transfer(address, uint256)` - Transfer tokens
- `approve(address, uint256)` - Approve spender
- `transferFrom(address, address, uint256)` - Transfer from approved account

## Implementation Notes

### Deterministic Deployment

Solids use CREATE2 with salt = `keccak256(abi.encode(name, symbol))`, ensuring:

- Same name+symbol always produces same address
- Address can be predicted before deployment
- No front-running concerns

### Supply Distribution

When a Solid is created:

```
Total Supply = 6.02214076e27 (10,000 mols × Avogadro's number)
Creator Share = 50% (3.01107038e27)
Pool Share = 50% (3.01107038e27)
```

### Constant Product AMM

The pool maintains approximately constant product:

```
solPool * ethPool ≈ k
```

Due to rounding in the formulas, the product actually increases slightly after each trade, providing a built-in fee mechanism.

### Security

- `withdraw()` uses reentrancy guard (EIP-1153 transient storage)
- ETH transfers propagate revert reasons
- No minting/burning after creation (fixed supply)

## Examples

### Creating a New Element

```solidity
function createOxygen() public payable returns (ISolid O) {
    // Check if Oxygen exists
    (bool exists, address addr,) = NOTHING.made("Oxygen", "O");

    if (exists) {
        O = ISolid(addr);
    } else {
        // Create with minimum fee
        O = NOTHING.make{value: 0.001 ether}("Oxygen", "O");
    }
}
```

### Trading

```solidity
function buyAndSell(ISolid H) public payable {
    // Buy SOL with 1 ETH
    uint256 solReceived = H.deposit{value: 1 ether}();

    // Get pool state
    (uint256 solPool, uint256 ethPool) = H.pool();

    // Sell half the SOL back
    uint256 ethReceived = H.withdraw(solReceived / 2);
}
```

### Liquidity Provision

```solidity
function provideLiquidity(ISolid H, uint256 amount) public {
    // Add ETH liquidity
    uint256 sol = H.deposit{value: amount}();

    // Keep SOL tokens as liquidity position
    // (No LP tokens - SOL tokens ARE the liquidity)
}
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Solid Protocol Documentation](https://github.com/uniteum/liquid)
- [Reference Implementation](https://github.com/uniteum/liquid/blob/solid/src/Solid.sol)

## Version

This interface is designed for Solidity ^0.8.30 to support EIP-1153 (transient storage).
