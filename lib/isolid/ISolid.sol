// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20Metadata} from "ierc20/IERC20Metadata.sol";

/**
 * @notice Interface for Solid - a constant-product AMM for ETH/SOL pairs with deterministic deployment
 */
interface ISolid is IERC20Metadata {
    /**
     * @notice Returns the NOTHING instance (the base Solid used as factory)
     * @return The immutable NOTHING Solid instance
     */
    function NOTHING() external view returns (ISolid);

    /**
     * @notice Returns the minimum stake required to make a new Solid
     * @return The minimum ETH stake required (default 0.001 ether)
     */
    function STAKE() external view returns (uint256);

    /**
     * @notice Returns the current pool balances of SOL tokens and ETH
     * @return solPool The amount of SOL tokens in the pool
     * @return ethPool The amount of ETH in the pool
     */
    function pool() external view returns (uint256 solPool, uint256 ethPool);

    /**
     * @notice Sells SOL tokens for ETH from the pool
     * @dev Uses constant-product formula: eth = ethPool - ethPool * solPool / (solPool + sol)
     * Transfers SOL tokens from caller to pool, sends ETH to caller.
     * Protected by reentrancy guard.
     * @param sol The amount of SOL tokens to sell
     * @return eth The amount of ETH received
     */
    function sell(uint256 sol) external returns (uint256 eth);

    /**
     * @notice Buys SOL tokens with ETH from the pool
     * @dev Uses constant-product formula: sol = solPool - solPool * (ethPool - eth) / ethPool
     * Transfers SOL tokens from pool to caller. Does not mint new tokens.
     * @return sol The amount of SOL tokens received
     */
    function buy() external payable returns (uint256 sol);

    /**
     * @notice Burns (vaporizes) SOL tokens from the caller's balance
     * @dev Permanently removes tokens from circulation, reducing total supply.
     * This is a one-way operation - vaporized tokens cannot be recovered.
     * @param sol The amount of SOL tokens to vaporize
     */
    function vaporize(uint256 sol) external;

    /**
     * @notice Checks if a Solid exists and computes its deterministic address
     * @dev Uses CREATE2 with salt = keccak256(abi.encode(name, symbol)) for deterministic deployment
     * @param name The name of the Solid token
     * @param symbol The symbol of the Solid token
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
     * @dev Requires minimum stake of STAKE. Reverts if already made.
     * Mints 50% of SUPPLY to maker and 50% to pool. Initial ETH becomes pool liquidity.
     * Uses CREATE2 for deterministic deployment based on name and symbol.
     * @param name The name of the Solid token
     * @param symbol The symbol of the Solid token
     * @return sol The newly made Solid instance
     */
    function make(string calldata name, string calldata symbol) external payable returns (ISolid sol);

    /**
     * @notice Emitted when a new Solid is made
     * @param solid The address of the newly made Solid
     * @param name The name of the Solid token (indexed)
     * @param symbol The symbol of the Solid token (indexed)
     */
    event Make(ISolid indexed solid, string indexed name, string indexed symbol);

    /**
     * @notice Emitted when SOL tokens are bought with ETH
     * @param solid The Solid instance where buy occurred
     * @param eth The amount of ETH spent
     * @param sol The amount of SOL tokens received
     */
    event Buy(ISolid indexed solid, uint256 eth, uint256 sol);

    /**
     * @notice Emitted when SOL tokens are sold for ETH
     * @param solid The Solid instance where sell occurred
     * @param sol The amount of SOL tokens sold
     * @param eth The amount of ETH received
     */
    event Sell(ISolid indexed solid, uint256 sol, uint256 eth);

    /**
     * @notice Emitted when SOL tokens are vaporized (burned)
     * @param solid The Solid instance where vaporization occurred
     * @param burner The address that vaporized their tokens
     * @param sol The amount of SOL tokens vaporized
     */
    event Vaporize(ISolid indexed solid, address indexed burner, uint256 sol);

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
     * @param name The name of the Solid token
     * @param symbol The symbol of the Solid token
     */
    error MadeAlready(string name, string symbol);
}
