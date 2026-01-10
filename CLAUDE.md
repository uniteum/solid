# CLAUDE.md - Solid Protocol

> Context guide for AI-assisted development of the Solid protocol.

## Meta: Maintaining This Document

### Purpose
This file provides context for AI assistants (primarily Claude) to understand the Solid protocol codebase. It is optimized for token efficiency and accuracy.

### When to Update

**Update IMMEDIATELY when:**
- User provides feedback contradicting this documentation
- Core protocol mechanics change (formulas, operations, invariants)
- New functions or contracts are added
- File structure changes significantly
- Test patterns or development workflows change

**Update PROACTIVELY when:**
- You discover inaccuracies while working on tasks
- Line counts or file sizes drift significantly from stated values
- Code examples become outdated or incorrect
- Better explanations or examples become apparent

### How to Update

**Optimization Guidelines:**
- Keep total length under 500 lines
- Prioritize formulas, patterns, and non-obvious mechanics
- Remove redundant explanations
- Use concise code examples over prose
- Reference other docs instead of duplicating content
- Update line counts when files change significantly (>10% drift)

**What to Include:**
- Core operations with exact formulas
- Non-obvious architectural patterns (CREATE2, factory, etc.)
- Common pitfalls or gotchas
- Test patterns that save time
- Quick reference for frequent operations

**What to Exclude:**
- Standard Solidity/Foundry knowledge
- Extensive background on ERC-20, AMMs, etc.
- Detailed explanations available in official docs
- Verbose examples when concise ones suffice

### Validation Process

**Before finalizing updates:**
1. Verify formulas against actual code in [src/Solid.sol](src/Solid.sol)
2. Check that line counts are approximately correct
3. Test code examples compile/run if they've changed
4. Ensure Quick Reference section remains accurate
5. Confirm total length stays token-efficient

### Related Documentation Files

- [README.md](README.md) - User-facing introduction
- [foundry.toml](foundry.toml) - Build configuration (authoritative source)
- [src/Solid.sol](src/Solid.sol) - Source of truth for all mechanics
- [src/ISolid.sol](src/ISolid.sol) - Interface definitions

**If user feedback conflicts with CLAUDE.md:** Update this file to reflect reality, then confirm the change with the user.

## Overview

**Solid** is a constant-product AMM protocol on Ethereum where Solid tokens are traded against ETH with deterministic deployment.

### Core Concepts

- **Solid tokens** = ERC-20 tokens created by the protocol (state variable: balances)
- **ETH** = Native Ethereum currency used for liquidity
- **NOTHING** = Base Solid instance used as factory for creating new Solids
- **Pool** = Contract balances of Solid tokens and ETH
- **Total Supply** = Fixed at exactly Avogadro's number (6.02214076e23)
- **Starting Price** = 1 ETH buys ~602,214.076 solids (≈ $0.005 USD per solid when ETH = $3,000)
- **Price Floor** = Virtual 1 ETH guarantees sell price never falls below starting price

### Key Files

- **[src/Solid.sol](src/Solid.sol)** (~90 lines) - Main contract
- **[lib/isolid/ISolid.sol](lib/isolid/ISolid.sol)** (~100 lines) - Interface with comprehensive NatSpec
- **[test/Solid.t.sol](test/Solid.t.sol)** (~290 lines) - Core tests
- **[test/SolidUser.sol](test/SolidUser.sol)** (~45 lines) - Test helper

## Core Operations

### 1. Make (Create New Solid)

```solidity
function make(string calldata name, string calldata symbol) external returns (ISolid sol)
```

**What it does:**
- Creates new Solid with name `name` and symbol `symbol`
- If Solid already exists, returns the existing instance (does not revert)
- No stake required (anyone can create for free)
- Mints exactly AVOGADRO tokens (100% to pool, 0% to maker)
- Pool starts with 0 actual ETH but uses virtual 1 ETH for pricing
- Uses CREATE2 for deterministic addresses
- **Initial price**: 1 ETH = ~602,214.076 solids
  - Elegant Avogadro relationship: AVOGADRO / 10^18
  - At ETH = $3,000: ~$0.005 USD per solid (half a penny)
- **Price floor**: Virtual 1 ETH ensures sell price never falls below this starting price

**Formula:**
```solidity
// Salt calculation
salt = keccak256(abi.encode(name, symbol))

// Supply split
maker_share = 0  // 0% to msg.sender (no tokens for maker)
pool_share = AVOGADRO  // 100% to contract (6.02214076e23)
```

