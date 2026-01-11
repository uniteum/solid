# Why You Should Make and Trade Solids

> **For the crypto hobbyist who's tired of fragmented liquidity and wants to launch tokens the right way.**

## What Are Solids?

Solids are ERC-20 tokens with **built-in ETH liquidity**. Every Solid token you make comes with an automated market maker (AMM) baked directly into the token contract itself.

No external DEXs. No liquidity fragmentation. No complicated pool deployments. No tokens for the creator.

**Just make a token, and it's instantly tradeable for everyone.**

## The Problem with Normal Tokens

You've probably been through this before:

1. Make an ERC-20 token
2. Deploy it to mainnet
3. Now what? It's worthless without liquidity
4. Set up a Uniswap pool (more gas, more complexity)
5. Provide initial liquidity (lock up capital)
6. Hope traders find your pool
7. Deal with liquidity fragmentation across multiple DEXs

**With Solids, steps 3-7 disappear.**

## How Solids Work

### Creating a Solid (Making)

Making a new Solid is **completely free** - you only pay gas. Thanks to EIP-1167 minimal proxy cloning, the gas cost is incredibly low - only **~198,000 gas**. At typical gas prices, that's:

- **10 gwei** (quiet times): ~$0.60 in gas
- **25 gwei** (moderate): ~$1.50 in gas
- **50 gwei** (busy): ~$3.00 in gas

```solidity
// Make a new Solid token - free creation!
solid.make("MyToken", "MTK");  // Just pay gas
```

**How the distribution works:**

When you make a Solid, the economics are radically different from traditional tokens:

- **0% to maker** - You get nothing except first mover advantage
- **100% to the pool** - All tokens go to everyone else
- The total supply is exactly **Avogadro's number**: **6.02214076 × 10²³** tokens
- A **deterministic address** (same name+symbol always produces same address)
- An **instantly tradeable token** with built-in liquidity

**This is honest creation.** You don't get free tokens, but you do get first access to buy at the initial price - a fair advantage for taking the initiative to create.

**Virtual pricing magic:**

Even with 0 actual ETH, the pool assumes a **virtual 1 ETH** for pricing. This creates an elegant starting price:

