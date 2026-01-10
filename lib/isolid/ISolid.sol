// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IERC20Metadata} from "ierc20/IERC20Metadata.sol";

/**
 * @notice Interface for Solid - a constant-product AMM for ETH/Solid pairs with deterministic deployment
 */
interface ISolid is IERC20Metadata {
    /**
     * @return The NOTHING implementation used as factory
     */
    function NOTHING() external view returns (ISolid);

    /**
     * @notice Returns the current pool balances of Solid and ETH
     * @dev E includes a virtual 1 ETH for initial pricing (actual balance + 1 ether)
     * The virtual 1 ETH creates a price floor - sell prices can never fall below starting price.
     * @return S The amount of Solid in the pool
     * @return E The virtual amount of ETH in the pool (actual + 1 ether)
     */
    function pool() external view returns (uint256 S, uint256 E);

    /**
     * @notice Returns the amount of ETH received for selling Solid from the pool
     * @dev Uses constant-product formula: e = E - E * S / (S + s)
     * ETH payout is capped at actual balance (virtual pricing may calculate higher).
     * @param s The amount of Solid to sell
     * @return e The amount of ETH received
     */
    function sells(uint256 s) external view returns (uint256 e);

    /**
     * @notice Sells Solid for ETH from the pool
     * @dev Uses constant-product formula: e = E - E * S / (S + s)
     * Transfers Solid from caller to pool, sends ETH to caller.
     * ETH payout is capped at actual balance (virtual pricing may calculate infinitesimally higher).
     * Protected by reentrancy guard.
     * @param s The amount of Solid to sell
     * @return e The amount of ETH received
     */
    function sell(uint256 s) external returns (uint256 e);

    /**
     * @notice Returns the amount of that Solid received for selling this Solid
     * @dev Calculates: sells(s) -> e, then that.buys(e) -> thats
     * @param that The Solid to receive
     * @param s The amount of this Solid to sell
     * @return thats The amount of that Solid that would be received
     */
    function sellsFor(ISolid that, uint256 s) external view returns (uint256 thats);

    /**
     * @notice Sells this Solid for another Solid in a single transaction
     * @dev Sells this Solid for ETH, then buys that Solid with the ETH.
     * No approval needed - uses internal _update.
     * Protected by reentrancy guard.
     * @param that The Solid to buy
     * @param s The amount of this Solid to sell
     * @return thats The amount of that Solid received
     */
    function sellFor(ISolid that, uint256 s) external returns (uint256 thats);

    /**
     * @notice Returns the amount of Solid received for buying with ETH from the pool
     * @dev Uses constant-product formula: s = S - S * (E - e) / E
     * @param e The amount of ETH sent
     * @return s The amount of Solid received
     */
    function buys(uint256 e) external view returns (uint256 s);

    /**
     * @notice Buys Solid with ETH from the pool
     * @dev Uses constant-product formula: s = S - S * (E - e) / E
     * Transfers Solid from pool to caller. Does not mint new tokens.
     * @return s The amount of Solid received
     */
    function buy() external payable returns (uint256 s);

    /**
     * @notice Checks if a Solid exists and computes its deterministic address
     * @dev Uses CREATE2 with salt = keccak256(abi.encode(name, symbol)) for deterministic deployment
     * @param name The name of the Solid
     * @param symbol The symbol of the Solid
     * @return yes True if the Solid with given name and symbol already exists
     * @return home The predicted (or actual if exists) contract address
     * @return salt The CREATE2 salt used for deployment (keccak256(abi.encode(name, symbol)))
     */
    function made(string calldata name, string calldata symbol)
        external
        view
        returns (bool yes, address home, bytes32 salt);

    /**
     * @notice Makes a new Solid instance with the given name and symbol
     * @dev If a Solid with the given name and symbol already exists, returns the existing instance.
     * Mints exactly AVOGADRO (6.02214076e23) tokens, 100% to pool.
     * Pool uses virtual 1 ETH for initial pricing, resulting in elegant starting price:
     * 1 ETH = ~602,214.076 solids (AVOGADRO / 10^18).
     * At $3,000/ETH, each solid starts at ~$0.005 USD (half a penny).
     * The virtual 1 ETH is permanent, creating a price floor - sell prices never fall below this.
     * Uses CREATE2 for deterministic deployment based on name and symbol.
     * @param name The name of the Solid
     * @param symbol The symbol of the Solid
     * @return solid The Solid instance (newly created or existing)
     */
    function make(string calldata name, string calldata symbol) external returns (ISolid solid);

    /**
     * @notice Emitted when a new Solid is made
     * @param solid The address of the newly made Solid
     * @param name The name of the Solid
     * @param symbol The symbol of the Solid
     */
    event Make(ISolid indexed solid, string name, string symbol);

    /**
     * @notice Emitted when Solid are bought with ETH
     * @param solid The Solid instance where buy occurred
     * @param e The amount of ETH spent
     * @param s The amount of Solid received
     */
    event Buy(ISolid indexed solid, uint256 e, uint256 s);

    /**
     * @notice Emitted when Solid are sold for ETH
     * @param solid The Solid instance where sell occurred
     * @param s The amount of Solid sold
     * @param e The amount of ETH received
     */
    event Sell(ISolid indexed solid, uint256 s, uint256 e);

    /**
     * @notice Thrown when name or symbol is empty in made() or make()
     */
    error Nothing();

    /**
     * @notice Thrown when ETH transfer to seller fails
     */
    error SellFailed(ISolid solid, uint256 s, uint256 e, uint256 E);
}
