// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {SolidSeller} from "../src/SolidSeller.sol";

/**
 * @notice Deploy the Solid protofactory
 * @dev Usage: forge script script/SolidSeller.s.sol -f $chain --private-key $tx_key --broadcast --verify --delay 10 --retries 10
 */
contract SolidSellerDeploy is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy Solid base contract using CREATE2 with salt 0x0
        SolidSeller seller = new SolidSeller{salt: 0x0}();
        console2.log("SolidSeller protofactory deployed at:", address(seller));

        vm.stopBroadcast();
    }
}
