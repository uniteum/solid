// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Solid} from "../src/Solid.sol";
import {SolidSeller} from "../src/SolidSeller.sol";
import {BaseTest} from "./Base.t.sol";
import {SolidUser} from "./SolidUser.sol";

contract SolidSellerTest is BaseTest {
    uint256 constant AVOGADRO = 6.02214076e23;
    uint256 constant ETH = 1e9;

    Solid public N;
    SolidSeller public sellerProto;
    SolidUser public alice;
    SolidUser public bob;

    ISolid public H; // Hydrogen
    ISolid public O; // Oxygen

    receive() external payable {}

    function setUp() public virtual override {
        super.setUp();

        // Create users
        alice = newUser("alice");
        bob = newUser("bob");

        // Deploy Solid factory
        N = new Solid();

        // Create some Solids for testing
        H = N.make("Hydrogen", "H");
        O = N.make("Oxygen", "O");

        // Add liquidity to both pools
        vm.deal(address(H), 10 ether);
        vm.deal(address(O), 10 ether);

        // Deploy SolidSeller prototype
        sellerProto = new SolidSeller();
    }

    function newUser(string memory name) internal returns (SolidUser user) {
        user = new SolidUser(name, N);
        vm.deal(address(user), ETH);
    }

    /**
     * Test basic deployment and initialization
     */
    function test_Setup() public view {
        assertEq(address(sellerProto.PROTO()), address(sellerProto), "PROTO should be self");
        assertEq(address(sellerProto.th1s()), address(0xdead), "th1s should be initialized to dead");
    }

    /**
     * Test creating a new seller via make()
     */
    function test_MakeSeller() public {
        SolidSeller seller = sellerProto.make(H, O);

        assertEq(address(seller.th1s()), address(H), "th1s should be H");
        assertEq(address(seller.that()), address(O), "that should be O");
        assertEq(seller.thisName(), "Hydrogen", "thisName should be Hydrogen");
        assertEq(seller.thisSymbol(), "H", "thisSymbol should be H");
        assertEq(seller.thatName(), "Oxygen", "thatName should be Oxygen");
        assertEq(seller.thatSymbol(), "O", "thatSymbol should be O");
    }

    /**
     * Test that making the same seller twice returns the same address
     */
    function test_MakeSeller_Deterministic() public {
        SolidSeller seller1 = sellerProto.make(H, O);
        SolidSeller seller2 = sellerProto.make(H, O);

        assertEq(address(seller1), address(seller2), "same params should return same seller");
    }

    /**
     * Test that different pairs create different sellers
     */
    function test_MakeSeller_DifferentPairs() public {
        SolidSeller sellerHO = sellerProto.make(H, O);
        SolidSeller sellerOH = sellerProto.make(O, H);

        assertTrue(address(sellerHO) != address(sellerOH), "different pairs should create different sellers");
    }

    /**
     * Test the made() view function for prediction
     */
    function test_Made_Prediction() public {
        (bool yesBefore, address homeBefore, bytes32 saltBefore) = sellerProto.made(H, O);

        assertFalse(yesBefore, "seller should not exist yet");

        SolidSeller seller = sellerProto.make(H, O);

        (bool yesAfter, address homeAfter, bytes32 saltAfter) = sellerProto.made(H, O);

        assertTrue(yesAfter, "seller should exist now");
        assertEq(homeBefore, address(seller), "predicted address should match");
        assertEq(homeAfter, address(seller), "predicted address should still match");
        assertEq(saltBefore, saltAfter, "salt should be consistent");
    }

    /**
     * Test delegation pattern - calling make on non-PROTO instance
     */
    function test_MakeSeller_Delegation() public {
        SolidSeller seller1 = sellerProto.make(H, O);

        // Calling make on the created seller should delegate to PROTO
        SolidSeller seller2 = seller1.make(H, O);

        assertEq(address(seller1), address(seller2), "delegation should return same seller");
    }

    /**
     * Test sells() view function - should calculate swap without executing
     */
    function test_Sells_View() public {
        SolidSeller seller = sellerProto.make(H, O);

        // Give alice enough ETH
        vm.deal(address(alice), 1 ether);

        // Buy some H tokens first
        uint256 hTokens = alice.buy(H, 0.5 ether);

        // Calculate how much O we'd get for selling half the H
        uint256 sellAmount = hTokens / 2;
        uint256 expectedO = seller.sells(sellAmount);

        assertGt(expectedO, 0, "should receive some O tokens");
    }

    /**
     * Test actual sell() execution
     */
    function test_Sell_Execution() public {
        SolidSeller seller = sellerProto.make(H, O);

        // Give alice enough ETH
        vm.deal(address(alice), 1 ether);

        // Alice buys some H tokens
        uint256 hTokens = alice.buy(H, 0.5 ether);
        assertGt(hTokens, 0, "alice should have H tokens");

        uint256 aliceHBefore = H.balanceOf(address(alice));
        uint256 aliceOBefore = O.balanceOf(address(alice));

        // Alice sells H for O through the seller
        uint256 sellAmount = hTokens / 2;

        // Approve seller to take alice's H tokens
        vm.prank(address(alice));
        H.approve(address(seller), sellAmount);

        // Execute the sell
        vm.prank(address(alice));
        uint256 oReceived = seller.sell(sellAmount);

        uint256 aliceHAfter = H.balanceOf(address(alice));
        uint256 aliceOAfter = O.balanceOf(address(alice));

        assertEq(aliceHAfter, aliceHBefore - sellAmount, "alice should have less H");
        assertEq(aliceOAfter, aliceOBefore + oReceived, "alice should have more O");
        assertGt(oReceived, 0, "should receive some O tokens");
    }

    /**
     * Test that zzz_() can only be called once
     */
    function test_Zzz_OnlyOnce() public {
        SolidSeller seller = sellerProto.make(H, O);

        ISolid He = N.make("Helium", "He");

        // Try to reinitialize - should be a no-op
        seller.zzz_(He, H);

        // Verify it didn't change
        assertEq(address(seller.th1s()), address(H), "th1s should still be H");
        assertEq(address(seller.that()), address(O), "that should still be O");
    }

    /**
     * Test sell with multiple users
     */
    function test_Sell_MultipleUsers() public {
        SolidSeller seller = sellerProto.make(H, O);

        // Give users enough ETH
        vm.deal(address(alice), 1 ether);
        vm.deal(address(bob), 1 ether);

        // Alice and Bob both buy H
        uint256 aliceH = alice.buy(H, 0.3 ether);
        uint256 bobH = bob.buy(H, 0.3 ether);

        // Both approve and sell through seller
        vm.prank(address(alice));
        H.approve(address(seller), aliceH / 2);

        vm.prank(address(alice));
        uint256 aliceO = seller.sell(aliceH / 2);

        vm.prank(address(bob));
        H.approve(address(seller), bobH / 2);

        vm.prank(address(bob));
        uint256 bobO = seller.sell(bobH / 2);

        assertGt(aliceO, 0, "alice should receive O");
        assertGt(bobO, 0, "bob should receive O");

        // Due to slippage, Bob should get less O than Alice (he traded after)
        assertLt(bobO, aliceO, "bob should get less due to slippage");
    }

    /**
     * Test that sells() preview matches actual sell() result reasonably
     */
    function test_Sells_MatchesActual() public {
        SolidSeller seller = sellerProto.make(H, O);

        // Give alice enough ETH
        vm.deal(address(alice), 1 ether);

        // Alice buys some H
        uint256 hTokens = alice.buy(H, 0.5 ether);
        uint256 sellAmount = hTokens / 2;

        // Get preview
        uint256 preview = seller.sells(sellAmount);

        // Execute actual sell
        vm.prank(address(alice));
        H.approve(address(seller), sellAmount);

        vm.prank(address(alice));
        uint256 actual = seller.sell(sellAmount);

        // Preview and actual should be reasonably close (within 5% due to price impact)
        // The difference comes from the fact that selling actually changes pool states
        assertApproxEqRel(actual, preview, 0.05e18, "preview should be reasonably close to actual");
        assertGt(actual, 0, "should receive some tokens");
    }

    /**
     * Test Make event is emitted
     */
    function test_Make_EmitsEvent() public {
        // Predict the address
        (bool exists, address predictedAddress,) = sellerProto.made(H, O);
        assertFalse(exists, "seller should not exist yet");

        vm.expectEmit(true, true, true, true);
        emit SolidSeller.Make(SolidSeller(payable(predictedAddress)), H, O);

        SolidSeller seller = sellerProto.make(H, O);
        assertEq(address(seller), predictedAddress, "seller address should match prediction");
    }

    /**
     * Fuzz test: sell with random amounts
     */
    function testFuzz_Sell(uint256 buyAmount, uint256 sellPercent) public {
        // Bound inputs
        buyAmount = bound(buyAmount, 0.001 ether, 100 ether);
        sellPercent = bound(sellPercent, 1, 100);

        SolidSeller seller = sellerProto.make(H, O);

        // Give alice enough ETH
        vm.deal(address(alice), buyAmount + 1 ether);

        // Alice buys H
        uint256 hTokens = alice.buy(H, buyAmount);

        if (hTokens > 0) {
            uint256 sellAmount = (hTokens * sellPercent) / 100;

            if (sellAmount > 0) {
                vm.prank(address(alice));
                H.approve(address(seller), sellAmount);

                uint256 oBefore = O.balanceOf(address(alice));

                vm.prank(address(alice));
                uint256 oReceived = seller.sell(sellAmount);

                uint256 oAfter = O.balanceOf(address(alice));

                assertEq(oAfter - oBefore, oReceived, "balance change should match return value");
                assertGt(oReceived, 0, "should receive some O");
            }
        }
    }
}
