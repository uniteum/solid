// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Solid, ISolid} from "./Solid.sol";

/**
 * @notice Factory for batch creation of Solid tokens
 */
contract SolidFactory {
    Solid public immutable SOLID;

    struct SolidSpec {
        string name;
        string symbol;
    }

    event MadeBatch(uint256 created, uint256 skipped, uint256 total);

    constructor(Solid solid) {
        SOLID = solid;
    }

    /**
     * @notice Check which solids exist and which don't
     * @param solids Array of solids to check
     * @return done Array of SolidSpecs that already exist
     * @return tbd Array of SolidSpecs that don't exist yet
     * @return stakePer Stake required per Solid
     * @return stake Total stake required to create the Solids
     */
    function made(SolidSpec[] calldata solids)
        public
        view
        returns (SolidSpec[] memory done, SolidSpec[] memory tbd, uint256 stakePer, uint256 stake)
    {
        uint256 existingCount = 0;
        uint256 notExistingCount = 0;

        // First pass: count
        for (uint256 i = 0; i < solids.length; i++) {
            (bool yes,,) = SOLID.made(solids[i].name, solids[i].symbol);
            if (yes) {
                existingCount++;
            } else {
                notExistingCount++;
            }
        }

        stakePer = SOLID.STAKE();
        stake = notExistingCount * stakePer;

        // Allocate arrays
        done = new SolidSpec[](existingCount);
        tbd = new SolidSpec[](notExistingCount);

        // Second pass: populate
        uint256 existingIndex = 0;
        uint256 notExistingIndex = 0;
        for (uint256 i = 0; i < solids.length; i++) {
            (bool yes,,) = SOLID.made(solids[i].name, solids[i].symbol);
            if (yes) {
                done[existingIndex++] = solids[i];
            } else {
                tbd[notExistingIndex++] = solids[i];
            }
        }
    }

    /**
     * @notice Create multiple Solids in a single transaction
     * @dev Refunds excess ETH to msg.sender
     * @param solids Array of solids to create
     * @return done Array of SolidSpecs that already existed
     * @return created Array of SolidSpecs that were created
     * @return stakePer Stake required per Solid
     * @return stake Total stake used to create the Solids
     */
    function make(SolidSpec[] calldata solids)
        external
        payable
        returns (SolidSpec[] memory done, SolidSpec[] memory created, uint256 stakePer, uint256 stake)
    {
        // Get arrays of done and non-done solids
        (done, created, stakePer, stake) = made(solids);

        if (msg.value < stake) {
            revert ISolid.PaymentLow(msg.value, stake);
        }

        // Create the non-done ones
        for (uint256 i = 0; i < created.length; i++) {
            SOLID.make{value: stakePer}(created[i].name, created[i].symbol);
        }

        emit MadeBatch(created.length, done.length, solids.length);

        // Refund excess ETH
        uint256 excess = msg.value - stake;
        if (excess > 0) {
            (bool ok,) = msg.sender.call{value: excess}("");
            require(ok, "Refund failed");
        }
    }
}
