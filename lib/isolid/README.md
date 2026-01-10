# ISolid Interface

> Solidity interface for the Solid protocol - a constant-product AMM for ETH/SOL token pairs with deterministic deployment.

## Overview

ISolid is the canonical interface for the Solid protocol, a novel AMM (Automated Market Maker) design where:

- **Solid tokens** are traded against **ETH** using a constant-product formula
- Contracts are deployed **deterministically** using CREATE2
- A **factory pattern** creates new Solids from a base NOTHING instance
- **No stake required** - anyone can create Solids for free
- **100% of supply** goes to the pool on creation (0% to creator)
- **Virtual 1 ETH pricing** creates elegant starting price and permanent price floor

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

    function createHydrogen() external returns (ISolid H) {
        // Creates "Hydrogen" with symbol "H" (no stake required)
        H = NOTHING.make("Hydrogen", "H");
    }
}
```

**Deployed NOTHING (Ethereum Mainnet):**
- Address: [`0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE`](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE)

## Core Functions

### Factory Functions

#### `made(string name, string symbol) → (bool yes, address home, bytes32 salt)`

Checks if a Solid exists and computes its deterministic address.

```solidity
(bool exists, address addr, bytes32 salt) = NOTHING.made("Hydrogen", "H");

if (!exists) {
    ISolid H = NOTHING.make("Hydrogen", "H");
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

Creates a new Solid with deterministic deployment. If a Solid with the given name and symbol already exists, returns the existing instance.

```solidity
ISolid H = NOTHING.make("Hydrogen", "H");
```

**Requirements:**
- Name and symbol must not be empty
- No stake required (anyone can create for free)

**Effects:**
- Deploys new Solid at deterministic address (or returns existing)
- Mints exactly AVOGADRO (6.02214076e23) tokens, 100% to pool
- Pool uses virtual 1 ETH for initial pricing
- Starting price: 1 ETH = ~602,214.076 solids (~$0.005/solid @ $3k ETH)
- Virtual 1 ETH creates permanent price floor - sell prices never fall below this

### Trading Functions

#### `buy() → uint256 sol`

Deposits ETH to receive SOL tokens from the pool.

```solidity
uint256 sol = H.buy{value: 1 ether}();
```

**Formula:**
```
sol = solPool - solPool * (ethPool - eth) / ethPool
```

**Effects:**
- Transfers SOL from pool to caller
- Increases pool ETH by `msg.value`
- Decreases pool SOL by `sol`

#### `sell(uint256 sol) → uint256 eth`

Gets ETH by putting SOL tokens into the pool.

```solidity
uint256 eth = H.sell(100 * 1e18);
```

**Formula:**
```
eth = ethPool - ethPool * solPool / (solPool + sol)
```

**Requirements:**
- Caller must have sufficient Solid token balance
- No approval needed - caller sells their own tokens directly

**Effects:**
- Transfers Solid tokens from caller to pool
- Transfers ETH from pool to caller
- ETH payout capped at actual balance (virtual pricing may calculate higher)
- Protected by reentrancy guard

### Query Functions

#### `pool() → (uint256 solPool, uint256 ethPool)`

Returns current pool balances. Note that `ethPool` includes a virtual 1 ETH added to the actual balance for pricing purposes.

```solidity
(uint256 solPool, uint256 ethPool) = H.pool();
// solPool = Solid tokens in pool
// ethPool = address(H).balance + 1 ether (virtual pricing)
```

The virtual 1 ETH creates an elegant starting price and permanent price floor - sell prices can never fall below the starting price.

#### `NOTHING() → ISolid`

Returns the base NOTHING instance (the factory).

```solidity
ISolid factory = H.NOTHING();
```

## Events

### `Make(ISolid indexed solid, string indexed name, string indexed symbol)`

Emitted when a new Solid is created.

```solidity
event Make(ISolid indexed solid, string indexed name, string indexed symbol);
```

### `Buy(ISolid indexed solid, uint256 eth, uint256 sol)`

Emitted when ETH is used to buy SOL tokens.

```solidity
event Buy(ISolid indexed solid, uint256 eth, uint256 sol);
```

### `Sell(ISolid indexed solid, uint256 sol, uint256 eth)`

Emitted when SOL is sold for ETH.

```solidity
event Sell(ISolid indexed solid, uint256 sol, uint256 eth);
```

## Errors

### `Nothing()`

Thrown when name or symbol is empty in `made()` or `make()`.

### `SellFailed()`

Thrown when ETH transfer to seller fails during `sell()`.

## Constants

The ISolid interface extends `IERC20Metadata`, providing:

- `name()` - Token name
- `symbol()` - Token symbol
- `decimals()` - Token decimals (18)
- `totalSupply()` - Total supply (6.02214076e23, exactly one Avogadro's number)
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
Total Supply = 6.02214076e23 (exactly one Avogadro's number)
Creator Share = 0% (no tokens for creator)
Pool Share = 100% (6.02214076e23)
Initial Price = ~602,214.076 solids per 1 ETH (~$0.005/solid @ $3k ETH)
```

### Constant Product AMM

The pool maintains constant product:

```
solPool * ethPool ≈ k
```

Due to rounding in the formulas, the product may change infinitesimally after each trade.

### Security

- `sell()` uses reentrancy guard (EIP-1153 transient storage)
- ETH transfers propagate revert reasons
- No minting after creation (total supply fixed at exactly one Avogadro's number: 6.02214076e23)
- Total supply never changes (no burning mechanism)
- Virtual 1 ETH pricing creates permanent price floor

## Examples

### Creating a New Element

```solidity
function createOxygen() public returns (ISolid O) {
    // No need to check if exists - make() returns existing instance if already made
    O = NOTHING.make("Oxygen", "O");
}
```

### Trading

```solidity
function buyAndSell(ISolid H) public payable {
    // Buy SOL with 1 ETH
    uint256 solReceived = H.buy{value: 1 ether}();

    // Get pool state
    (uint256 solPool, uint256 ethPool) = H.pool();

    // Sell half the SOL back
    uint256 ethReceived = H.sell(solReceived / 2);
}
```

### Liquidity Provision

```solidity
function provideLiquidity(ISolid H, uint256 amount) public {
    // Add ETH liquidity
    uint256 sol = H.buy{value: amount}();

    // Keep SOL tokens as liquidity position
    // (No LP tokens - SOL tokens ARE the liquidity)
}
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Solid Protocol Documentation](https://github.com/uniteum/solid)
- [Reference Implementation](https://github.com/uniteum/solid/blob/main/src/Solid.sol)
- [NOTHING on Etherscan](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE) - Deployed mainnet contract

## Version

This interface is designed for Solidity ^0.8.30 to support EIP-1153 (transient storage).
