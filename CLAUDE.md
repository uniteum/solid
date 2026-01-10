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
- Extensive background on ERC-20, bonding curves, etc.
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
- [lib/isolid/ISolid.sol](lib/isolid/ISolid.sol) - Interface definitions

**If user feedback conflicts with CLAUDE.md:** Update this file to reflect reality, then confirm the change with the user.

## Overview

**Solid** is an exponential bonding curve protocol on Ethereum where tokens are minted/burned dynamically based on ETH deposits/withdrawals with deterministic deployment.

### Core Concepts

- **Solid tokens** = ERC-20 tokens minted dynamically via bonding curve
- **ETH** = Native Ethereum currency used for buying/selling
- **NOTHING** = Base Solid instance used as factory for creating new Solids
- **Total Supply** = Dynamic, starts at 0, increases with buys, decreases with sells
- **Bonding Curve** = Exponential-like pricing: `cost = K * sol * (2*supply + sol) / 2`
- **K** = Curve parameter (fixed at 1e9 = 1 gwei)

### Key Files

- **[src/Solid.sol](src/Solid.sol)** (~145 lines) - Main contract with bonding curve
- **[lib/isolid/ISolid.sol](lib/isolid/ISolid.sol)** (~95 lines) - Interface with NatSpec
- **[test/Solid.t.sol](test/Solid.t.sol)** (~165 lines) - Core tests
- **[test/SolidInvariant.t.sol](test/SolidInvariant.t.sol)** (~220 lines) - Invariant tests

## Core Operations

### 1. Make (Create New Solid)

```solidity
function make(string calldata name, string calldata symbol) external returns (ISolid sol)
```

**What it does:**
- Creates new Solid with name `name` and symbol `symbol`
- If Solid already exists, returns the existing instance (does not revert)
- No stake required (anyone can create for free)
- Starts with 0 supply - tokens are minted dynamically via bonding curve
- Uses CREATE2 for deterministic addresses

**Example:**
```solidity
ISolid H = N.make("Hydrogen", "H");
// H.totalSupply() = 0  // Starts at zero
// H.balanceOf(msg.sender) = 0
// address(H).balance = 0
```

### 2. Buy (ETH → Solid)

```solidity
function buy() public payable returns (uint256 sol)
```

**What it does:**
- Buys Solid tokens with ETH using bonding curve
- Mints new tokens to buyer
- Total supply increases
- Price increases exponentially with supply

**Formula:**
```solidity
// Solve: eth = K * sol * (2*s + sol) / 2
// Result: sol = sqrt(s² + 2*eth/K) - s
// where s = current supply, K = 1e9
```

**Example:**
```solidity
uint256 sol = H.buy{value: 1 ether}();
// Mints sol tokens to msg.sender
// Total supply increases by sol
// Contract ETH balance increases by 1 ether
```

### 3. Sell (Solid → ETH)

```solidity
function sell(uint256 sol) external nonReentrant returns (uint256 eth)
```

**What it does:**
- Sells Solid tokens for ETH using bonding curve
- Burns tokens from seller
- Total supply decreases
- Returns ETH to seller

**Formula:**
```solidity
eth = K * sol * (2*s - sol) / 2
// where s = current supply, K = 1e9
```

**Example:**
```solidity
uint256 eth = H.sell(100);
// Burns 100 Solid from msg.sender
// Total supply decreases by 100
// Transfers eth to msg.sender
```

## Mathematical Invariants

### 1. Supply Equals Balance Sum

```
totalSupply() = sum of all balanceOf(user) for all users
```

Buy mints new tokens, sell burns tokens. No tokens exist in a "pool" - they're all owned by users.

### 2. ETH Balance Integrity

```
address(solid).balance = total deposited - total withdrawn
```

Every buy adds ETH, every sell removes ETH. The contract balance exactly tracks the difference.

### 3. No Constant Product

Unlike constant-product AMMs, there is NO k = x * y invariant. Supply changes dynamically.

## Bonding Curve Math

### Cost Function

To buy `sol` tokens starting from supply `s`:
```
cost(s, sol) = K * sol * (2*s + sol) / 2
```

This is the integral of a linear price function `price(s) = K * s`.

### Refund Function

To sell `sol` tokens starting from supply `s`:
```
refund(s, sol) = K * sol * (2*s - sol) / 2
```

This is the inverse: selling from supply `s` gives back the cost of buying from `s - sol` to `s`.

### Quadratic Formula

Given `eth`, to find how many tokens can be bought:
```
eth = K * sol * (2*s + sol) / 2
Rearrange: K * sol² + 2 * K * s * sol - 2 * eth = 0
Solve: sol = sqrt(s² + 2*eth/K) - s
```

Implementation uses Babylonian square root method.

## Architecture

### Contract Structure

```solidity
contract Solid is ISolid, ERC20, ReentrancyGuardTransient {
    uint256 constant K = 1e9;
    ISolid public immutable NOTHING = this;
}
```

### State Variables

- `NOTHING` - Immutable self-reference (main instance for factory)
- `_name` - Token name (from ERC20)
- `_symbol` - Token symbol (from ERC20)
- `_balances` - Token balances mapping (from ERC20)
- `_totalSupply` - Dynamic total supply (from ERC20)

### Key Functions

