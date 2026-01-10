// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Solid} from "../src/Solid.sol";
import {BaseTest} from "./Base.t.sol";

/**
 * Handler contract to manage state transitions for invariant testing
 */
contract SolidHandler is Test {
    Solid public solid;

    // Track cumulative actions for debugging
    uint256 public buyCount;
    uint256 public sellCount;

    // Track individual actors
    address[] public actors;
    mapping(address => bool) public isActor;

    // Ghost variables for tracking invariants
    uint256 public ghostTotalEthDeposited;
    uint256 public ghostTotalEthWithdrawn;

    constructor(Solid _solid) {
        solid = _solid;
    }

    /**
     * Buy solids with ETH
     */
    function buy(uint256 amount) public {
        // Bound to reasonable values (0.001 ETH to 10 ETH)
        amount = bound(amount, 1e15, 10 ether);

        // Track actor
        if (!isActor[msg.sender]) {
            actors.push(msg.sender);
            isActor[msg.sender] = true;
        }

        // Ensure actor has enough ETH
        vm.deal(msg.sender, amount);

        uint256 solidsBefore = solid.balanceOf(msg.sender);
        uint256 supplyBefore = solid.totalSupply();
        uint256 poolEthBefore = address(solid).balance;

        vm.prank(msg.sender);
        uint256 solidsReceived = solid.buy{value: amount}();

        uint256 solidsAfter = solid.balanceOf(msg.sender);
        uint256 supplyAfter = solid.totalSupply();
        uint256 poolEthAfter = address(solid).balance;

        // Update tracking
        buyCount++;
        ghostTotalEthDeposited += amount;

        // Sanity checks
        assertEq(solidsAfter - solidsBefore, solidsReceived, "Solids balance mismatch");
        assertEq(supplyAfter - supplyBefore, solidsReceived, "Supply mismatch");
        assertEq(poolEthAfter - poolEthBefore, amount, "ETH pool mismatch");
    }

    /**
     * Sell solids for ETH
     */
    function sell(uint256 actorSeed) public {
        // Skip if no actors
        if (actors.length == 0) return;

        // Select an actor
        address actor = actors[actorSeed % actors.length];
        uint256 solidsBalance = solid.balanceOf(actor);

        // Skip if actor has no solids
        if (solidsBalance == 0) return;

        // Sell between 1% and 100% of balance
        uint256 sellAmount = bound(actorSeed, solidsBalance / 100, solidsBalance);
        if (sellAmount == 0) return;

        uint256 supplyBefore = solid.totalSupply();
        uint256 ethBefore = actor.balance;
        uint256 poolEthBefore = address(solid).balance;

        vm.prank(actor);
        uint256 ethReceived = solid.sell(sellAmount);

        uint256 supplyAfter = solid.totalSupply();
        uint256 ethAfter = actor.balance;
        uint256 poolEthAfter = address(solid).balance;

        // Update tracking
        sellCount++;
        ghostTotalEthWithdrawn += ethReceived;

        // Sanity checks
        assertEq(supplyBefore - supplyAfter, sellAmount, "Supply decrease mismatch");
        assertEq(ethAfter - ethBefore, ethReceived, "ETH received mismatch");
        assertEq(poolEthBefore - poolEthAfter, ethReceived, "ETH pool decrease mismatch");
    }

    /**
     * Get all actors
     */
    function getActors() public view returns (address[] memory) {
        return actors;
    }

    /**
     * Get number of actors
     */
    function getActorCount() public view returns (uint256) {
        return actors.length;
    }
}

/**
 * Invariant test suite for Solid.sol bonding curve
 */
contract SolidInvariantTest is StdInvariant, BaseTest {
    Solid public solid;
    SolidHandler public handler;

    function setUp() public override {
        super.setUp();

        // Create a new solid token
        Solid nothing = new Solid();
        solid = Solid(payable(address(nothing.make("Hydrogen", "H"))));

        // Create handler
        handler = new SolidHandler(solid);

        // Set handler as target contract
        targetContract(address(handler));

        // Target specific functions
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = SolidHandler.buy.selector;
        selectors[1] = SolidHandler.sell.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    /**
     * INVARIANT: Pool ETH balance should equal deposited - withdrawn
     */
    function invariant_ethBalance() public view {
        uint256 poolEth = address(solid).balance;
        uint256 expectedEth = handler.ghostTotalEthDeposited() - handler.ghostTotalEthWithdrawn();

        assertEq(poolEth, expectedEth, "Pool ETH != (deposited - withdrawn)");
    }

    /**
     * INVARIANT: Sum of all balances should equal total supply
     */
    function invariant_balanceSum() public view {
        uint256 sum = 0;

        // Add all actor balances
        address[] memory actorList = handler.getActors();
        for (uint256 i = 0; i < actorList.length; i++) {
            sum += solid.balanceOf(actorList[i]);
        }

        assertEq(sum, solid.totalSupply(), "Sum of balances != total supply");
    }

    /**
     * INVARIANT: No individual actor should hold more than total supply
     */
    function invariant_noOverflow() public view {
        address[] memory actorList = handler.getActors();
        uint256 currentSupply = solid.totalSupply();
        for (uint256 i = 0; i < actorList.length; i++) {
            uint256 balance = solid.balanceOf(actorList[i]);
            assertLe(balance, currentSupply, "Actor balance > total supply");
        }
    }

    /**
     * INVARIANT: Total supply should never exceed a reasonable bound
     * With K=1e9, buying all 1 billion ETH would give ~sqrt(2e27) ≈ 1.4e13 tokens
     */
    function invariant_supplyBound() public view {
        uint256 totalSupply = solid.totalSupply();
        assertLe(totalSupply, 1e20, "Total supply exceeded reasonable bound");
    }

    /**
     * INVARIANT: Pool ETH should never exceed what was deposited
     */
    function invariant_ethSolvency() public view {
        uint256 poolEth = address(solid).balance;
        uint256 totalDeposited = handler.ghostTotalEthDeposited();

        assertLe(poolEth, totalDeposited, "Pool ETH > deposited");
    }

    /**
     * Helper: Log final state for debugging
     */
    function invariant_logFinalState() public view {
        console.log("=== Final Invariant Test State ===");
        console.log("Buys:", handler.buyCount());
        console.log("Sells:", handler.sellCount());
        console.log("Total Supply:", solid.totalSupply());
        console.log("Pool ETH:", address(solid).balance);
        console.log("Total Deposited:", handler.ghostTotalEthDeposited());
        console.log("Total Withdrawn:", handler.ghostTotalEthWithdrawn());
        console.log("Actors:", handler.getActorCount());
    }
}
