// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Solid} from "../src/Solid.sol";
import {ISolid} from "isolid/ISolid.sol";

contract PricingTest is Test {
    function test_ShowPricing() public {
        Solid N = new Solid();
        ISolid H = N.make("Hydrogen", "H");
        
        // Buy with 1 ETH
        uint256 sol = H.buy{value: 1 ether}();
        
        console.log("1 ETH buys:", sol / 1e18, "tokens");
        console.log("Price per token:", (1 ether * 1e18) / sol, "wei");
        uint256 usdPrice = (3000 * 1e6 * 1e18) / sol; // in millionths of dollar
        console.log("At ETH=$3000, price per token: $0.%s", usdPrice / 1e6);
    }
}