**Query:**
- `buys(eth)` - Preview how many tokens `eth` would buy
- `sells(sol)` - Preview how much ETH selling `sol` would return
- `totalSupply()` - Current token supply (dynamic, starts at 0)

**Factory:**
- `made(name, symbol)` - Check if Solid exists and predict address
- `make(name, symbol)` - Create new Solid with deterministic address

**Trading:**
- `buy()` - Buy Solid with ETH (mints tokens)
- `sell(sol)` - Sell Solid for ETH (burns tokens)
- `sellFor(that, sol)` - Atomic swap this→ETH→that

**Internal:**
- `sqrt(x)` - Babylonian square root for quadratic formula
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

### Safe ETH Transfers

```solidity
(bool ok, bytes memory returned) = msg.sender.call{value: eth}("");
if (!ok) {
    if (returned.length > 0) {
        assembly {
            revert(add(returned, 32), mload(returned))
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

1. **Supply equals balance sum**: `sum(balanceOf(user)) == totalSupply()`
2. **ETH balance consistency**: `address(this).balance` accurately reflects deposited - withdrawn
3. **No negative supply**: Buy mints, sell burns, supply never goes negative

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
# After adding bonding curve function - test just that
forge test --match-test test_FirstBuy -vv

# After modifying sell logic - test sell operations
forge test --match-test test_BuySellRoundtrip -vv

# Quick compilation check
forge test --match-test test_Setup -vv
```

**When to run full tests:**
- Core protocol changes (bonding curve formulas)
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

# Default (256 runs, 500 depth) - ~20 seconds
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
- **Function declaration formatting**: When parameters don't fit on one line, use multi-line with proper indentation
- **Imports**: One per line, sorted alphabetically
- **Line length**: Max 120 characters (forge fmt default)
- **Indentation**: 4 spaces (configured in foundry.toml)

## Test Patterns

### Base Test Setup

```solidity
contract SolidTest is BaseTest {
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
}
```

**SolidUser** wraps operations with automatic logging and balance tracking.

### Example Test

```solidity
function test_BuySellRoundtrip() public {
    ISolid H = N.make("Hydrogen", "H");

    uint256 sol = H.buy{value: 1 ether}();
    uint256 ethReceived = H.sell(sol);

    assertLt(ethReceived, 1 ether, "should have net loss on roundtrip");
    assertEq(H.totalSupply(), 0, "supply should return to 0");
}
```

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
ISolid H = N.make("Hydrogen", "H");
// H.totalSupply() = 0  // Starts at zero
// H.balanceOf(msg.sender) = 0
// address(H).balance = 0
```

### Buying Solid with ETH

```solidity
uint256 sol = H.buy{value: 1 ether}();
// Mints sol tokens to msg.sender
// Total supply increases by sol
// Contract receives 1 ether
```

### Selling Solid for ETH

```solidity
uint256 eth = H.sell(500);
// Burns 500 Solid from msg.sender
// Total supply decreases by 500
// Transfers eth to msg.sender
```

### Checking State

```solidity
uint256 supply = H.totalSupply();  // Current dynamic supply
uint256 balance = H.balanceOf(user);  // User's token balance
uint256 contractEth = address(H).balance;  // ETH in contract
```

## Constants Reference

```solidity
K = 1e9  // Bonding curve parameter (1 gwei)
```

**Pricing Examples:**
- First token costs: ~1 gwei (K * 1 * 1 / 2)
- At supply 1e9: marginal price = ~1 gwei per token
- At supply 1e18: marginal price = ~1 ether per token

## Events

```solidity
event Make(ISolid indexed solid, string name, string symbol);
event Buy(ISolid indexed solid, uint256 eth, uint256 sol);
event Sell(ISolid indexed solid, uint256 sol, uint256 eth);
```

## Errors

```solidity
error Nothing();        // Called on NOTHING instance or empty name/symbol
error SellFailed();     // ETH transfer failed during sell
```

## Quick Reference

### State Queries

```solidity
uint256 supply = solid.totalSupply();  // Dynamic supply
uint256 balance = solid.balanceOf(user);  // User balance
uint256 contractEth = address(solid).balance;  // Contract ETH
```

### Bonding Curve Formulas

```solidity
// Buy: ETH → Tokens (mints)
sol = sqrt(s² + 2*eth/K) - s

// Sell: Tokens → ETH (burns)
eth = K * sol * (2*s - sol) / 2
```

### Metadata

```solidity
string memory name = solid.name();
string memory symbol = solid.symbol();
uint8 decimals = solid.decimals();    // 18 (default)
ISolid nothing = solid.NOTHING();     // Factory instance
```

## Key Differences from Traditional Bonding Curves

1. **Dynamic Supply**: Total supply starts at 0 and changes with buy/sell
2. **Simple Formula**: Uses quadratic cost function (integral of linear price)
3. **Native ETH**: Uses ETH directly (not WETH)
4. **Deterministic Addresses**: CREATE2 based on name+symbol
5. **Factory Pattern**: NOTHING instance creates all Solids
6. **No Liquidity Providers**: Pure bonding curve, no LP tokens
7. **Permissionless Creation**: Anyone can create Solids for free
8. **Atomic Swaps**: `sellFor()` enables one-transaction swaps between Solids

---

*This document is optimized for AI-assisted development. For human-readable introduction, see [README.md](README.md).*
