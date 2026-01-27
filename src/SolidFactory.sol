// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Solid} from "./Solid.sol";

/**
 * @notice Factory for batch creation of Solid tokens
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

    event MadeBatch(uint256 created, uint256 total);

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
}
