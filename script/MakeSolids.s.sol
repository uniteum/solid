// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {SolidFactory} from "../src/SolidFactory.sol";

/**
 * @notice Invoke SolidFactory to create Solids from a JSON file
 * @dev Usage: forge script script/MakeSolids.sol -f $chain --private-key $tx_key --broadcast
 * @dev The script automatically calculates required ETH based on STAKE from the Solid contract
 */
contract MakeSolids is Script {
    function run() external {
        // Get SolidFactory address from environment
        address factoryAddress = vm.envAddress("SOLID_FACTORY");
        console2.log("Using SolidFactory at:", factoryAddress);

        // Read and parse solids directly into factory format
        string memory path = vm.envString("SOLIDS_PATH");
        string memory fullPath = string.concat(vm.projectRoot(), "/", path);
        // forge-lint: disable-next-line(unsafe-cheatcode)
        string memory json = vm.readFile(fullPath);

        SolidFactory.MakeIn[] memory solids = abi.decode(vm.parseJson(json, "$"), (SolidFactory.MakeIn[]));

        console2.log("Found", solids.length, "solids to create");

        // Create factory instance
        SolidFactory factory = SolidFactory(factoryAddress);

        // Check which solids already exist BEFORE broadcast
        SolidFactory.MakeOut[] memory mades = factory.made(solids);

        // Count existing and to-create
        uint256 existingCount = 0;
        uint256 toCreateCount = 0;
        for (uint256 i = 0; i < mades.length; i++) {
            if (mades[i].made) {
                existingCount++;
            } else {
                toCreateCount++;
            }
        }

        console2.log("\nPre-flight check:");
        console2.log("  Already exist:", existingCount);
        console2.log("  To create:", toCreateCount);

        // Show existing tokens
        if (existingCount > 0) {
            console2.log("\nAlready exist:");
            for (uint256 i = 0; i < mades.length; i++) {
                if (mades[i].made) {
                    console2.log("  -", mades[i].symbol, mades[i].name);
                }
            }
        }

        // Show tokens to be created
        if (toCreateCount > 0) {
            console2.log("\nWill create:");
            for (uint256 i = 0; i < mades.length; i++) {
                if (!mades[i].made) {
                    console2.log("  -", mades[i].symbol, mades[i].name);
                }
            }
        }

        // Only broadcast if there are tokens to create
        if (toCreateCount == 0) {
            console2.log("\nNo tokens to create. Exiting.");
            return;
        }

        console2.log("\nStarting broadcast...");
        vm.startBroadcast();
        SolidFactory.MakeOut[] memory results = factory.make(solids);

        // Count created (those with made=false in the results, since it's checked before creation)
        uint256 createdCount = 0;
        for (uint256 i = 0; i < results.length; i++) {
            if (!results[i].made) {
                createdCount++;
            }
        }

        console2.log("\nSummary:");
        console2.log("  Created:", createdCount);
        console2.log("  Skipped:", results.length - createdCount);

        vm.stopBroadcast();
    }
}
