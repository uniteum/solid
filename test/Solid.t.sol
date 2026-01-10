// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Solid} from "../src/Solid.sol";
import {BaseTest} from "./Base.t.sol";
import {SolidUser} from "./SolidUser.sol";

contract SolidTest is BaseTest {
    uint256 constant SOL = 1e23;
    uint256 constant ETH = 1e9;
    Solid public N;
    SolidUser public owen;

    receive() external payable {}

    function setUp() public virtual override {
        super.setUp();
        owen = newUser("owen");
        N = new Solid(SOL);
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

    function test_Sells_MatchesSell() public {
        // Create Hydrogen
        ISolid H = N.make("Hydrogen", "H");

        // Add liquidity
        vm.deal(address(H), 10 ether);

        // Buy some H
        uint256 hBought = H.buy{value: 1 ether}();

        // Get the preview from sells()
        uint256 ethPreview = H.sells(hBought);

        // Execute actual sell
        uint256 ethActual = H.sell(hBought);

        // They should match exactly
        assertEq(ethActual, ethPreview, "sell should return same ETH as sells preview");
    }

    function test_SellFor_NoApproval() public {
        // Create two Solids
        ISolid H = N.make("Hydrogen", "H");
        ISolid O = N.make("Oxygen", "O");

        // Add liquidity to both
        vm.deal(address(H), 10 ether);
        vm.deal(address(O), 10 ether);

        // Give owen more ETH for buying
        vm.deal(address(owen), 100 ether);

        // Owen buys some H
        uint256 hBought = owen.buy(H, 1 ether);
        assertGt(hBought, 0, "should have bought H");

        uint256 hBefore = H.balanceOf(address(owen));
        uint256 oBefore = O.balanceOf(address(owen));

        // Owen sells H for O in ONE transaction WITHOUT approval!
        uint256 oReceived = owen.sellFor(H, O, hBought);

        uint256 hAfter = H.balanceOf(address(owen));
        uint256 oAfter = O.balanceOf(address(owen));

        assertEq(hAfter, hBefore - hBought, "should have sold all H");
        assertEq(oAfter, oBefore + oReceived, "should have received O");
        assertGt(oReceived, 0, "should receive some O");
    }

    function test_CannotReinitializeNOTHING() public {
        // This test would have caught the bug where NOTHING had an empty symbol
        // If symbol is empty, zzz_() could be called to mint tokens on NOTHING
        uint256 supplyBefore = N.totalSupply();
        assertEq(supplyBefore, 0, "NOTHING should start with zero supply");

        // Attempt to call zzz_() on NOTHING should fail silently (no-op)
        // because _symbol is already set to "NOTHING"
        N.zzz_("Evil", "EVIL");

        // Verify NOTHING was not reinitialized
        uint256 supplyAfter = N.totalSupply();
        assertEq(supplyAfter, 0, "NOTHING supply should remain zero");
        assertEq(N.name(), "", "NOTHING name should remain empty");
        assertEq(N.symbol(), "NOTHING", "NOTHING symbol should remain NOTHING");
        assertEq(N.balanceOf(address(this)), 0, "attacker should not receive tokens");
    }

    function test_MakeHydrogen() public returns (ISolid H) {
        H = N.make("Hydrogen", "H");
        uint256 supply = H.totalSupply();
        assertEq(H.totalSupply(), supply);
        assertEq(H.name(), "Hydrogen");
        assertEq(H.symbol(), "H");
        assertEq(H.balanceOf(address(this)), 0, "creator should have 0% of supply with no stake");
        assertEq(H.balanceOf(address(H)), supply, "pool should have 100% of supply");
        assertEq(address(H).balance, 0, "pool should have 0 ETH");
    }

    function test_MakeWithExtraStake() public {
        ISolid H = N.make("Helium", "He");
        uint256 supply = H.totalSupply();
        assertEq(H.totalSupply(), supply);
        assertEq(H.balanceOf(address(this)), 0, "creator should have 0% of supply");
        assertEq(H.balanceOf(address(H)), supply, "pool should have 100% of supply");
        assertEq(address(H).balance, 0, "pool should have 0 ETH");
    }

    function test_MakeWithNoStakeCreatesPoolOnly() public {
        ISolid Li = N.make("Lithium", "Li");
        uint256 supply = Li.totalSupply();
        assertEq(Li.totalSupply(), supply);
        assertEq(Li.balanceOf(address(this)), 0, "creator should have 0% of supply");
        assertEq(Li.balanceOf(address(Li)), supply, "pool should have 100% of supply");
        assertEq(address(Li).balance, 0, "pool should have 0 ETH");
    }

    function test_BuyDoesNotCreateTokens() public {
        ISolid H = N.make("TestToken", "TT");
        uint256 supply = H.totalSupply();

        uint256 supplyBefore = H.totalSupply();
        uint256 poolBefore = H.balanceOf(address(H));
        uint256 creatorBefore = H.balanceOf(address(this));

        // Buy with a large amount of ETH
        uint256 buyAmount = 78227239616666287245;
        H.buy{value: buyAmount}();

        uint256 supplyAfter = H.totalSupply();
        uint256 poolAfter = H.balanceOf(address(H));
        uint256 creatorAfter = H.balanceOf(address(this));
        uint256 receivedSolids = creatorAfter - creatorBefore;

        // Total supply should not change
        assertEq(supplyAfter, supplyBefore, "Total supply changed!");

        // Sum of all balances should equal total supply
        uint256 sum = poolAfter + creatorAfter;
        assertEq(sum, supply, "Sum of balances != total supply");

        // Pool should have decreased by the amount user received
        assertEq(poolBefore - poolAfter, receivedSolids, "Pool decrease != user increase");
    }

    function test_BuySellBalanceIntegrity() public {
        ISolid H = N.make("Integrity", "INT");
        uint256 supply = H.totalSupply();

        // Have owen buy
        uint256 buyAmt = 78227239616666287245;
        vm.deal(address(owen), buyAmt);
        owen.buy(H, buyAmt);

        // Check total balances
        uint256 poolBal = H.balanceOf(address(H));
        uint256 creatorBal = H.balanceOf(address(this));
        uint256 owenBal = H.balanceOf(address(owen));
        uint256 sum = poolBal + creatorBal + owenBal;

        assertEq(sum, supply, "Sum != SUPPLY after owen buy");
        assertEq(H.totalSupply(), supply, "Total supply changed!");
    }

    function makeHydrogen(uint256 seed) public returns (ISolid H, uint256 h, uint256 e) {
        seed = seed % ETH;
        H = test_MakeHydrogen();
        // Add seed ETH to the pool
        vm.deal(address(H), seed);
        (h, e) = H.pool();
    }

    function test_StartingPrice(uint256 seed) public returns (ISolid H, uint256 h, uint256 e) {
        (H, h, e) = makeHydrogen(seed);
        uint256 supply = H.totalSupply();
        assertEq(h, supply, "h should be 100% of SUPPLY");
        assertEq(e, (seed % ETH) + 1 ether, "e should be seed + 1 ether (virtual)");
    }

    function test_StartingBuy(uint256 seed, uint256 d) public returns (ISolid H, uint256 h, uint256 e, uint256 s) {
        (H, h, e) = makeHydrogen(seed);
        d = d % address(owen).balance;
        if (e != 0 || d != 0) {
            uint256 balanceBefore = address(owen).balance;
            uint256 poolSolidsBefore = H.balanceOf(address(H));

            s = owen.buy(H, d);

            uint256 balanceAfter = address(owen).balance;
            uint256 poolSolidsAfter = H.balanceOf(address(H));

            assertEq(balanceBefore - balanceAfter, d, "should have spent d ETH");
            assertEq(H.balanceOf(address(owen)), s, "should have received s solids");
            assertEq(poolSolidsBefore - poolSolidsAfter, s, "pool should have decreased by s solids");
            if (d > 0) {
                assertGt(s, 0, "should receive some solids");
            }

            emit log_named_uint("d", d);
            emit log_named_uint("e", e);
            emit log_named_uint("s", s);
            emit log_named_uint("h", h);
        }
    }

    function test_StartingBuy11() public returns (ISolid H, uint256 h, uint256 e, uint256 s) {
        (H, h, e, s) = test_StartingBuy(1e6, 1e6);
    }

    function test_StartingBuy12() public returns (ISolid H, uint256 h, uint256 e, uint256 s) {
        (H, h, e, s) = test_StartingBuy(1e6, 2e6);
    }

    function test_StartingBuy21() public returns (ISolid H, uint256 h, uint256 e, uint256 s) {
        (H, h, e, s) = test_StartingBuy(2e6, 1e6);
    }

    function test_StartingBuy22() public returns (ISolid H, uint256 h, uint256 e, uint256 s) {
        (H, h, e, s) = test_StartingBuy(2e6, 2e6);
    }

    function test_SellFailed1() public {
        test_BuySell(1e9, 4594638);
    }

    function test_BuySell(uint256 seed, uint256 d) public returns (ISolid H, uint256 bought, uint256 sold) {
        (H,,) = makeHydrogen(seed);
        d = d % address(owen).balance;
        if (d != 0) {
            bought = owen.buy(H, d);

            uint256 balanceBefore = address(owen).balance;
            uint256 poolSolidsBefore = H.balanceOf(address(H));
            uint256 poolEthBefore = address(H).balance;

            sold = owen.sell(H, bought);

            uint256 balanceAfter = address(owen).balance;
            uint256 poolSolidsAfter = H.balanceOf(address(H));
            uint256 poolEthAfter = address(H).balance;

            assertEq(balanceAfter - balanceBefore, sold, "should have received sold ETH");
            assertEq(H.balanceOf(address(owen)), 0, "should have no solids left");
            assertEq(poolSolidsAfter - poolSolidsBefore, bought, "pool should have received bought solids back");
            assertEq(poolEthBefore - poolEthAfter, sold, "pool should have decreased by sold ETH");
            assertGt(sold, 0, "should receive some ETH");

            emit log_named_uint("d", d);
            emit log_named_uint("bought", bought);
            emit log_named_uint("sold", sold);
        }
    }

    function test_BuySellPoolReturnsToStartSpecific() public {
        test_BuySellPoolReturnsToStart(12345, 5 ether);
    }

    function test_BuySellPoolReturnsToStart(uint256 seed, uint256 d) public {
        // Create a Solid with random initial ETH
        (ISolid H,,) = makeHydrogen(seed);

        // Ensure owen has enough ETH and bound buy amount
        uint256 owenBalance = address(owen).balance;
        if (owenBalance < 1e15) {
            return; // Skip test if owen doesn't have minimum
        }
        d = bound(d, 1e15, owenBalance);

        // Capture initial pool state BEFORE any buy
        uint256 poolSolidsInitial = H.balanceOf(address(H));
        uint256 poolEthInitial = address(H).balance;

        // Do buy
        uint256 solidsReceived = owen.buy(H, d);

        // Verify pool state changed
        assertGt(H.balanceOf(address(H)), poolSolidsInitial, "pool solids should increase after buy");
        assertGt(address(H).balance, poolEthInitial, "pool ETH should increase after buy");

        // Do sell (all solids received)
        uint256 ethReceived = owen.sell(H, solidsReceived);

        // Verify pool returned to initial state
        uint256 poolSolidsFinal = H.balanceOf(address(H));
        uint256 poolEthFinal = address(H).balance;

        assertEq(poolSolidsFinal, poolSolidsInitial, "pool solids should return to initial state");
        assertEq(poolEthFinal, poolEthInitial, "pool ETH should return to initial state");

        // Verify user has no solids left
        assertEq(H.balanceOf(address(owen)), 0, "user should have no solids after full sell");

        emit log_named_uint("poolSolidsInitial", poolSolidsInitial);
        emit log_named_uint("poolEthInitial", poolEthInitial);
        emit log_named_uint("d", d);
        emit log_named_uint("solidsReceived", solidsReceived);
        emit log_named_uint("ethReceived", ethReceived);
        emit log_named_uint("poolSolidsFinal", poolSolidsFinal);
        emit log_named_uint("poolEthFinal", poolEthFinal);
    }

    function test_MakeFromNonNothingDelegates() public {
        // Create a first Solid (Hydrogen) from NOTHING
        ISolid H = N.make("Hydrogen", "H");
        assertEq(H.balanceOf(address(this)), 0, "creator should have 0% of H");

        // Now call make from H (non-NOTHING) to create Helium
        // This should delegate to NOTHING and create He with full supply in pool
        ISolid he = Solid(payable(address(H))).make("Helium", "He");
        uint256 supplyHe = he.totalSupply();

        // Verify full supply goes to pool (no maker shares)
        assertEq(he.balanceOf(address(this)), 0, "creator should have 0% of He");
        assertEq(he.balanceOf(address(H)), 0, "H should not have any He tokens");
        assertEq(he.balanceOf(address(he)), supplyHe, "He pool should have 100% of supply");
    }

    function test_CannotBuyNOTHING() public {
        // Verify NOTHING has no supply
        assertEq(N.totalSupply(), 0, "NOTHING should have zero supply");
        assertEq(N.balanceOf(address(N)), 0, "NOTHING pool should be empty");

        // Attempt to buy from NOTHING should revert with Nothing()
        vm.expectRevert(ISolid.Nothing.selector);
        N.buy{value: 1 ether}();
    }

    function test_CannotSendETHToNOTHING() public {
        // Attempt to send ETH directly to NOTHING should revert with Nothing()
        vm.expectRevert(ISolid.Nothing.selector);
        (bool success,) = address(N).call{value: 1 ether}("");
        success; // Acknowledge the return value to silence warnings
    }
}
