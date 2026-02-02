// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Solid} from "./Solid.sol";

/**
 * @notice Factory for batch creation and purchasing of Solid tokens
 */
contract SolidFactory {
    Solid public immutable NOTHING;

    struct MakeIn {
        string name;
        string symbol;
    }

    struct MakeOut {
        address home;
        bool made;
        string name;
        string symbol;
    }

    struct BuyIn {
        uint256 eth;
        string name;
        string symbol;
    }

    struct BuyOut {
        uint256 eth;
        string name;
        ISolid solid;
        string symbol;
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
     * @return mades Array of MakeOut structs with details about each solid
     */
    function made(MakeIn[] calldata solids) public view returns (MakeOut[] memory mades) {
        mades = new MakeOut[](solids.length);

        // First pass: count
        for (uint256 i = 0; i < solids.length; i++) {
            (bool yes, address home,) = NOTHING.made(solids[i].name, solids[i].symbol);
            mades[i] = MakeOut({home: home, made: yes, name: solids[i].name, symbol: solids[i].symbol});
        }
    }

    /**
     * @notice Create multiple Solids in a single transaction
     * @param solids Array of solids to create
     * @return mades Array of MakeOut structs with details about each solid
     */
    function make(MakeIn[] calldata solids) external returns (MakeOut[] memory mades) {
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
     * @param specs Array of BuyIn with name, symbol, and ETH amount for each
     * @return results Array of BuyOut with details about each purchase
     */
    function buy(BuyIn[] calldata specs) external payable returns (BuyOut[] memory results) {
        results = new BuyOut[](specs.length);
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

            results[i] =
                BuyOut({eth: specs[i].eth, name: specs[i].name, solid: solid, symbol: specs[i].symbol, tokens: tokens});
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
