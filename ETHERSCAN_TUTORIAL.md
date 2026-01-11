# Etherscan Tutorial: Using Solid Protocol

> Step-by-step guide to creating and trading Solids directly from Etherscan

## Prerequisites

- MetaMask, Coinbase Wallet, or WalletConnect-compatible wallet
- Some ETH for gas fees and trading
- Ethereum mainnet connection

## NOTHING Contract

All Solid protocol interactions start with the **NOTHING** contract:

**Address:** [`0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE`](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE)

---

## Part 1: Creating Your First Solid

### Step 1: Connect Your Wallet

1. Go to [NOTHING Write Contract page](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#writeContract)
2. Click **"Connect to Web3"** button
3. Select your wallet (MetaMask, Coinbase Wallet, or WalletConnect)
4. Approve the connection in your wallet

### Step 2: Check If Your Solid Already Exists

Before creating, check if someone already made your Solid:

1. Go to [NOTHING Read Contract page](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#readContract)
2. Find function **`5. made`**
3. Enter your desired:
   - `name` (e.g., "Hydrogen")
   - `symbol` (e.g., "H")
4. Click **"Query"**

**Results:**
- `yes` = `true` → Already exists at the `home` address
- `yes` = `false` → Available to create

### Step 3: Create a New Solid

1. Go back to [Write Contract page](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#writeContract)
2. Find function **`3. make`**
3. Enter:
   - `name`: Token name (e.g., "Hydrogen")
   - `symbol`: Token symbol (e.g., "H")
4. Click **"Write"**
5. Confirm transaction in your wallet
6. Wait for confirmation

**What Happens:**
- A new Solid is deployed at a deterministic address
- Total supply: 602,214,076,000,000,000,000,000 tokens (Avogadro's number)
- **You receive:** 0 tokens (creator gets nothing)
- **Pool receives:** 100% of supply
- **Starting price:** 1 ETH = ~602,214.076 tokens (~$0.005/token at $3k ETH)
- **Price floor:** Virtual 1 ETH ensures prices never fall below starting price

### Step 4: Find Your Solid's Address

After creation, get the contract address:

**Method 1 - From Transaction:**
1. Click your transaction hash
2. Look for the **"Make"** event in the Logs tab
3. The `solid` parameter is your new contract address

**Method 2 - Using `made()`:**
1. Go to [Read Contract page](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#readContract)
2. Call **`5. made`** with your name and symbol
3. The `home` address is your Solid's contract

---

## Part 2: Buying Solids with ETH

### Step 1: Check the Price

Before buying, preview how many tokens you'll get:

1. Go to your Solid's contract page on Etherscan
2. Click **"Contract"** → **"Read Contract"**
3. Find function **`2. buys`**
4. Enter ETH amount in wei:
   - 0.1 ETH = `100000000000000000` (17 zeros)
   - 1 ETH = `1000000000000000000` (18 zeros)
5. Click **"Query"**

**Result:** Number of tokens you'll receive (with 18 decimals)

### Step 2: Buy Tokens

1. Go to **"Write Contract"** tab
2. Click **"Connect to Web3"**
3. Find function **`2. buy`**
4. In the **payable ETH amount** field (top of function):
   - Enter amount like `0.1` for 0.1 ETH
5. Click **"Write"**
6. Confirm transaction in wallet

**Result:** Tokens transfer from pool to your wallet

### Example: Buying Hydrogen

Let's say Hydrogen is at `0x1234...` (example address):

1. Visit `https://etherscan.io/address/0x1234...#writeContract`
2. Connect wallet
3. Use `buy()` with 0.5 ETH
4. You receive ~301,107 H tokens (approximately)

---

## Part 3: Selling Solids for ETH

### Step 1: Check Your Balance

1. Go to your Solid's contract **"Read Contract"** tab
2. Find function **`4. balanceOf`**
3. Enter your wallet address
4. Click **"Query"**

**Result:** Your token balance (with 18 decimals)

### Step 2: Preview Sell Price

1. On same **"Read Contract"** tab
2. Find function **`7. sells`**
3. Enter amount to sell (in wei with 18 decimals):
   - Example: `100000000000000000000` = 100 tokens
4. Click **"Query"**

**Result:** ETH you'll receive (in wei)

### Step 3: Sell Tokens

1. Go to **"Write Contract"** tab
2. Connect wallet if needed
3. Find function **`6. sell`**
4. Enter `s` (amount to sell in wei):
   - Example: `50000000000000000000` = 50 tokens
5. Click **"Write"**
6. Confirm transaction

**Result:** Tokens transfer to pool, ETH transfers to your wallet

---

## Part 4: Trading One Solid for Another

This is the most powerful feature - swap tokens in a single transaction!

### Example: Trading Hydrogen for Oxygen

Assume you have:
- Hydrogen (H) at `0xH111...`
- Oxygen (O) at `0xO222...`
- 100 H tokens in your wallet

### Step 1: Preview the Trade

1. Go to Hydrogen contract **"Read Contract"** tab
2. Find function **`8. sellsFor`**
3. Enter:
   - `that`: Oxygen contract address `0xO222...`
   - `s`: Amount to trade `100000000000000000000` (100 tokens)
4. Click **"Query"**

**Result:** Amount of Oxygen tokens you'll receive

### Step 2: Execute the Trade

1. Go to Hydrogen **"Write Contract"** tab
2. Connect wallet
3. Find function **`7. sellFor`**
4. Enter:
   - `that`: Oxygen contract address `0xO222...`
   - `s`: Amount to trade `100000000000000000000`
5. Click **"Write"**
6. Confirm transaction

**What Happens (atomically):**
1. Your 100 H tokens → Hydrogen pool
2. Hydrogen pool → ETH to you (internal)
3. That ETH → Oxygen pool (internal)
4. Oxygen pool → O tokens to you

**Result:** You now have Oxygen tokens instead of Hydrogen!

---

## Part 5: Understanding Pool State

### Checking Pool Reserves

1. Go to any Solid's **"Read Contract"** tab
2. Find function **`6. pool`**
3. Click **"Query"**

**Returns:**
- `S` = Solid tokens in pool
- `E` = Virtual ETH (actual balance + 1 ETH)

**Important:** The pool adds 1 ETH virtually for pricing. This creates:
- Initial price discovery (even with 0 actual ETH)
- Permanent price floor (sell prices never fall below starting price)

### Example Pool States

**Newly Created Solid:**
```
S = 602214076000000000000000 (100% of supply)
E = 1000000000000000000 (1 ETH virtual, 0 actual)
Price = 1 ETH buys ~602,214 tokens
```

**After 10 ETH of Buys:**
```
S = ~540,000,000,000,000,000,000,000 (decreased)
E = ~11,000,000,000,000,000,000 (10 actual + 1 virtual)
Price = 1 ETH buys ~49,090 tokens (price increased)
```

---

## Part 6: Common Trading Scenarios

### Scenario A: Providing Liquidity

**Goal:** Add ETH liquidity to a Solid pool

1. Use **`buy()`** with your desired ETH amount
2. Keep the tokens (don't sell immediately)
3. Pool ETH increases, making it more liquid
4. You can sell back anytime to exit

**Note:** No LP tokens - the Solid tokens ARE your liquidity position

### Scenario B: Arbitrage with External Exchanges

**Goal:** Profit from price differences between Solid protocol and external exchanges (like Uniswap)

**Note:** There is NO internal arbitrage within Solid - each Solid has only one pool with deterministic pricing. Arbitrage only exists between the Solid protocol and external DEXes.

**Example:** If Hydrogen (H) trades on both Solid and Uniswap:

1. Check price on Solid: **`H.buys(1 ether)`** → X tokens
2. Check price on Uniswap for same H/ETH pair
3. If Solid price < Uniswap price:
   - Buy H on Solid: **`H.buy{value: 1 ether}()`**
   - Sell H on Uniswap for more ETH
4. If Uniswap price < Solid price:
   - Buy H on Uniswap with ETH
   - Sell H on Solid: **`H.sell(amount)`**
5. Profit = final ETH - starting ETH - gas costs

### Scenario C: Direct Solid-to-Solid Swaps

**Goal:** Trade H → O (Hydrogen → Oxygen) in one atomic transaction

**Example:** Swap 1000 H for O:

1. Check expected output: **`H.sellsFor(O_address, 1000)`** → Y tokens
2. Execute swap: **`H.sellFor(O_address, 1000)`**
   - Sells 1000 H for ETH internally
   - Buys O with that ETH internally
   - Returns O tokens to you atomically

**Why use it?**
- **Same pricing** as doing H→ETH then ETH→O separately
- **Lower gas costs** - one transaction instead of two
- **Atomic execution** - no risk of price changes between steps
- **More convenient** - simpler to execute

---

## Tips & Best Practices

### Gas Optimization

- **Batch operations** when possible
- **Preview first** using read functions to avoid failed transactions
- Trade during **lower gas times** (weekends, late night UTC)

### Understanding Decimals

All amounts use 18 decimals:
- `1` token = `1000000000000000000` wei
- `0.5` ETH = `500000000000000000` wei
- Use converters: [eth-converter.com](https://eth-converter.com/)

### Price Impact

Large trades cause slippage:
- Buying increases price (you pay more per token as you buy)
- Selling decreases price (you receive less per token as you sell)
- Check **`buys()`** / **`sells()`** first to estimate impact

### Security

- **Always verify** contract addresses (check against official sources)
- **Start small** to test the flow
- **Understand** that creator gets 0% (100% goes to pool)
- **No approval needed** for `sell()` or `sellFor()` (you sell your own tokens)

---

## Quick Reference

### Key Functions by Use Case

| Action | Function | Tab | Payable |
|--------|----------|-----|---------|
| Create Solid | `make(name, symbol)` | Write | No |
| Check if exists | `made(name, symbol)` | Read | No |
| Buy with ETH | `buy()` | Write | **Yes** |
| Sell for ETH | `sell(s)` | Write | No |
| Swap Solids | `sellFor(that, s)` | Write | No |
| Preview buy | `buys(e)` | Read | No |
| Preview sell | `sells(s)` | Read | No |
| Preview swap | `sellsFor(that, s)` | Read | No |
| Check balance | `balanceOf(address)` | Read | No |
| Check pool | `pool()` | Read | No |

### Important Addresses

- **NOTHING (Factory):** [`0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE`](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE)
- **Your Solid:** Use `made()` to find address

### Need Help?

- [Full Documentation](https://github.com/uniteum/solid)
- [ISolid Interface Reference](https://github.com/uniteum/isolid)
- Report issues: [GitHub Issues](https://github.com/uniteum/solid/issues)

---

**Pro Tip:** Bookmark your favorite Solids' Etherscan pages for quick access to Read/Write Contract tabs!