- **1 ETH = ~602,214.076 solids** (Avogadro's number / 10¹⁸)
- At $3,000/ETH: **~$0.005 per solid** (half a penny)
- This virtual ETH creates a **permanent price floor** - sell prices can never fall below this

When you send ETH during creation, it adds to the virtual 1 ETH, immediately increasing the starting price.

### Trading Solids

**Deposit ETH, buy tokens:**
```solidity
// Buy tokens by depositing ETH
solid.buy{value: 1 ether}();
// Returns tokens based on constant-product formula
```

**Sell tokens, get ETH:**
```solidity
// Sell tokens back for ETH
solid.sell(1000000000);
```

## Why Solids Are Better

### 1. Extremly Low Setup Friction

**Traditional approach:**
- Deploy token contract: ~2,000,000 gas (~$50+ at 25 gwei)
- Approve router: ~50,000 gas (~$1)
- Make Uniswap pool: ~4,000,000 gas (~$100+)
- Add liquidity: ~150,000 gas (~$4)
- **Total: $155+ and 4 transactions** (at 25 gwei)

**Solids approach (using EIP-1167 cloning):**
- Make token: ~198,000 gas (~$1.50 at 25 gwei)
- **Total: ~$1.50 and 1 transaction**

You save **99%** on costs plus all the complexity. Creating a tradeable token costs less than a coffee.

### 2. Liquidity Can't Leave - Only Grow

With traditional DEX pools, liquidity providers can rug at any time, killing your token's tradability.

**With Solids, 100% of token liquidity is locked in the contract.** The pool can never be drained. Your token is always tradeable.

**Even better:** The virtual 1 ETH creates a **permanent price floor**, and anyone can boost the pool by sending ETH directly to the contract. The intrinsic value can only increase, never decrease.

### 3. Genuinely Fair Launch

- **0% to maker** - You receive zero tokens automatically
- **100% to the pool** - All tokens available for public trading from block one
- No presales, no VC allocation, no team vesting
- The economics are transparent and hardcoded
- **First-mover advantage only:** As creator, you can buy first at the initial price

This is a genuinely fair launch. The creator gets the same opportunity as anyone else - they can buy tokens at the starting price. No pre-allocation, no insider discount, just the natural advantage of being first.

### 4. Deterministic Addresses

The same name and symbol always produce the same contract address. This means:
- **No frontrunning** - if someone tries to steal your token name, they make the same address you would have
- **Predictable deployments** - you can calculate addresses off-chain
- **No name squatting** - everyone has access to all Solid tokens

### 5. Chemistry-Inspired Economics with Price Floor Guarantee

The total supply is exactly **Avogadro's number**: **6.02214076 × 10²³** tokens.

Why? Because if you're going to make internet money, you might as well base it on fundamental physical constants. With the virtual 1 ETH pricing:

- **Starting price**: 1 ETH = ~602,214.076 solids (Avogadro / 10¹⁸)
- **Price floor**: The virtual 1 ETH ensures sell prices can never fall below this
- **Elegant relationship**: "One ETH buys Avogadro's number divided by 10¹⁸"

It's nerdy. It's fun. It's memorable. And unlike most tokens, Solids have a guaranteed minimum value.

## Real Use Cases for Hobbyists

### Community Tokens

Launch a token for your Discord, DAO, or group chat in one transaction. Instant tradability means your community can start trading immediately. Community members can even boost the token's intrinsic value by sending ETH directly to it.

### Experimental Economics

Want to test token bonding curves, game theory, or coordination mechanisms? Solids remove all the setup overhead so you can focus on the experiment.

### Memecoins Done Right

Every memecoin needs liquidity. With Solids, you skip straight to the fun part - building community and culture - without worrying about pools and liquidity management.

### NFT Project Tokens

Already have an NFT project? Launch a Solid as your ecosystem token. The fair launch mechanics and permanent liquidity make it perfect for community governance tokens.

### Personal Currency

Make a token representing you. Trade it with friends. Use it as social money. With a ~$1.50 creation cost (just gas), why not?

## Technical Details (For the Curious)

### Constant-Product AMM

When you buy with ETH:
```
tokens_out = pool_tokens × eth_in / pool_eth
```

When you sell tokens for ETH:
```
eth_out = pool_eth - (pool_eth × pool_tokens) / (pool_tokens + tokens_in)
```

**Key insight:** The pool always includes a **virtual 1 ETH** for pricing, even when actual ETH balance is 0. This creates the permanent price floor and elegant starting price of ~602,214 solids per ETH.

Same formula as Uniswap v2, but gas-optimized and built into the token.

### Security Features

- **Reentrancy protection** via EIP-1153 transient storage
- **Deterministic deployments** using OpenZeppelin Clones (EIP-1167)
- **Immutable parameters** - supply and distribution can't change
- **No admin keys** - completely decentralized after creation

### Gas Costs

Thanks to EIP-1167 minimal proxy cloning, Solids are extremely gas-efficient:

- **Make new Solid**: ~198,000 gas
  - At 10 gwei: **$0.60**
  - At 25 gwei: **$1.50**
  - At 50 gwei: **$3.00**
- **Buy with ETH**: ~50,000 gas ($0.30-$1.50)
- **Sell tokens**: ~60,000 gas ($0.40-$1.80)

**Why so cheap?** EIP-1167 clones don't redeploy the full contract bytecode. They deploy a tiny proxy that delegates to the NOTHING template. This makes creation **50-100x cheaper** than deploying a traditional token contract.

Compare:
- Traditional ERC-20 + Uniswap setup: ~$155 total
- Solids: ~$1.50 total (just gas, no stake required)

## Getting Started

### Using Etherscan to Interact with Solids

You don't need to write any code - you can create and trade Solids directly through Etherscan.io!

#### 1. Find the NOTHING Contract

The "NOTHING" contract is the factory for all Solids. Go to its address on Etherscan (deployed at a deterministic address on mainnet and L2s).

#### 2. Make Your Solid via Etherscan

1. On Etherscan, go to the **Contract** tab
2. Click **Write Contract**
3. Click **Connect to Web3** and connect your wallet (MetaMask, WalletConnect, etc.)
4. Find the **make** function
5. Enter the following:
   - **payableAmount (ether)**: Optional - leave as `0` for free creation, or send ETH to bootstrap liquidity
   - **name (string)**: Your token name (e.g., `"MyToken"`)
   - **symbol (string)**: Your token symbol (e.g., `"MTK"`)
6. Click **Write** and confirm the transaction

That's it! Your Solid is now created with instant liquidity. Remember: you get 0 free tokens, but you can buy first at the initial price alongside everyone else.

#### 3. Find Your New Solid's Address

After the transaction confirms:
1. Click on the transaction hash
2. Look in the **Logs** section
3. Find the **Make** event - it will show your new Solid's contract address
4. Click on that address to view your new token contract

#### 4. Trade Your Solid via Etherscan

To **buy tokens** (spend ETH, receive solids):
1. Go to your Solid's contract on Etherscan
2. Click **Contract** → **Write Contract**
3. Connect your wallet
4. Find the **buy** function
5. Enter ETH amount in **payableAmount**
6. Click **Write** and confirm

To **sell tokens** (spend solids, receive ETH):
1. Same contract, **Write Contract** tab
2. Find the **sell** function
3. Enter the amount of tokens to sell (in wei, with 18 decimals)
   - Example: `1000000000000000000` = 1 solid token
4. Click **Write** and confirm

To **boost the pool** (permanently increase value for all holders):
- Simply send ETH directly to the Solid's contract address from your wallet
- This raises the price floor for everyone - pure altruism!

#### 5. Check Pool Status

To see the current pool state:
1. Go to **Read Contract** tab
2. Find the **pool** function
3. Click **Query** - it returns:
   - **solPool**: SOL tokens in the pool
   - **ethPool**: ETH in the pool (in wei)

You can also check:
- **balanceOf**: Your token balance (enter your address)
- **totalSupply**: Always exactly Avogadro's number (6.02214076 × 10²³)
- **name** and **symbol**: Token metadata

## FAQ

**Q: Wait, I get ZERO tokens as the creator?**
A: Correct - you receive zero tokens automatically. However, you can buy at the initial price just like anyone else. Your advantage is being first, not getting free tokens or a special discount. It's a fair first-mover advantage.

**Q: Can I remove liquidity?**
A: No. 100% of tokens are permanently locked in the pool. The virtual 1 ETH creates an unremovable price floor. This is a feature - it prevents rugs.

**Q: What if someone else makes my token name?**
A: They can't "steal" it - the same name+symbol always produces the same address. Being first to create gives you the chance to buy at the initial price, which is the natural reward for taking initiative.

**Q: Can I make multiple Solids?**
A: Yes! It's completely free (just gas). Make as many as you want.

**Q: Should I send ETH when making a Solid?**
A: Only if you want to bootstrap initial liquidity for the community. The token works fine with 0 ETH (thanks to virtual pricing), but adding ETH immediately boosts the price.

**Q: Can I increase the ETH pool after making a token?**
A: Yes! Anyone can send ETH directly to the contract address. This permanently increases the price floor for all holders - pure altruism.

**Q: What blockchain is this on?**
A: Ethereum mainnet and major L2s (Base, Arbitrum, Optimism, Polygon).

**Q: Is this audited?**
A: The code uses battle-tested OpenZeppelin primitives and standard AMM math. Review the code yourself - it's less than 100 lines.

**Q: What's the catch?**
A: No catch. It's an experiment in pure public goods and permanent liquidity. The only "cost" is gas (~$1.50).

**Q: Can I use this for serious projects?**
A: The contracts are simple and secure, but do your own research. Start small, test thoroughly.

## Philosophy

Solids are built on four principles:

1. **Simplicity** - One transaction, ~$1.50 in gas, instant tradeable token
2. **Permanence** - Virtual 1 ETH price floor that can never be removed
3. **Fairness** - 0% free allocation, everyone buys at market price
4. **Honest Incentives** - Creator's only advantage is buying first at initial price

We believe the best tokens reward initiative fairly. You don't get free tokens, but you do get first access - a reasonable advantage for creating something valuable.

## Try It Today

The future of token launches is simple, fair, and permanent.

**Make your first Solid. See how it feels to launch a token with instant liquidity.**

Then make another one for fun.

---

**Still skeptical?** Read the [smart contract code](https://etherscan.io/address/TBD#code) - it's less than 100 lines. No hidden surprises.

**Built by crypto hobbyists, for crypto hobbyists.**

*Make something. Make it Solid.*
