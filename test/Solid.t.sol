// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Solid} from "../src/Solid.sol";
import {BaseTest} from "./Base.t.sol";
import {SolidUser} from "./SolidUser.sol";

contract SolidTest is BaseTest {
    uint256 constant ETH = 1e9;
    Solid public N;
    SolidUser public owen;

    receive() external payable {}

    function setUp() public virtual override {
        super.setUp();
        owen = newUser("owen");
        N = new Solid();
    }

    function newUser(string memory name) internal returns (SolidUser user) {
        user = new SolidUser(name, N);
        vm.deal(address(user), ETH);
    }

    function test_Setup() public view {
        assertEq(N.totalSupply(), 0);
        assertEq(N.name(), "");
        assertEq(N.symbol(), "NOTHING");
    }

    function test_MakeHydrogen() public returns (ISolid H) {
        H = N.make("Hydrogen", "H");
        assertEq(H.totalSupply(), 0, "should start with 0 supply");
        assertEq(H.name(), "Hydrogen");
        assertEq(H.symbol(), "H");
        assertEq(address(H).balance, 0, "should have 0 ETH");
    }

    function test_FirstBuy() public {
        ISolid H = N.make("Hydrogen", "H");

        // Buy with 1 ether
        uint256 sol = H.buy{value: 1 ether}();

        assertGt(sol, 0, "should receive tokens");
        assertEq(H.totalSupply(), sol, "total supply should equal tokens bought");
        assertEq(H.balanceOf(address(this)), sol, "buyer should receive tokens");
        assertEq(address(H).balance, 1 ether, "contract should receive ETH");
    }

    function test_BuysPreview() public {
        ISolid H = N.make("Hydrogen", "H");

        uint256 preview = H.buys(1 ether);
        uint256 actual = H.buy{value: 1 ether}();

        assertEq(actual, preview, "buy should match buys preview");
    }

    function test_SellsPreview() public {
        ISolid H = N.make("Hydrogen", "H");

        uint256 bought = H.buy{value: 1 ether}();
        uint256 preview = H.sells(bought);
        uint256 actual = H.sell(bought);

        assertEq(actual, preview, "sell should match sells preview");
    }

    function test_BuyIncreasesPrice() public {
        ISolid H = N.make("Hydrogen", "H");

        // First buy
        uint256 sol1 = H.buy{value: 1 ether}();

        // Second buy of same ETH amount
        uint256 sol2 = H.buy{value: 1 ether}();

        // Should receive fewer tokens on second buy (price increased)
        assertLt(sol2, sol1, "second buy should receive fewer tokens");
    }

    function test_BuySellRoundtrip() public {
        ISolid H = N.make("Hydrogen", "H");

        uint256 ethBefore = address(this).balance;

        // Buy tokens
        uint256 sol = H.buy{value: 1 ether}();

        // Sell all tokens back
        H.sell(sol);

        uint256 ethAfter = address(this).balance;

        // Quadratic curve: selling all tokens back should return ~all ETH (with tiny rounding)
        assertApproxEqRel(ethAfter, ethBefore, 0.01e18, "should get ~all ETH back (within 1%)");
        assertEq(H.totalSupply(), 0, "supply should return to 0");
        assertEq(H.balanceOf(address(this)), 0, "should have 0 balance");
    }

    function test_MultipleBuyers() public {
        ISolid H = N.make("Hydrogen", "H");

        // This contract buys
        uint256 sol1 = H.buy{value: 1 ether}();

        // Owen buys
        vm.deal(address(owen), 10 ether);
        uint256 sol2 = owen.buy(H, 1 ether);

        // Owen should get fewer tokens (price increased)
        assertLt(sol2, sol1, "second buyer should get fewer tokens");

        // Total supply should be sum
        assertEq(H.totalSupply(), sol1 + sol2, "total supply should be sum of buys");
    }

    function test_CannotBuyNOTHING() public {
        vm.expectRevert(ISolid.Nothing.selector);
        N.buy{value: 1 ether}();
    }

    function test_CannotSellNOTHING() public {
        vm.expectRevert(ISolid.Nothing.selector);
        N.sell(100);
    }

    function test_CannotSendETHToNOTHING() public {
        vm.expectRevert(ISolid.Nothing.selector);
        (bool success,) = address(N).call{value: 1 ether}("");
        success;
    }

    function test_SellFor() public {
        ISolid H = N.make("Hydrogen", "H");
        ISolid O = N.make("Oxygen", "O");

        // Buy H
        uint256 hBought = H.buy{value: 1 ether}();

        // Sell H for O in one transaction
        uint256 oReceived = H.sellFor(O, hBought);

        assertEq(H.balanceOf(address(this)), 0, "should have no H left");
        assertGt(oReceived, 0, "should have received O");
        assertEq(O.balanceOf(address(this)), oReceived, "should have O balance");
    }

    function test_MakeIdempotent() public {
        ISolid H1 = N.make("Hydrogen", "H");
        ISolid H2 = N.make("Hydrogen", "H");

        assertEq(address(H1), address(H2), "should return same address");
    }

    function test_MadePredictsAddress() public {
        (bool exists, address predicted,) = N.made("Helium", "He");
        assertFalse(exists, "should not exist yet");

        ISolid He = N.make("Helium", "He");
        assertEq(address(He), predicted, "should match predicted address");
    }
}