**Example:**
```solidity
ISolid H = N.make("Hydrogen", "H");
// H.totalSupply() = AVOGADRO (6.02214076e23)
// H.balanceOf(msg.sender) = 0  // Maker gets nothing
// H.balanceOf(address(H)) = AVOGADRO  // Pool gets 100%
// address(H).balance = 0  // No actual ETH
// pool() returns (AVOGADRO, 1 ether)  // Virtual 1 ETH for pricing
// For 1 ETH, you can buy: AVOGADRO / 1e18 = ~602,214.076 solids
// At $3,000/ETH: each solid costs ~$0.005 USD (half a penny)
```

### 2. Buy (ETH → Solid)

```solidity
function buy() public payable returns (uint256 sol)
```

**What it does:**
- Buys Solid tokens with ETH from pool
- Uses constant-product formula
- Does NOT mint new tokens (transfers from pool)
- Pool Solid decreases, pool ETH increases

**Formula:**
```solidity
sol = solPool - solPool * (ethPool - eth) / ethPool
// Equivalent to: sol = solPool * eth / ethPool
// This is the delta that makes the product constant
```

**Example:**
```solidity
uint256 sol = H.buy{value: 1 ether}();
// Transfers sol tokens from pool to msg.sender
// Pool ETH increases by 1 ether
```

### 3. Sell (Solid → ETH)

```solidity
function sell(uint256 sol) external nonReentrant returns (uint256 eth)
```

**What it does:**
- Sells Solid tokens for ETH from pool
- Uses constant-product formula
- Does NOT burn tokens (transfers to pool)
- Pool Solid increases, pool ETH decreases

**Formula:**
```solidity
eth = ethPool - ethPool * solPool / (solPool + sol)
```

**Example:**
```solidity
uint256 eth = H.sell(100);
// Transfers 100 Solid from msg.sender to pool
// Transfers calculated eth to msg.sender
```

## Mathematical Invariants

### 1. Constant Product AMM

```
solPool * ethPool = k  (approximately constant before and after trades)
```

**Note:** Due to rounding in the formulas, the product may change infinitesimally after each trade.

### 2. Total Supply is Fixed

```
totalSupply() = AVOGADRO (always, exactly 6.02214076e23)
```

Total supply is fixed at exactly Avogadro's number. Buy/sell operations only transfer tokens between users and pool without changing total supply.

### 3. Balance Integrity

```
balanceOf(pool) + balanceOf(maker) + sum(other balances) = totalSupply()
```

All balances must sum to total supply at all times.

## Factory Pattern

### Creating New Solids

```solidity
function made(string calldata name, string calldata symbol)
    public view returns (bool yes, address location, bytes32 salt)
```

**How it works:**
- Uses CREATE2 with `keccak256(abi.encode(name, symbol))` as salt
- Same name+symbol always produces same address
- Uses EIP-1167 minimal proxy (OpenZeppelin Clones)
- Only callable from NOTHING instance

**Example:**
```solidity
// Check if "Hydrogen" "H" exists
(bool exists, address addr, bytes32 salt) = N.made("Hydrogen", "H");

// Create if doesn't exist
if (!exists) {
    ISolid H = N.make("Hydrogen", "H");
    assert(address(H) == addr);  // Deterministic!
}
```

### Delegation Pattern

When `make()` is called on a non-NOTHING instance:
```solidity
if (this != NOTHING) {
    sol = NOTHING.make(name, symbol);
    // No transfer needed - maker gets nothing
}
```

This allows any Solid to create new Solids, but always delegates to NOTHING.

## Architecture

### Contract Structure

```solidity
contract Solid is ISolid, ERC20, ReentrancyGuardTransient {
    uint256 constant AVOGADRO = 6.02214076e23;

    ISolid public immutable NOTHING = this;
}
```

### State Variables

- `NOTHING` - Immutable self-reference (main instance for factory)
- `_name` - Token name (from ERC20)
- `_symbol` - Token symbol (from ERC20)
- `_balances` - Token balances mapping (from ERC20)

### Key Functions

**Balance Queries:**
- `pool()` - Returns (solPool, ethPool) tuple where ethPool = actualBalance + 1 ether
- `balanceOf(address)` - Standard ERC20 balance query

**Factory:**
- `made(name, symbol)` - Check if Solid exists and predict address
- `make(name, symbol)` - Create new Solid with deterministic address

**Trading:**
- `buy()` - Buy Solid with ETH
- `sell(sol)` - Sell Solid for ETH

**Internal:**
- `zzz_(name, symbol)` - Initialization function (called once during creation)

