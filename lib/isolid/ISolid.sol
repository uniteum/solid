// SPDX-License-Identifier: MIT
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
     * @return The minimum stake required to make a new Solid token
     */
    function STAKE() external view returns (uint256);

    /**
     * @notice Returns the current pool balances of Solid and ETH
     * @dev ethPool includes a virtual 1 ETH for initial pricing (actual balance + 1 ether)
     * @return solPool The amount of Solid in the pool
     * @return ethPool The virtual amount of ETH in the pool (actual + 1 ether)
     */
    function pool() external view returns (uint256 solPool, uint256 ethPool);

    /**
     * @notice Sells Solid for ETH from the pool
     * @dev Uses constant-product formula: eth = ethPool - ethPool * solPool / (solPool + sol)
     * Transfers Solid from caller to pool, sends ETH to caller.
     * ETH payout is capped at actual balance (virtual pricing may calculate higher).
     * Protected by reentrancy guard.
     * @param sol The amount of Solid to sell
     * @return eth The amount of ETH received
     */
    function sell(uint256 sol) external returns (uint256 eth);

    /**
     * @notice Buys Solid with ETH from the pool
     * @dev Uses constant-product formula: sol = solPool - solPool * (ethPool - eth) / ethPool
     * Transfers Solid from pool to caller. Does not mint new tokens.
     * @return sol The amount of Solid received
     */
    function buy() external payable returns (uint256 sol);

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
     * @dev No stake required. Reverts if already made.
     * Mints 100% of SUPPLY to pool. Pool uses virtual 1 ETH for initial pricing.
     * Uses CREATE2 for deterministic deployment based on name and symbol.
     * @param name The name of the Solid
     * @param symbol The symbol of the Solid
     * @return sol The newly made Solid instance
     */
    function make(string calldata name, string calldata symbol) external returns (ISolid sol);

    /**
     * @notice Emitted when a new Solid is made
     * @param solid The address of the newly made Solid
     * @param name The name of the Solid (indexed)
     * @param symbol The symbol of the Solid (indexed)
     */
    event Make(ISolid indexed solid, string name, string symbol);

    /**
     * @notice Emitted when Solid are bought with ETH
     * @param solid The Solid instance where buy occurred
     * @param eth The amount of ETH spent
     * @param sol The amount of Solid received
     */
    event Buy(ISolid indexed solid, uint256 eth, uint256 sol);

    /**
     * @notice Emitted when Solid are sold for ETH
     * @param solid The Solid instance where sell occurred
     * @param sol The amount of Solid sold
     * @param eth The amount of ETH received
     */
    event Sell(ISolid indexed solid, uint256 sol, uint256 eth);

    /**
     * @notice Thrown when name or symbol is empty in made() or make()
     */
    error Nothing();

    /**
     * @notice Thrown when ETH transfer to seller fails
     */
    error SellFailed();

    /**
     * @notice Thrown when stake is less than STAKE in make()
     * @param sent The amount of ETH sent
     * @param required The required minimum ETH stake
     */
    error StakeLow(uint256 sent, uint256 required);

    /**
     * @notice Thrown when attempting to make a Solid that has already been made
     * @param name The name of the Solid
     * @param symbol The symbol of the Solid
     */
    error MadeAlready(string name, string symbol);
}
