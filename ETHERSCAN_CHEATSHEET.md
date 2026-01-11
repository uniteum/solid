# Etherscan Cheatsheet: Solid Protocol

> Quick reference for trading Solids directly on Etherscan

## Quick Links

### NOTHING (Factory)
**Contract:** [`0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE`](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE)

- [Read Contract](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#readContract)
- [Write Contract](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#writeContract)
- [Make Function](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#writeContract#F3) - Create new Solids

### Hello World Example
**Contract:** [`0x9336b87315eBCF49ebC889865cC3D9bf58160564`](https://etherscan.io/address/0x9336b87315eBCF49ebC889865cC3D9bf58160564)

- [Read Contract](https://etherscan.io/address/0x9336b87315eBCF49ebC889865cC3D9bf58160564#readContract)
- [Write Contract](https://etherscan.io/address/0x9336b87315eBCF49ebC889865cC3D9bf58160564#writeContract)
- [Buy Function](https://etherscan.io/address/0x9336b87315eBCF49ebC889865cC3D9bf58160564#writeContract#F2) - Buy "Hello World" tokens

---

## Essential Operations

### 1. Create a New Solid

**On NOTHING Contract → Write Contract → `3. make`**

```
name: "My Token"
symbol: "MTKN"
```

**Result:**
- Deploys at deterministic address
- Total supply: 602,214,076,000,000,000,000,000 (Avogadro's number)
- Creator receives: 0 tokens (100% to pool)
- Starting price: 1 ETH = ~602,214 tokens

### 2. Check If Solid Exists

**On NOTHING Contract → Read Contract → `5. made`**

```
name: "My Token"
symbol: "MTKN"
```

**Returns:**
- `yes` = true/false (exists or not)
- `home` = contract address
- `salt` = CREATE2 salt used

### 3. Buy Tokens with ETH

**On Solid Contract → Write Contract → `2. buy`**

```
payableAmount (ether): 0.1
```

**Example (Hello World):**
Visit [Buy Function](https://etherscan.io/address/0x9336b87315eBCF49ebC889865cC3D9bf58160564#writeContract#F2)

### 4. Preview Buy Amount

**On Solid Contract → Read Contract → `2. buys`**

```
e (uint256): 100000000000000000  (0.1 ETH in wei)
```

**Returns:** Amount of tokens you'll receive

### 5. Sell Tokens for ETH

**On Solid Contract → Write Contract → `6. sell`**

```
s (uint256): 1000000000000000000000  (1000 tokens)
```

### 6. Preview Sell Amount

**On Solid Contract → Read Contract → `7. sells`**

```
s (uint256): 1000000000000000000000  (1000 tokens)
```

**Returns:** Amount of ETH you'll receive (in wei)

### 7. Check Pool State

**On Solid Contract → Read Contract → `6. pool`**

**Returns:**
- `S` = Solid tokens in pool
- `E` = Virtual ETH (actual balance + 1 ETH)

### 8. Check Token Balance

**On Solid Contract → Read Contract → `4. balanceOf`**

```
account (address): 0xYourAddressHere
```

### 9. Swap One Solid for Another

**On Source Solid → Write Contract → `7. sellFor`**

```
that (address): 0xTargetSolidAddress
s (uint256): 100000000000000000000  (100 tokens)
```

**Result:** Atomic swap in one transaction (Solid A → ETH → Solid B)

### 10. Preview Solid-to-Solid Swap

**On Source Solid → Read Contract → `8. sellsFor`**

```
that (address): 0xTargetSolidAddress
s (uint256): 100000000000000000000
```

---

## Wei Conversion Reference

Use these for entering amounts:

| Amount | Wei (18 decimals) |
|--------|-------------------|
| 0.001 ETH | `1000000000000000` |
| 0.01 ETH | `10000000000000000` |
| 0.1 ETH | `100000000000000000` |
| 1 ETH | `1000000000000000000` |
| 10 ETH | `10000000000000000000` |
| | |
| 1 token | `1000000000000000000` |
| 10 tokens | `10000000000000000000` |
| 100 tokens | `100000000000000000000` |
| 1000 tokens | `1000000000000000000000` |

**Quick converter:** [eth-converter.com](https://eth-converter.com/)

---

## Function Quick Reference

| Function | Location | Purpose | Payable |
|----------|----------|---------|---------|
| `make(name, symbol)` | NOTHING Write | Create new Solid | No |
| `made(name, symbol)` | NOTHING Read | Check if exists | No |
| `buy()` | Solid Write | Buy tokens with ETH | **Yes** |
| `buys(e)` | Solid Read | Preview buy amount | No |
| `sell(s)` | Solid Write | Sell tokens for ETH | No |
| `sells(s)` | Solid Read | Preview sell amount | No |
| `sellFor(that, s)` | Solid Write | Swap to another Solid | No |
| `sellsFor(that, s)` | Solid Read | Preview swap amount | No |
| `balanceOf(account)` | Solid Read | Check token balance | No |
| `pool()` | Solid Read | Check pool reserves | No |

---

## Common Workflows

### Workflow A: Buy Hello World Tokens

1. Go to [Hello World Buy](https://etherscan.io/address/0x9336b87315eBCF49ebC889865cC3D9bf58160564#writeContract#F2)
2. Connect wallet
3. Enter ETH amount (e.g., `0.1`)
4. Click "Write"
5. Confirm in wallet

### Workflow B: Create Your Own Solid

1. Go to [NOTHING Make](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#writeContract#F3)
2. Connect wallet
3. Enter name and symbol
4. Click "Write"
5. Find address in transaction logs (Look for "Make" event)

### Workflow C: Sell Tokens Back for ETH

1. Go to your Solid's Write Contract tab
2. Connect wallet
3. Find `6. sell`
4. Enter amount in wei (e.g., `1000000000000000000000` = 1000 tokens)
5. Click "Write"
6. Confirm in wallet

### Workflow D: Trade One Solid for Another

1. On Source Solid's Write Contract tab
2. Find `7. sellFor`
3. Enter:
   - `that`: Target Solid address
   - `s`: Amount to swap (in wei)
4. Click "Write"
5. Receive target tokens atomically

---

## Important Notes

### Creator Economics
- Creators receive **0% of supply**
- 100% goes to pool
- Creator must buy separately (fair launch)
- Creator can be first buyer (first-mover advantage)

### Pricing Mechanics
- **Starting price:** 1 ETH = ~602,214 tokens
- **Price floor:** Virtual 1 ETH ensures prices never fall below start
- **Price impact:** Large trades cause slippage
- **Formula:** Constant product (x * y = k)

### Security Tips
- Always verify contract addresses
- Preview amounts with read functions first
- Start with small amounts to test
- No approval needed for selling (you own the tokens)
- Gas fees apply to all write operations

### Gas Optimization
- Use preview functions (`buys`, `sells`, `sellsFor`) before executing
- Avoid failed transactions by checking balances first
- Trade during low gas periods (weekends, late night UTC)
- Use `sellFor` instead of sell+buy (saves gas)

---

## Example Addresses to Get Started

### NOTHING (Factory)
[`0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE`](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE)

### Hello World (Example Solid)
[`0x9336b87315eBCF49ebC889865cC3D9bf58160564`](https://etherscan.io/address/0x9336b87315eBCF49ebC889865cC3D9bf58160564)

Find more Solids by watching the [Make events](https://etherscan.io/address/0xB1c5929334BF19877faBBFC1CFb3Af8175b131cE#events) on NOTHING.

---

## Need Help?

- **Full Tutorial:** See [ETHERSCAN_TUTORIAL.md](lib/isolid/ETHERSCAN_TUTORIAL.md)
- **Documentation:** [CLAUDE.md](CLAUDE.md) and [README.md](README.md)
- **Interface Reference:** [ISolid.sol](lib/isolid/ISolid.sol)
- **Report Issues:** [GitHub Issues](https://github.com/uniteum/solid/issues)

---

**Pro Tip:** Bookmark this page along with your favorite Solids' Etherscan contracts for quick trading access!