## Security

### Reentrancy Protection

```solidity
modifier nonReentrant() {
    // Uses EIP-1153 transient storage
    // from OpenZeppelin ReentrancyGuardTransient
}
```

- `sell()` uses `nonReentrant` (sends ETH to msg.sender)
- `buy()` is payable, no reentrancy needed (receives ETH)
- Transient storage clears after transaction

### Virtual ETH Pricing

```solidity
function pool() public view returns (uint256 solPool, uint256 ethPool) {
    if (this == NOTHING) revert Nothing();
    solPool = balanceOf(address(this));
    ethPool = address(this).balance + 1 ether;  // Virtual pricing
}
```

- Pool adds 1 ether to actual balance for pricing calculations
- Enables initial price discovery even with 0 actual ETH
- **Price floor guarantee**: The virtual 1 ETH ensures the sell price can never fall below the starting price
  - Even if all tokens are sold back to the pool, ethPool ≥ 1 ether
  - This creates a natural price floor at ~602,214.076 solids per ETH
- `sell()` caps payout to actual balance to prevent reversion

```solidity
function sell(uint256 sol) external nonReentrant returns (uint256 eth) {
    eth = sells(sol);
    uint256 actualBalance = address(this).balance;
    if (eth > actualBalance) eth = actualBalance;  // Cap to actual
    // ... transfer eth
}
```

### Safe ETH Transfers

```solidity
(bool ok, bytes memory returnData) = msg.sender.call{value: eth}("");
if (!ok) {
    if (returnData.length > 0) {
        assembly {
            revert(add(returnData, 32), mload(returnData))
        }
    } else {
        revert SellFailed();
    }
}
```

- Propagates revert reason from failed transfers
- Custom error if no revert reason provided

### Factory Access Control

- `zzz_()` only callable during initialization (checks `_symbol` is empty)
- No explicit access control (anyone can call once)
- CREATE2 ensures deterministic addresses prevent front-running

### Critical Invariants

**IMPORTANT:** These invariants MUST hold at all times:

1. **Total supply is fixed**: `totalSupply() == AVOGADRO` (never changes, exactly 6.02214076e23)
2. **Pool balance consistency**: `balanceOf(address(this)) + sum(user balances) == AVOGADRO`
3. **ETH balance consistency**: `address(this).balance` accurately reflects pool liquidity

## Development Workflow

### Build & Test

```bash
forge build          # Compile contracts
forge test           # Run test suite
forge test -vvv      # Verbose output with logs
forge fmt            # Format code
```

### Testing Strategy

**IMPORTANT: Always do smoke tests first, not full tests, unless changes are extensive.**

**Smoke Testing (Default approach):**
- After making changes, run a targeted test that exercises the changed code
- This provides fast feedback (milliseconds to seconds)
- Only run full test suite when changes are extensive or affect multiple areas
- **Always prompt the user before running the full test suite**

**Examples:**
```bash
# After adding sellFor function - test just that function
forge test --match-test test_SellFor_NoApproval -vv

# After modifying buy logic - test buy operations
forge test --match-test test_Buy -vv

# Quick compilation check
forge test --match-test test_Setup -vv
```

**When to run full tests:**
- Core protocol changes (buy/sell formulas, pool logic)
- Changes affecting multiple contracts
- Before commits/PRs
- After user explicitly requests it

### Running Specific Tests

```bash
forge test --match-test test_MakeHydrogen     # Run single test
forge test --match-test test_BuySell          # Run specific test
forge test --match-test test_Setup -vv        # Quick test with verbose output
forge test --match-contract SolidInvariant    # Run invariant tests
```

### Invariant Test Profiles

Invariant tests can be configured for different thoroughness levels:

```bash
# Quick (64 runs, 128 depth) - ~4 seconds
FOUNDRY_PROFILE=quick forge test --match-contract SolidInvariant

# Default (256 runs, 500 depth) - ~170 seconds
forge test --match-contract SolidInvariant

# CI (512 runs, 1000 depth) - thorough testing
FOUNDRY_PROFILE=ci forge test --match-contract SolidInvariant

# Deep (1024 runs, 2000 depth) - very thorough
FOUNDRY_PROFILE=deep forge test --match-contract SolidInvariant
```

**When to use each:**
- `quick` - During active development (fast feedback)
- `default` - Before commits (good coverage)
- `ci` - In CI/CD pipelines
- `deep` - Before production deploys or major releases

### Code Style

