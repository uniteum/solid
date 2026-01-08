// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Solid} from "../src/Solid.sol";
import {SolidFactory} from "../src/SolidFactory.sol";
import {BaseTest} from "./Base.t.sol";

contract SolidFactoryTest is BaseTest {
    uint256 constant ETH = 100 ether;
    Solid public N;
    SolidFactory public factory;

    function setUp() public virtual override {
        super.setUp();
        N = new Solid();
        factory = new SolidFactory(N);
        vm.deal(address(this), ETH);
    }

    // Helper to get supply from a Solid instance
    function getSupply(ISolid solid) internal view returns (uint256) {
        return solid.totalSupply();
    }

    function test_Constructor() public view {
        assertEq(address(factory.SOLID()), address(N), "factory should reference N");
    }

    function test_MadeWithEmptyArray() public view {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](0);
        (
            SolidFactory.SolidSpec[] memory existing,
            SolidFactory.SolidSpec[] memory notExisting,
            uint256 feePer,
            uint256 fee
        ) = factory.made(solids);

        assertEq(existing.length, 0, "should have no existing");
        assertEq(notExisting.length, 0, "should have no notExisting");
        assertEq(feePer, N.STAKE(), "feePer should be STAKE");
        assertEq(fee, 0, "fee should be 0");
    }

    function test_MadeWithOneNonExisting() public view {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](1);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});

        (
            SolidFactory.SolidSpec[] memory existing,
            SolidFactory.SolidSpec[] memory notExisting,
            uint256 feePer,
            uint256 fee
        ) = factory.made(solids);

        assertEq(existing.length, 0, "should have no existing");
        assertEq(notExisting.length, 1, "should have one notExisting");
        assertEq(notExisting[0].name, "Hydrogen", "name should match");
        assertEq(notExisting[0].symbol, "H", "symbol should match");
        assertEq(feePer, N.STAKE(), "feePer should be STAKE");
        assertEq(fee, N.STAKE(), "fee should be STAKE");
    }

    function test_MadeWithOneExisting() public {
        // Create Hydrogen first
        N.make{value: N.STAKE()}("Hydrogen", "H");

        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](1);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});

        (
            SolidFactory.SolidSpec[] memory existing,
            SolidFactory.SolidSpec[] memory notExisting,
            uint256 feePer,
            uint256 fee
        ) = factory.made(solids);

        assertEq(existing.length, 1, "should have one existing");
        assertEq(existing[0].name, "Hydrogen", "name should match");
        assertEq(existing[0].symbol, "H", "symbol should match");
        assertEq(notExisting.length, 0, "should have no notExisting");
        assertEq(feePer, N.STAKE(), "feePer should be STAKE");
        assertEq(fee, 0, "fee should be 0");
    }

    function test_MadeWithMixedExistingAndNonExisting() public {
        // Create Hydrogen and Helium first
        N.make{value: N.STAKE()}("Hydrogen", "H");
        N.make{value: N.STAKE()}("Helium", "He");

        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](4);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"}); // existing
        solids[1] = SolidFactory.SolidSpec({name: "Lithium", symbol: "Li"}); // new
        solids[2] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"}); // existing
        solids[3] = SolidFactory.SolidSpec({name: "Beryllium", symbol: "Be"}); // new

        (
            SolidFactory.SolidSpec[] memory existing,
            SolidFactory.SolidSpec[] memory notExisting,
            uint256 feePer,
            uint256 fee
        ) = factory.made(solids);

        assertEq(existing.length, 2, "should have two existing");
        assertEq(existing[0].name, "Hydrogen", "first existing name should match");
        assertEq(existing[0].symbol, "H", "first existing symbol should match");
        assertEq(existing[1].name, "Helium", "second existing name should match");
        assertEq(existing[1].symbol, "He", "second existing symbol should match");

        assertEq(notExisting.length, 2, "should have two notExisting");
        assertEq(notExisting[0].name, "Lithium", "first notExisting name should match");
        assertEq(notExisting[0].symbol, "Li", "first notExisting symbol should match");
        assertEq(notExisting[1].name, "Beryllium", "second notExisting name should match");
        assertEq(notExisting[1].symbol, "Be", "second notExisting symbol should match");

        assertEq(feePer, N.STAKE(), "feePer should be STAKE");
        assertEq(fee, 2 * N.STAKE(), "fee should be 2 * STAKE");
    }

    function test_MakeWithEmptyArray() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](0);
        (
            SolidFactory.SolidSpec[] memory existing,
            SolidFactory.SolidSpec[] memory created,
            uint256 feePer,
            uint256 fee
        ) = factory.make{value: 0}(solids);

        assertEq(existing.length, 0, "should have no existing");
        assertEq(created.length, 0, "should have no created");
        assertEq(feePer, N.STAKE(), "feePer should be STAKE");
        assertEq(fee, 0, "fee should be 0");
    }

    function test_MakeWithOneNewSolid() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](1);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});

        uint256 balanceBefore = address(this).balance;

        (
            SolidFactory.SolidSpec[] memory existing,
            SolidFactory.SolidSpec[] memory created,
            uint256 feePer,
            uint256 fee
        ) = factory.make{value: N.STAKE()}(solids);

        assertEq(existing.length, 0, "should have no existing");
        assertEq(created.length, 1, "should have one created");
        assertEq(created[0].name, "Hydrogen", "name should match");
        assertEq(created[0].symbol, "H", "symbol should match");
        assertEq(feePer, N.STAKE(), "feePer should be STAKE");
        assertEq(fee, N.STAKE(), "fee should be STAKE");

        // Verify the Solid was actually created
        (bool yes, address home,) = N.made("Hydrogen", "H");
        assertTrue(yes, "Hydrogen should exist");
        assertTrue(home != address(0), "Hydrogen should have valid address");

        // Verify balance change
        assertEq(address(this).balance, balanceBefore - N.STAKE(), "should have spent STAKE");
    }

    function test_MakeWithMultipleNewSolids() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](3);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});
        solids[1] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"});
        solids[2] = SolidFactory.SolidSpec({name: "Lithium", symbol: "Li"});

        uint256 balanceBefore = address(this).balance;

        (
            SolidFactory.SolidSpec[] memory existing,
            SolidFactory.SolidSpec[] memory created,
            uint256 feePer,
            uint256 fee
        ) = factory.make{value: 3 * N.STAKE()}(solids);

        assertEq(existing.length, 0, "should have no existing");
        assertEq(created.length, 3, "should have three created");
        assertEq(created[0].name, "Hydrogen", "first name should match");
        assertEq(created[0].symbol, "H", "first symbol should match");
        assertEq(created[1].name, "Helium", "second name should match");
        assertEq(created[1].symbol, "He", "second symbol should match");
        assertEq(created[2].name, "Lithium", "third name should match");
        assertEq(created[2].symbol, "Li", "third symbol should match");
        assertEq(feePer, N.STAKE(), "feePer should be STAKE");
        assertEq(fee, 3 * N.STAKE(), "fee should be 3 * STAKE");

        // Verify all Solids were actually created
        (bool yes1,,) = N.made("Hydrogen", "H");
        (bool yes2,,) = N.made("Helium", "He");
        (bool yes3,,) = N.made("Lithium", "Li");
        assertTrue(yes1, "Hydrogen should exist");
        assertTrue(yes2, "Helium should exist");
        assertTrue(yes3, "Lithium should exist");

        // Verify balance change
        assertEq(address(this).balance, balanceBefore - 3 * N.STAKE(), "should have spent 3 * STAKE");
    }

    function test_MakeWithMixedExistingAndNew() public {
        // Create Hydrogen first
        N.make{value: N.STAKE()}("Hydrogen", "H");

        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](3);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"}); // existing
        solids[1] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"}); // new
        solids[2] = SolidFactory.SolidSpec({name: "Lithium", symbol: "Li"}); // new

        uint256 balanceBefore = address(this).balance;

        (
            SolidFactory.SolidSpec[] memory existing,
            SolidFactory.SolidSpec[] memory created,
            uint256 feePer,
            uint256 fee
        ) = factory.make{value: 2 * N.STAKE()}(solids);

        assertEq(existing.length, 1, "should have one existing");
        assertEq(existing[0].name, "Hydrogen", "existing name should match");
        assertEq(existing[0].symbol, "H", "existing symbol should match");

        assertEq(created.length, 2, "should have two created");
        assertEq(created[0].name, "Helium", "first created name should match");
        assertEq(created[0].symbol, "He", "first created symbol should match");
        assertEq(created[1].name, "Lithium", "second created name should match");
        assertEq(created[1].symbol, "Li", "second created symbol should match");

        assertEq(feePer, N.STAKE(), "feePer should be STAKE");
        assertEq(fee, 2 * N.STAKE(), "fee should be 2 * STAKE");

        // Verify new Solids were created
        (bool yes1,,) = N.made("Helium", "He");
        (bool yes2,,) = N.made("Lithium", "Li");
        assertTrue(yes1, "Helium should exist");
        assertTrue(yes2, "Lithium should exist");

        // Verify balance change
        assertEq(address(this).balance, balanceBefore - 2 * N.STAKE(), "should have spent 2 * STAKE");
    }

    function test_MakeWithExcessStakeRefunds() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](1);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});

        uint256 balanceBefore = address(this).balance;
        uint256 excessStake = 5 * N.STAKE();

        factory.make{value: N.STAKE() + excessStake}(solids);

        // Verify excess was refunded
        assertEq(address(this).balance, balanceBefore - N.STAKE(), "should have refunded excess and only spent STAKE");
    }

    function test_MakeRevertsWithInsufficientStake() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](2);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});
        solids[1] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"});

        uint256 insufficientStake = N.STAKE(); // Need 2 * STAKE

        vm.expectRevert(abi.encodeWithSelector(ISolid.StakeLow.selector, insufficientStake, 2 * N.STAKE()));
        factory.make{value: insufficientStake}(solids);
    }

    function test_MakeRevertsWithNoStake() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](1);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});

        vm.expectRevert(abi.encodeWithSelector(ISolid.StakeLow.selector, 0, N.STAKE()));
        factory.make{value: 0}(solids);
    }

    function test_MakeWithAllExistingSkipsCreation() public {
        // Create Hydrogen and Helium first
        N.make{value: N.STAKE()}("Hydrogen", "H");
        N.make{value: N.STAKE()}("Helium", "He");

        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](2);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});
        solids[1] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"});

        uint256 balanceBefore = address(this).balance;

        (
            SolidFactory.SolidSpec[] memory existing,
            SolidFactory.SolidSpec[] memory created,
            uint256 feePer,
            uint256 fee
        ) = factory.make{value: 0}(solids);

        assertEq(existing.length, 2, "should have two existing");
        assertEq(created.length, 0, "should have no created");
        assertEq(feePer, N.STAKE(), "feePer should be STAKE");
        assertEq(fee, 0, "fee should be 0");

        // Verify no balance change
        assertEq(address(this).balance, balanceBefore, "should have spent nothing");
    }

    function test_MakeEmitsMadeBatchEvent() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](3);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});
        solids[1] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"});
        solids[2] = SolidFactory.SolidSpec({name: "Lithium", symbol: "Li"});

        // Create Hydrogen first
        N.make{value: N.STAKE()}("Hydrogen", "H");

        // Expect MadeBatch event with: created=2, skipped=1, total=3
        vm.expectEmit(true, true, true, true, address(factory));
        emit SolidFactory.MadeBatch(2, 1, 3);

        factory.make{value: 2 * N.STAKE()}(solids);
    }

    function test_MakeFuzzWithRandomStake(uint256 stake, uint256 count) public {
        // Bound inputs
        count = bound(count, 1, 10);
        uint256 requiredFee = count * N.STAKE();

        // Create array of solids
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](count);
        for (uint256 i = 0; i < count; i++) {
            solids[i] = SolidFactory.SolidSpec({
                name: string(abi.encodePacked("Element", vm.toString(i))),
                symbol: string(abi.encodePacked("E", vm.toString(i)))
            });
        }

        if (stake < requiredFee) {
            // Should revert with insufficient stake
            vm.expectRevert(abi.encodeWithSelector(ISolid.StakeLow.selector, stake, requiredFee));
            factory.make{value: stake}(solids);
        } else {
            // Should succeed
            uint256 balanceBefore = address(this).balance;
            vm.assume(balanceBefore >= stake); // Ensure we have enough balance

            factory.make{value: stake}(solids);

            // Verify balance change (should only spend requiredFee)
            assertEq(address(this).balance, balanceBefore - requiredFee, "should have spent only required fee");
        }
    }

    function test_MadeFeesCalculation() public view {
        // Test with varying numbers of non-existing solids
        for (uint256 i = 0; i <= 5; i++) {
            SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](i);
            for (uint256 j = 0; j < i; j++) {
                solids[j] = SolidFactory.SolidSpec({
                    name: string(abi.encodePacked("Element", vm.toString(j))),
                    symbol: string(abi.encodePacked("E", vm.toString(j)))
                });
            }

            (,,, uint256 fee) = factory.made(solids);
            assertEq(fee, i * N.STAKE(), "fee should be count * STAKE");
        }
    }

    // Test that receive() works for refunds
    receive() external payable {}
}
