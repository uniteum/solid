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
     * @notice Returns the amount of ETH received for selling Solid
     * @dev Uses bonding curve: eth = K * sol * (2*supply - sol) / 2
     * @param sol The amount of Solid to sell
     * @return eth The amount of ETH received
     */
    function sells(uint256 sol) external view returns (uint256 eth);

    /**
     * @notice Returns the amount of that Solid received for selling this Solid
     * @dev Calculates: sells(sol) -> eth, then that.buys(eth) -> thats
     * @param that The Solid to receive
     * @param sol The amount of this Solid to sell
     * @return thats The amount of that Solid that would be received
     */
    function sellsFor(ISolid that, uint256 sol) external view returns (uint256 thats);

    /**
     * @notice Sells Solid for ETH, burning the tokens
     * @dev Uses bonding curve: eth = K * sol * (2*supply - sol) / 2
     * Burns Solid from caller, sends ETH to caller.
     * Protected by reentrancy guard.
     * @param sol The amount of Solid to sell
     * @return eth The amount of ETH received
     */
    function sell(uint256 sol) external returns (uint256 eth);

    /**
     * @notice Sells this Solid for another Solid in a single transaction
     * @dev Sells this Solid for ETH, then buys that Solid with the ETH.
     * No approval needed - uses internal _update.
     * Protected by reentrancy guard.
     * @param that The Solid to buy
     * @param sol The amount of this Solid to sell
     * @return thats The amount of that Solid received
     */
    function sellFor(ISolid that, uint256 sol) external returns (uint256 thats);

    /**
     * @notice Returns the amount of Solid received for buying with ETH
     * @dev Uses bonding curve: eth = K * sol * (2*supply + sol) / 2, solved for sol
     * @param eth The amount of ETH sent
     * @return sol The amount of Solid received
     */
    function buys(uint256 eth) external view returns (uint256 sol);

    /**
     * @notice Buys Solid with ETH, minting new tokens
     * @dev Uses bonding curve to calculate amount. Mints new tokens to buyer.
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
     * @dev If a Solid with the given name and symbol already exists, returns the existing instance.
     * Starts with zero supply - tokens are minted dynamically via exponential bonding curve.
     * Uses CREATE2 for deterministic deployment based on name and symbol.
     * @param name The name of the Solid
     * @param symbol The symbol of the Solid
     * @return sol The Solid instance (newly created or existing)
     */
    function make(string calldata name, string calldata symbol) external returns (ISolid sol);

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
}
