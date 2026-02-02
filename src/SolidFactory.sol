// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Solid} from "./Solid.sol";

/**
 * @notice Factory for batch creation and purchasing of Solid tokens
 */
contract SolidFactory {
    Solid public immutable NOTHING;

    struct SolidMade {
        address home;
        bool made;
        string name;
        string symbol;
    }

    struct SolidSpec {
        string name;
        string symbol;
    }

    struct BuySpec {
        string name;
        string symbol;
        uint256 eth;
    }

    struct BuyResult {
        ISolid solid;
        uint256 eth;
        uint256 tokens;
    }

    error InsufficientETH(uint256 required, uint256 sent);

    event MadeBatch(uint256 created, uint256 total);
    event BoughtBatch(uint256 total, uint256 ethSpent);

    constructor(Solid solid) {
        NOTHING = solid;
    }

    /**
     * @notice Check which solids exist and which don't
     * @param solids Array of solids to check
     * @return mades Array of SolidMade structs with details about each solid
     */
    function made(SolidSpec[] calldata solids) public view returns (SolidMade[] memory mades) {
        mades = new SolidMade[](solids.length);

        // First pass: count
        for (uint256 i = 0; i < solids.length; i++) {
            (bool yes, address home,) = NOTHING.made(solids[i].name, solids[i].symbol);
            mades[i] = SolidMade({home: home, made: yes, name: solids[i].name, symbol: solids[i].symbol});
        }
    }

    /**
     * @notice Create multiple Solids in a single transaction
     * @param solids Array of solids to create
     * @return mades Array of SolidMade structs with details about each solid
     */
    function make(SolidSpec[] calldata solids) external returns (SolidMade[] memory mades) {
        // Get arrays of done and TBD solids
        mades = made(solids);
        uint256 created = 0;

        // Create the TBD ones
        for (uint256 i = 0; i < mades.length; i++) {
            if (!mades[i].made) {
                created++;
                NOTHING.make(mades[i].name, mades[i].symbol);
            }
        }

        emit MadeBatch(created, solids.length);
    }

    /**
     * @notice Buy multiple Solids in a single transaction, creating them if needed
     * @param specs Array of BuySpec with name, symbol, and ETH amount for each
     * @return results Array of BuyResult with details about each purchase
     */
    function buy(BuySpec[] calldata specs) external payable returns (BuyResult[] memory results) {
        results = new BuyResult[](specs.length);
        uint256 totalEth = 0;

        for (uint256 i = 0; i < specs.length; i++) {
            totalEth += specs[i].eth;
        }

        if (msg.value < totalEth) {
            revert InsufficientETH(totalEth, msg.value);
        }

        for (uint256 i = 0; i < specs.length; i++) {
            ISolid solid = NOTHING.make(specs[i].name, specs[i].symbol);
            uint256 tokens = solid.buy{value: specs[i].eth}();
            solid.transfer(msg.sender, tokens);

            results[i] = BuyResult({solid: solid, eth: specs[i].eth, tokens: tokens});
        }

        // Refund excess ETH
        uint256 excess = msg.value - totalEth;
        if (excess > 0) {
            (bool ok,) = msg.sender.call{value: excess}("");
            require(ok, "ETH refund failed");
        }

        emit BoughtBatch(specs.length, totalEth);
    }
}
