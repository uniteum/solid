// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {Solid} from "../src/Solid.sol";
import {SolidFactory} from "../src/SolidFactory.sol";

/**
 * @notice Deploy the SolidFactory with reference to Solid protofactory
 * @dev Usage: forge script script/SolidFactory.sol -f $chain --private-key $tx_key --broadcast --verify --delay 10 --retries 10
 */
contract SolidFactoryDeploy is Script {
    function run() external {
        // Get Solid protofactory address from environment
        address nothing = vm.envAddress("NOTHING");
        console2.log("NOTHING at:", nothing);

        vm.startBroadcast();

        // Deploy SolidFactory with Solid reference
        SolidFactory factory = new SolidFactory(Solid(payable(nothing)));
        console2.log("SolidFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}