**NatSpec:**
- Use `/** */` multi-line block notation (never `///`)
- Always multi-line format even for single-line comments
- Include `@notice` for public descriptions
- Add `@param` and `@return` as needed

**Formatting:**
- Run `forge fmt` before committing
- Follows Foundry's default style guide

### Code Quality & Linting

**CRITICAL: All generated code MUST be lint-free.**

**Pre-commit checklist:**
1. Run `forge fmt` on all modified `.sol` files
2. Verify compilation: `forge build`
3. Run affected tests: `forge test`
4. Check for warnings in compiler output

**Solidity Style Rules:**
- **Function visibility order**: external → public → internal → private
- **Function declaration formatting**: When parameters don't fit on one line:
  ```solidity
  // CORRECT: Multi-line with proper indentation
  function longFunctionName(uint256 param1, uint256 param2)
      public
      returns (uint256 result1, uint256 result2)
  {
      // body
  }

  // WRONG: Single line when too long
  function longFunctionName(uint256 param1, uint256 param2) public returns (uint256 result1, uint256 result2) {
  ```
- **Imports**: One per line, sorted alphabetically
- **Line length**: Max 120 characters (forge fmt default)
- **Indentation**: 4 spaces (configured in foundry.toml)

**Common Linting Fixes:**
- Add blank line before function if missing
- Remove trailing whitespace
- Ensure consistent spacing around operators
- Format multi-line function signatures consistently

**When writing code:**
1. Write the code
2. Mentally verify it follows forge fmt rules
3. If unsure, assume forge fmt will reformat and write cleanly
4. After file operations, expect forge fmt may auto-format

## Test Patterns

### Base Test Setup

```solidity
contract SolidTest is BaseTest {
    uint256 constant AVOGADRO = 6.02214076e23;
    uint256 constant ETH = 1e9;
    Solid public N;
    SolidUser public owen;

    function setUp() public virtual override {
        super.setUp();
        owen = newUser("owen");
        N = new Solid();
    }

    function newUser(string memory name) internal returns (SolidUser user) {
        user = new SolidUser(name, N);
        vm.deal(address(user), ETH);
    }
}
```

### Test User Pattern

```solidity
contract SolidUser is User {
    function buy(ISolid U, uint256 eth) public returns (uint256 solid) { }
    function sell(ISolid U, uint256 solid) public returns (uint256 eth) { }
    function liquidate(ISolid U) public returns (uint256 eth, uint256 solid) { }
}
```

**SolidUser** wraps operations with automatic logging and balance tracking.

### Example Test

```solidity
function test_BuySell(uint256 seed, uint256 d) public {
    (ISolid H,,) = makeHydrogen(seed);
    d = d % address(owen).balance;
    if (d != 0) {
        uint256 bought = owen.buy(H, d);
        uint256 sold = owen.sell(H, bought);

        assertEq(H.balanceOf(address(owen)), 0, "should have no solids left");
        assertGt(sold, 0, "should receive some ETH");
    }
}
```

### Important Test Helpers

```solidity
function makeHydrogen(uint256 seed) public returns (ISolid H, uint256 h, uint256 e) {
    seed = seed % ETH;
    H = N.make("Hydrogen", "H");
    vm.deal(address(H), seed);  // Add random ETH to pool
    (h, e) = H.pool();  // e will be seed + 1 ether (virtual)
}
```

This creates a Hydrogen Solid with random ETH in the pool for fuzz testing.

## Deployment

### Deployed Addresses

**Mainnet (Ethereum):**
- NOTHING: `0x16cF8EeB96DE6666254F498E3A3C8523454EFf54`

### Environment Variables

```bash
export tx_key=<YOUR_PRIVATE_WALLET_KEY>
export ETHERSCAN_API_KEY=<YOUR_ETHERSCAN_API_KEY>
export chain=11155111  # Sepolia testnet
```

### Deploy Script

```bash
chain=11155111
forge script script/Solid.sol \
  -f $chain \
  --private-key $tx_key \
  --broadcast \
  --verify \
  --delay 10 \
  --retries 10
```

### Supported Networks

See [foundry.toml](foundry.toml) for full chain configuration:
- Ethereum (1, 11155111)
- Arbitrum (42161, 421614)
- Base (8453, 84532)
- Optimism (10, 11155420)
- Polygon (137, 80002)
- BNB Chain (56, 97)

## Configuration

### Solidity Settings

From [foundry.toml](foundry.toml):

```toml
solc = "0.8.30"           # Required for EIP-1153
evm_version = "cancun"
optimizer = true
optimizer_runs = 200
via_ir = true
bytecode_hash = "none"
cbor_metadata = false
always_use_create_2_factory = true
```

