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
     * @return The percentage of ETH condensed into Solid
     * @notice Equal to 90% to discourage but not prevent expanding the token supply
     * All of the ETH goes into the pool, increasing the Solid price.
     */
    function CONDENSE_PERCENT() external view returns (uint256);

    /**
     * @notice Returns the current pool balances of Solid and ETH
     * @return solPool The amount of Solid in the pool
     * @return ethPool The amount of ETH in the pool
     */
    function pool() external view returns (uint256 solPool, uint256 ethPool);

    /**
     * @notice Sells Solid for ETH from the pool
     * @dev Uses constant-product formula: eth = ethPool - ethPool * solPool / (solPool + sol)
     * Transfers Solid from caller to pool, sends ETH to caller.
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
     * @notice Burns Solid and returns ETH according to the price indicated by the pool
     * @param sol The amount of Solid to vaporize
     * @return eth The amount of ETH received
     */
    function vaporize(uint256 sol) external returns (uint256 eth);

    /**
     * @notice Mints Solid to the caller according to the price indicated by the pool
     * Not all of the sent ETH is condensed, to discourage but not prevent expanding the token supply.
     * See CONDENSE_PERCENT.
     * All of the ETH goes into the pool, increasing the Solid price, and benefitting Solid holders.
     * @return sol The amount of condensed Solid
     */
    function condense() external payable returns (uint256 sol);

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
     * @dev Requires minimum stake of STAKE. Reverts if already made.
     * Mints 50% of SUPPLY to maker and 50% to pool. Initial ETH becomes pool liquidity.
     * Uses CREATE2 for deterministic deployment based on name and symbol.
     * @param name The name of the Solid
     * @param symbol The symbol of the Solid
     * @return sol The newly made Solid instance
     */
    function make(string calldata name, string calldata symbol) external payable returns (ISolid sol);

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
     * @notice Emitted when Solid are condensed (minted)
     * @param solid The condensed Solid
     * @param sender The address that condensed their eth
     * @param eth The amount of ETH condensed
     * @param sol The amount of Solid condensed
     */
    event Condense(ISolid indexed solid, address indexed sender, uint256 eth, uint256 sol);

    /**
     * @notice Emitted when Solid are vaporized (burned)
     * @param solid The vaporized Solid
     * @param sender The address that vaporized their tokens
     * @param sol The amount of Solid vaporized
     * @param eth The amount of ETH returned
     */
    event Vaporize(ISolid indexed solid, address indexed sender, uint256 sol, uint256 eth);

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
