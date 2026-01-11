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
- [Create Solids via Etherscan](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#writeContract#F3) - Call `make()` directly from your browser

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
- `home` - Deterministic contract address (computed via CREATE2)
- `salt` - CREATE2 salt: `keccak256(abi.encode(name, symbol))`

#### `make(string name, string symbol) → ISolid sol`

Creates a new Solid with deterministic deployment. If a Solid with the given name and symbol already exists, returns the existing instance (does not revert).

```solidity
ISolid H = NOTHING.make("Hydrogen", "H");
```

**Requirements:**
- Name and symbol must not be empty
- No stake required (anyone can create for free)

**Effects:**
- Deploys new Solid at deterministic address (or returns existing if already made)
- Mints exactly AVOGADRO (6.02214076e23) tokens, 100% to pool, 0% to creator
- Pool starts with 0 actual ETH but uses virtual 1 ETH for pricing
- **Starting price**: 1 ETH = ~602,214.076 solids (AVOGADRO / 10^18)
  - At ETH = $3,000: ~$0.005 USD per solid (half a penny)
- **Price floor**: Virtual 1 ETH is permanent, ensuring sell prices never fall below starting price

### Trading Functions

#### `buys(uint256 eth) → uint256 sol`

Returns the amount of Solid received for buying with ETH (view function).

```solidity
uint256 sol = H.buys(1 ether);  // Calculate without executing
```

**Formula:**
```solidity
sol = solPool - solPool * (ethPool - eth) / ethPool
```

#### `buy() → uint256 sol`

Buys Solid tokens with ETH from the pool.

```solidity
uint256 sol = H.buy{value: 1 ether}();
```

**Formula:**
```solidity
sol = solPool - solPool * (ethPool - eth) / ethPool
// Equivalent to: sol = solPool * eth / ethPool
```

**Effects:**
- Transfers Solid tokens from pool to caller (does NOT mint new tokens)
- Increases pool ETH by `msg.value`
- Decreases pool Solid by `sol`
- Uses constant-product formula to maintain k ≈ constant

#### `sells(uint256 sol) → uint256 eth`

Returns the amount of ETH received for selling Solid (view function).

```solidity
uint256 eth = H.sells(100 * 1e18);  // Calculate without executing
```

**Formula:**
```solidity
eth = ethPool - ethPool * solPool / (solPool + sol)
```

**Note:** ETH payout is capped at actual balance (virtual pricing may calculate infinitesimally higher).

#### `sell(uint256 sol) → uint256 eth`

Sells Solid tokens for ETH from the pool.

```solidity
uint256 eth = H.sell(100 * 1e18);
```

**Formula:**
```solidity
eth = ethPool - ethPool * solPool / (solPool + sol)
```

**Requirements:**
- Caller must have sufficient Solid token balance
- No approval needed - caller sells their own tokens directly

**Effects:**
- Transfers Solid tokens from caller to pool (does NOT burn tokens)
- Transfers ETH from pool to caller
- Increases pool Solid by `sol`
- Decreases pool ETH by `eth`
- ETH payout capped at actual balance (virtual pricing may calculate higher)
- Protected by reentrancy guard (EIP-1153 transient storage)

#### `sellsFor(ISolid that, uint256 sol) → uint256 thats`

Returns the amount of another Solid received for selling this Solid (view function).

```solidity
// Calculate how much Oxygen you'd get for selling 100 Hydrogen
uint256 oxygenAmount = H.sellsFor(O, 100 * 1e18);
```

**Formula:**
```solidity
// Calculates: H.sells(sol) -> eth, then O.buys(eth) -> thats
```

#### `sellFor(ISolid that, uint256 sol) → uint256 thats`

Sells this Solid for another Solid in a single atomic transaction.

```solidity
// Sell 100 Hydrogen for Oxygen in one transaction
uint256 oxygenReceived = H.sellFor(O, 100 * 1e18);
```

**Requirements:**
- Caller must have sufficient balance of this Solid
- No approval needed - uses internal transfer mechanism

**Effects:**
- Sells this Solid for ETH
- Immediately buys that Solid with the ETH
- Returns the amount of that Solid received
- Protected by reentrancy guard (EIP-1153 transient storage)

### Query Functions

#### `pool() → (uint256 solPool, uint256 ethPool)`

Returns current pool balances. Note that `ethPool` includes a virtual 1 ETH added to the actual balance for pricing purposes.

```solidity
(uint256 solPool, uint256 ethPool) = H.pool();
// solPool = Solid tokens in pool (actual balance)
// ethPool = address(H).balance + 1 ether (virtual pricing)
```

**Virtual ETH Pricing:**
- Pool adds 1 ether to actual balance for all pricing calculations
- Enables initial price discovery even with 0 actual ETH
- **Price floor guarantee**: Virtual 1 ETH ensures sell price never falls below starting price
  - Even if all tokens sold back to pool, ethPool ≥ 1 ether
  - Creates natural price floor at ~602,214.076 solids per ETH

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

### `Buy(ISolid indexed solid, uint256 e, uint256 s)`

Emitted when ETH is used to buy Solid tokens.

```solidity
event Buy(ISolid indexed solid, uint256 e, uint256 s);
```

**Parameters:**
- `solid` - The Solid instance where buy occurred
- `e` - Amount of ETH spent
- `s` - Amount of Solid received

### `Sell(ISolid indexed solid, uint256 s, uint256 e)`

Emitted when Solid is sold for ETH.

```solidity
event Sell(ISolid indexed solid, uint256 s, uint256 e);
```

**Parameters:**
- `solid` - The Solid instance where sell occurred
- `s` - Amount of Solid sold
- `e` - Amount of ETH received

## Errors

### `Nothing()`

Thrown when:
- Name or symbol is empty in `made()` or `make()`
- Functions are called on the NOTHING instance itself (NOTHING cannot trade)

### `SellFailed(ISolid solid, uint256 s, uint256 e, uint256 E)`

Thrown when ETH transfer to seller fails during `sell()`.

**Parameters:**
- `solid` - The Solid instance where the sell failed
- `s` - Amount of Solid being sold
- `e` - Amount of ETH that should have been sent
- `E` - Virtual ETH pool balance

## Constants

The ISolid interface extends `IERC20Metadata`, providing standard ERC-20 functions:

- `name()` - Token name
- `symbol()` - Token symbol
- `decimals()` - Token decimals (18)
- `totalSupply()` - Total supply (always exactly 6.02214076e23, never changes)
- `balanceOf(address)` - Balance of account
- `transfer(address, uint256)` - Transfer tokens
- `approve(address, uint256)` - Approve spender
- `transferFrom(address, address, uint256)` - Transfer from approved account
- `allowance(address, address)` - Query spender allowance

## Implementation Notes

### Deterministic Deployment

Solids use CREATE2 with salt = `keccak256(abi.encode(name, symbol))`, ensuring:

- Same name+symbol always produces same address
- Address can be predicted before deployment via `made()` function
- No front-running concerns (deterministic addresses)
- Uses EIP-1167 minimal proxy pattern (OpenZeppelin Clones)

### Supply Distribution

When a Solid is created:

```
Total Supply = 6.02214076e23 (exactly Avogadro's number, never changes)
Creator Share = 0% (no tokens for creator)
Pool Share = 100% (all 6.02214076e23 tokens)
Initial Price = AVOGADRO / 10^18 = ~602,214.076 solids per 1 ETH
At $3,000/ETH = ~$0.005 USD per solid (half a penny)
```

The total supply is permanently fixed - buy/sell operations only transfer tokens between users and pool without minting or burning.

### Constant Product AMM

The pool maintains constant product:

```
solPool * ethPool ≈ k
```

Due to rounding in the formulas, the product may change infinitesimally after each trade.

### Security

- `sell()` protected by reentrancy guard (EIP-1153 transient storage via OpenZeppelin ReentrancyGuardTransient)
- `buy()` is payable, no reentrancy protection needed (receives ETH only)
- ETH transfers propagate revert reasons on failure
- Total supply fixed forever at exactly AVOGADRO (6.02214076e23)
  - No minting after creation
  - No burning mechanism
  - Buy/sell only transfers tokens between users and pool
- Virtual 1 ETH pricing creates permanent price floor
- `sell()` caps ETH payout to actual balance to prevent reversion

## Examples

### Creating a New Solid

```solidity
function createOxygen() public returns (ISolid O) {
    // No need to check if exists - make() returns existing instance if already made
    // No stake required - anyone can create for free
    O = NOTHING.make("Oxygen", "O");

    // After creation:
    // O.totalSupply() == 6.02214076e23 (exactly Avogadro's number)
    // O.balanceOf(msg.sender) == 0 (creator gets nothing)
    // O.balanceOf(address(O)) == 6.02214076e23 (pool gets 100%)
}
```

### Trading

```solidity
function buyAndSell(ISolid H) public payable {
    // Preview buy before executing
    uint256 expectedSol = H.buys(1 ether);

    // Buy Solid tokens with 1 ETH (transfers from pool, doesn't mint)
    uint256 solReceived = H.buy{value: 1 ether}();

    // Get pool state (ethPool includes virtual 1 ETH)
    (uint256 solPool, uint256 ethPool) = H.pool();

    // Preview sell before executing
    uint256 expectedEth = H.sells(solReceived / 2);

    // Sell half the Solid back (transfers to pool, doesn't burn)
    uint256 ethReceived = H.sell(solReceived / 2);

    // Note: Due to AMM pricing, ethReceived will be slightly less than 0.5 ETH
}
```

### Cross-Solid Trading

```solidity
function tradeHydrogenForOxygen(ISolid H, ISolid O) public {
    // Preview the trade
    uint256 expectedOxygen = H.sellsFor(O, 100 * 1e18);

    // Execute: sell 100 Hydrogen for Oxygen in one atomic transaction
    uint256 oxygenReceived = H.sellFor(O, 100 * 1e18);

    // No approval needed - sellFor uses internal transfer
    assert(oxygenReceived == expectedOxygen);
}
```

### Liquidity Provision

```solidity
function provideLiquidity(ISolid H) public payable {
    // Add ETH liquidity by buying Solid tokens
    uint256 sol = H.buy{value: msg.value}();

    // Keep Solid tokens as liquidity position
    // No LP tokens - Solid tokens ARE the liquidity
    // You can sell back anytime: H.sell(sol)
}
```

## Links

- [Solid Protocol Documentation](https://github.com/uniteum/solid)
- [Reference Implementation](https://github.com/uniteum/solid/blob/main/src/Solid.sol)
- [NOTHING on Etherscan](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE) - Deployed mainnet contract

## Version

This interface is designed for Solidity ^0.8.30 to support EIP-1153 (transient storage).