**Key Requirements:**
- Solidity 0.8.30+ for transient storage (EIP-1153)
- Cancun EVM for latest features
- CREATE2 for deterministic deployments

## Common Operations

### Creating a New Solid

```solidity
// Create "Hydrogen" "H" (no stake required)
// If already exists, returns the existing instance (does not revert)
ISolid H = N.make("Hydrogen", "H");
// H.totalSupply() = AVOGADRO (6.02214076e23)
// H.balanceOf(msg.sender) = 0  // Maker gets nothing
// H.balanceOf(address(H)) = AVOGADRO  // Pool gets 100%
// address(H).balance = 0  // No actual ETH
// Starting price: 1 ETH = ~602,214.076 solids (~$0.005/solid @ $3k ETH)
```

### Buying Solid with ETH

```solidity
uint256 sol = H.buy{value: 1 ether}();
// Receive sol tokens from pool
// Pool ETH increases by 1 ether
// Pool Solid decreases by sol amount
```

### Selling Solid for ETH

```solidity
uint256 eth = H.sell(500);
// Send 500 Solid to pool
// Receive eth back
// Pool ETH decreases by eth amount
// Pool Solid increases by 500
```

### Checking Pool State

```solidity
(uint256 solPool, uint256 ethPool) = H.pool();
// solPool = Solid tokens in pool
// ethPool = Virtual ETH in pool (actual balance + 1 ether)
```

## Constants Reference

```solidity
AVOGADRO = 6.02214076e23        // Avogadro's number (total supply of each Solid)
```

**Key insight**: With virtual 1 ETH pricing and supply of exactly one Avogadro:
- **Initial price**: 1 ETH = AVOGADRO / 10^18 = ~602,214.076 solids
- **Elegant relationship**: "1 ETH buys Avogadro's number divided by 10^18"
- **Practical price**: When ETH = $3,000, each solid starts at ~$0.005 USD (half a penny)
- **Price floor**: The virtual 1 ETH is permanent, so sell prices can never fall below this initial price
  - Even with zero actual ETH in pool, ethPool ≥ 1 ether guarantees minimum valuation
  - This protects against complete price collapse

## Events

```solidity
event Make(ISolid indexed solid, string indexed name, string indexed symbol);
event Buy(ISolid indexed solid, uint256 eth, uint256 sol);
event Sell(ISolid indexed solid, uint256 sol, uint256 eth);
```

## Errors

```solidity
error Nothing();        // Empty name or symbol, or called on NOTHING
error SellFailed();     // ETH transfer failed during sell
```

## Quick Reference

### Pool State Queries

```solidity
(uint256 solPool, uint256 ethPool) = solid.pool();
// ethPool = address(solid).balance + 1 ether (virtual pricing)
uint256 balance = solid.balanceOf(address(user));
uint256 supply = solid.totalSupply();  // Always equals AVOGADRO (6.02214076e23)
```

### Trading Formulas

```solidity
// Buy: ETH → Solid (transfer from pool)
sol = solPool - solPool * (ethPool - eth) / ethPool
// Simplified: sol = solPool * eth / ethPool

// Sell: Solid → ETH (transfer to pool)
eth = ethPool - ethPool * solPool / (solPool + sol)
// Note: Capped to min(eth, actualBalance) before transfer
```

### Metadata

```solidity
string memory name = solid.name();
string memory symbol = solid.symbol();
uint8 decimals = solid.decimals();    // 18 (default)
ISolid nothing = solid.NOTHING();     // Factory instance
```

## Key Differences from Traditional AMMs

1. **Fixed Supply**: Total supply is exactly Avogadro's number (6.02214076e23, never changes)
2. **Native ETH**: Uses ETH directly (not WETH)
3. **Deterministic Addresses**: CREATE2 based on name+symbol
4. **Factory Pattern**: NOTHING instance creates all Solids
5. **Zero Maker Share**: Creator receives 0% (100% goes to pool)
6. **Virtual Pricing**: Pool adds 1 ETH virtually for initial price discovery
7. **Elegant Initial Price**: 1 ETH = ~602,214.076 solids (Avogadro / 10^18)
8. **Price Floor Guarantee**: Virtual 1 ETH ensures sell price never falls below starting price
9. **No Liquidity Tokens**: Solid tokens ARE the liquidity
10. **Permissionless Creation**: Anyone can create Solids for free

---

*This document is optimized for AI-assisted development. For human-readable introduction, see [README.md](README.md).*
