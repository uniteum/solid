// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Solid} from "../src/Solid.sol";
import {SolidFactory} from "../src/SolidFactory.sol";
import {BaseTest} from "./Base.t.sol";

contract SolidFactoryTest is BaseTest {
    uint256 constant SOL = 1e23;
    uint256 constant ETH = 100 ether;
    Solid public N;
    SolidFactory public factory;

    function setUp() public virtual override {
        super.setUp();
        N = new Solid(SOL);
        factory = new SolidFactory(N);
        vm.deal(address(this), ETH);
    }

    // Helper to get supply from a Solid instance
    function getSupply(ISolid solid) internal view returns (uint256) {
        return solid.totalSupply();
    }

    function test_Constructor() public view {
        assertEq(address(factory.NOTHING()), address(N), "factory should reference N");
    }

    function test_MadeWithEmptyArray() public view {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](0);
        SolidFactory.SolidMade[] memory mades = factory.made(solids);

        assertEq(mades.length, 0, "should have no results");
    }

    function test_MadeWithOneNonExisting() public view {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](1);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});

        SolidFactory.SolidMade[] memory mades = factory.made(solids);

        assertEq(mades.length, 1, "should have one result");
        assertFalse(mades[0].made, "should not exist yet");
        assertEq(mades[0].name, "Hydrogen", "name should match");
        assertEq(mades[0].symbol, "H", "symbol should match");
        assertTrue(mades[0].home != address(0), "home should be predicted address");
    }

    function test_MadeWithOneExisting() public {
        // Create Hydrogen first
        N.make("Hydrogen", "H");

        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](1);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});

        SolidFactory.SolidMade[] memory mades = factory.made(solids);

        assertEq(mades.length, 1, "should have one result");
        assertTrue(mades[0].made, "should exist");
        assertEq(mades[0].name, "Hydrogen", "name should match");
        assertEq(mades[0].symbol, "H", "symbol should match");
    }

    function test_MadeWithMixedExistingAndNonExisting() public {
        // Create Hydrogen and Helium first
        N.make("Hydrogen", "H");
        N.make("Helium", "He");

        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](4);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"}); // existing
        solids[1] = SolidFactory.SolidSpec({name: "Lithium", symbol: "Li"}); // new
        solids[2] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"}); // existing
        solids[3] = SolidFactory.SolidSpec({name: "Beryllium", symbol: "Be"}); // new

        SolidFactory.SolidMade[] memory mades = factory.made(solids);

        assertEq(mades.length, 4, "should have four results");

        // Check each result
        assertTrue(mades[0].made, "Hydrogen should exist");
        assertEq(mades[0].name, "Hydrogen", "first name should match");
        assertEq(mades[0].symbol, "H", "first symbol should match");

        assertFalse(mades[1].made, "Lithium should not exist");
        assertEq(mades[1].name, "Lithium", "second name should match");
        assertEq(mades[1].symbol, "Li", "second symbol should match");

        assertTrue(mades[2].made, "Helium should exist");
        assertEq(mades[2].name, "Helium", "third name should match");
        assertEq(mades[2].symbol, "He", "third symbol should match");

        assertFalse(mades[3].made, "Beryllium should not exist");
        assertEq(mades[3].name, "Beryllium", "fourth name should match");
        assertEq(mades[3].symbol, "Be", "fourth symbol should match");
    }

    function test_MakeWithEmptyArray() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](0);
        SolidFactory.SolidMade[] memory mades = factory.make(solids);

        assertEq(mades.length, 0, "should have no results");
    }

    function test_MakeWithOneNewSolid() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](1);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});

        SolidFactory.SolidMade[] memory mades = factory.make(solids);

        assertEq(mades.length, 1, "should have one result");
        // Note: mades[0].made is false because it was checked BEFORE creation
        assertEq(mades[0].name, "Hydrogen", "name should match");
        assertEq(mades[0].symbol, "H", "symbol should match");

        // Verify the Solid was actually created
        (bool yes, address home,) = N.made("Hydrogen", "H");
        assertTrue(yes, "Hydrogen should exist");
        assertTrue(home != address(0), "Hydrogen should have valid address");
    }

    function test_MakeWithMultipleNewSolids() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](3);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});
        solids[1] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"});
        solids[2] = SolidFactory.SolidSpec({name: "Lithium", symbol: "Li"});

        SolidFactory.SolidMade[] memory mades = factory.make(solids);

        assertEq(mades.length, 3, "should have three results");
        assertEq(mades[0].name, "Hydrogen", "first name should match");
        assertEq(mades[0].symbol, "H", "first symbol should match");
        assertEq(mades[1].name, "Helium", "second name should match");
        assertEq(mades[1].symbol, "He", "second symbol should match");
        assertEq(mades[2].name, "Lithium", "third name should match");
        assertEq(mades[2].symbol, "Li", "third symbol should match");

        // Verify all Solids were actually created
        (bool yes1,,) = N.made("Hydrogen", "H");
        (bool yes2,,) = N.made("Helium", "He");
        (bool yes3,,) = N.made("Lithium", "Li");
        assertTrue(yes1, "Hydrogen should exist");
        assertTrue(yes2, "Helium should exist");
        assertTrue(yes3, "Lithium should exist");
    }

    function test_MakeWithMixedExistingAndNew() public {
        // Create Hydrogen first
        N.make("Hydrogen", "H");

        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](3);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"}); // existing
        solids[1] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"}); // new
        solids[2] = SolidFactory.SolidSpec({name: "Lithium", symbol: "Li"}); // new

        SolidFactory.SolidMade[] memory mades = factory.make(solids);

        assertEq(mades.length, 3, "should have three results");

        // Check existing (made=true because it existed before)
        assertTrue(mades[0].made, "Hydrogen should have been existing");
        assertEq(mades[0].name, "Hydrogen", "first name should match");
        assertEq(mades[0].symbol, "H", "first symbol should match");

        // Check newly created (made=false because they were checked before creation)
        assertFalse(mades[1].made, "Helium made flag should be false (checked before creation)");
        assertEq(mades[1].name, "Helium", "second name should match");
        assertEq(mades[1].symbol, "He", "second symbol should match");

        assertFalse(mades[2].made, "Lithium made flag should be false (checked before creation)");
        assertEq(mades[2].name, "Lithium", "third name should match");
        assertEq(mades[2].symbol, "Li", "third symbol should match");

        // Verify new Solids were created
        (bool yes1,,) = N.made("Helium", "He");
        (bool yes2,,) = N.made("Lithium", "Li");
        assertTrue(yes1, "Helium should exist");
        assertTrue(yes2, "Lithium should exist");
    }

    function test_MakeWithAllExistingSkipsCreation() public {
        // Create Hydrogen and Helium first
        N.make("Hydrogen", "H");
        N.make("Helium", "He");

        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](2);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});
        solids[1] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"});

        SolidFactory.SolidMade[] memory mades = factory.make(solids);

        assertEq(mades.length, 2, "should have two results");
        assertTrue(mades[0].made, "Hydrogen should exist");
        assertTrue(mades[1].made, "Helium should exist");
    }

    function test_MakeEmitsMadeBatchEvent() public {
        SolidFactory.SolidSpec[] memory solids = new SolidFactory.SolidSpec[](3);
        solids[0] = SolidFactory.SolidSpec({name: "Hydrogen", symbol: "H"});
        solids[1] = SolidFactory.SolidSpec({name: "Helium", symbol: "He"});
        solids[2] = SolidFactory.SolidSpec({name: "Lithium", symbol: "Li"});

        // Create Hydrogen first
        N.make("Hydrogen", "H");

        // Expect MadeBatch event with: created=2, total=3
        vm.expectEmit(true, true, true, true, address(factory));
        emit SolidFactory.MadeBatch(2, 3);

        factory.make(solids);
    }

    // Test that receive() works for refunds
    receive() external payable {}

    function test_BuyWithOneNewSolid() public {
        SolidFactory.BuySpec[] memory specs = new SolidFactory.BuySpec[](1);
        specs[0] = SolidFactory.BuySpec({name: "Hydrogen", symbol: "H", eth: 1 ether});

        SolidFactory.BuyResult[] memory results = factory.buy{value: 1 ether}(specs);

        assertEq(results.length, 1, "should have one result");
        assertEq(results[0].eth, 1 ether, "eth should match");
        assertGt(results[0].tokens, 0, "should receive tokens");
        assertEq(results[0].solid.balanceOf(address(this)), results[0].tokens, "balance should match tokens");

        // Verify the Solid was actually created
        (bool yes,,) = N.made("Hydrogen", "H");
        assertTrue(yes, "Hydrogen should exist");
    }

    function test_BuyWithMultipleSolids() public {
        SolidFactory.BuySpec[] memory specs = new SolidFactory.BuySpec[](3);
        specs[0] = SolidFactory.BuySpec({name: "Hydrogen", symbol: "H", eth: 1 ether});
        specs[1] = SolidFactory.BuySpec({name: "Helium", symbol: "He", eth: 2 ether});
        specs[2] = SolidFactory.BuySpec({name: "Lithium", symbol: "Li", eth: 0.5 ether});

        SolidFactory.BuyResult[] memory results = factory.buy{value: 3.5 ether}(specs);

        assertEq(results.length, 3, "should have three results");

        // Check each result
        assertEq(results[0].eth, 1 ether, "first eth should match");
        assertGt(results[0].tokens, 0, "should receive Hydrogen tokens");
        assertEq(results[0].solid.balanceOf(address(this)), results[0].tokens, "Hydrogen balance should match");

        assertEq(results[1].eth, 2 ether, "second eth should match");
        assertGt(results[1].tokens, 0, "should receive Helium tokens");
        assertEq(results[1].solid.balanceOf(address(this)), results[1].tokens, "Helium balance should match");

        assertEq(results[2].eth, 0.5 ether, "third eth should match");
        assertGt(results[2].tokens, 0, "should receive Lithium tokens");
        assertEq(results[2].solid.balanceOf(address(this)), results[2].tokens, "Lithium balance should match");
    }

    function test_BuyWithExistingSolid() public {
        // Create and fund Hydrogen first
        ISolid H = N.make("Hydrogen", "H");
        vm.deal(address(H), 5 ether);

        SolidFactory.BuySpec[] memory specs = new SolidFactory.BuySpec[](1);
        specs[0] = SolidFactory.BuySpec({name: "Hydrogen", symbol: "H", eth: 1 ether});

        SolidFactory.BuyResult[] memory results = factory.buy{value: 1 ether}(specs);

        assertEq(results.length, 1, "should have one result");
        assertEq(address(results[0].solid), address(H), "should be same Solid");
        assertGt(results[0].tokens, 0, "should receive tokens");
    }

    function test_BuyRevertsWithInsufficientETH() public {
        SolidFactory.BuySpec[] memory specs = new SolidFactory.BuySpec[](2);
        specs[0] = SolidFactory.BuySpec({name: "Hydrogen", symbol: "H", eth: 1 ether});
        specs[1] = SolidFactory.BuySpec({name: "Helium", symbol: "He", eth: 2 ether});

        vm.expectRevert(abi.encodeWithSelector(SolidFactory.InsufficientETH.selector, 3 ether, 2 ether));
        factory.buy{value: 2 ether}(specs);
    }

    function test_BuyRefundsExcessETH() public {
        SolidFactory.BuySpec[] memory specs = new SolidFactory.BuySpec[](1);
        specs[0] = SolidFactory.BuySpec({name: "Hydrogen", symbol: "H", eth: 1 ether});

        uint256 balanceBefore = address(this).balance;
        factory.buy{value: 5 ether}(specs);
        uint256 balanceAfter = address(this).balance;

        // Should have been refunded 4 ether
        assertEq(balanceBefore - balanceAfter, 1 ether, "should only spend 1 ether");
    }

    function test_BuyEmitsBoughtBatchEvent() public {
        SolidFactory.BuySpec[] memory specs = new SolidFactory.BuySpec[](2);
        specs[0] = SolidFactory.BuySpec({name: "Hydrogen", symbol: "H", eth: 1 ether});
        specs[1] = SolidFactory.BuySpec({name: "Helium", symbol: "He", eth: 2 ether});

        vm.expectEmit(true, true, true, true, address(factory));
        emit SolidFactory.BoughtBatch(2, 3 ether);

        factory.buy{value: 3 ether}(specs);
    }
}
