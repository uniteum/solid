// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {ISolid} from "isolid/ISolid.sol";
import {Solid} from "../src/Solid.sol";
import {BaseTest} from "./Base.t.sol";

contract BondingCurveTest is BaseTest {
    Solid public N;
    ISolid public H;

    receive() external payable {}

    function setUp() public virtual override {
        super.setUp();
        N = new Solid();
        H = N.make("Hydrogen", "H");
    }

    /**
     * Test that buying and selling are approximate inverses
     */
    function test_BuySellInverse() public {
        // Buy with 1 ETH
        uint256 sol = H.buy{value: 1 ether}();

        // Sell all tokens back
        uint256 ethBack = H.sell(sol);

        // Should get ~all ETH back (within 1% due to rounding)
        assertApproxEqRel(ethBack, 1 ether, 0.01e18, "buy->sell should be ~inverse");
    }

    /**
     * Test that selling and buying are approximate inverses
     */
    function test_SellBuyInverse() public {
        // First buy to get tokens
        uint256 initialBuy = H.buy{value: 10 ether}();

        // Sell half
        uint256 halfTokens = initialBuy / 2;
        uint256 ethReceived = H.sell(halfTokens);

        // Buy back with that ETH
        uint256 tokensBack = H.buy{value: ethReceived}();

        // Should get ~same tokens back (within 1%)
        assertApproxEqRel(tokensBack, halfTokens, 0.01e18, "sell->buy should be ~inverse");
    }

    /**
     * Test that price increases with supply
     */
    function test_PriceIncreasesWithSupply() public {
        // First buy: get baseline price
        uint256 sol1 = H.buy{value: 1 ether}();
        uint256 price1 = (1 ether * 1e18) / sol1; // Price per token in wei

        // Second buy: same ETH should get fewer tokens
        uint256 sol2 = H.buy{value: 1 ether}();
        uint256 price2 = (1 ether * 1e18) / sol2;

        // Price should increase
        assertGt(price2, price1, "price should increase with supply");
        assertLt(sol2, sol1, "should get fewer tokens at higher supply");
    }

    /**
     * Test marginal price increases throughout buy
     */
    function test_MarginalPriceIncreases() public {
        // Buy in small increments and check price goes up
        uint256[] memory prices = new uint256[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 sol = H.buy{value: 0.1 ether}();
            prices[i] = (0.1 ether * 1e18) / sol;
        }

        // Each subsequent buy should have higher price
        for (uint256 i = 1; i < 5; i++) {
            assertGt(prices[i], prices[i - 1], "marginal price should increase");
        }
    }

    /**
     * Test buys() preview matches actual buy()
     */
    function test_BuysPreviewMatchesBuy(uint256 amount) public {
        amount = bound(amount, 0.001 ether, 10 ether);

        uint256 preview = H.buys(amount);
        uint256 actual = H.buy{value: amount}();

        assertEq(actual, preview, "buys preview should match buy");
    }

    /**
     * Test sells() preview matches actual sell()
     */
    function test_SellsPreviewMatchesSell(uint256 ethAmount) public {
        ethAmount = bound(ethAmount, 0.01 ether, 5 ether);

        // Buy first to get tokens
        uint256 tokens = H.buy{value: ethAmount}();

        // Preview sell
        uint256 preview = H.sells(tokens);

        // Actual sell
        uint256 actual = H.sell(tokens);

        assertEq(actual, preview, "sells preview should match sell");
    }

    /**
     * Test that buying twice the ETH doesn't give twice the tokens (non-linear)
     */
    function test_NonLinearCurve() public {
        uint256 sol1 = H.buy{value: 1 ether}();
        uint256 sol2 = H.buy{value: 2 ether}(); // 2x ETH at higher supply

        // Should NOT get 2x tokens (curve is super-linear)
        assertLt(sol2, 2 * sol1, "2x ETH should give <2x tokens (super-linear curve)");
    }

    /**
     * Test roundtrip at various supply levels
     */
    function test_RoundtripAtVariousSupplies(uint256 seed) public {
        // Build up random supply (bound to reasonable values)
        seed = bound(seed, 0, 10 ether);
        if (seed > 0) {
            H.buy{value: seed}();
        }

        // Now do roundtrip
        uint256 testAmount = 0.5 ether;
        uint256 tokens = H.buy{value: testAmount}();
        uint256 ethBack = H.sell(tokens);

        // Should get ~all ETH back (allow 2% for rounding at higher supplies)
        assertApproxEqRel(ethBack, testAmount, 0.02e18, "roundtrip should preserve value");
    }

    /**
     * Test that total cost equals sum of marginal costs
     * For quadratic curves, buying incrementally at increasing prices gives slightly MORE tokens
     * than buying all at once at the average price
     */
    function test_IntegralProperty() public {
        // Buy 1 ETH worth all at once
        uint256 tokensBulk = H.buys(1 ether);

        // Reset
        H = N.make("Helium", "He");

        // Buy in 10 increments of 0.1 ETH
        uint256 tokensIncremental = 0;
        for (uint256 i = 0; i < 10; i++) {
            tokensIncremental += H.buy{value: 0.1 ether}();
        }

        // For quadratic curve: incremental gives slightly more due to pricing granularity
        // But should be within reasonable range (1% for small increments)
        assertApproxEqRel(
            tokensIncremental, tokensBulk, 0.01e18, "incremental vs bulk should be within 1%"
        );
    }

    /**
     * Test that sell refund never exceeds buy cost at same supply
     */
    function test_NoArbitrage() public {
        uint256 buyAmount = 1 ether;

        // Buy tokens
        uint256 tokens = H.buy{value: buyAmount}();

        // Sell immediately
        uint256 sellAmount = H.sell(tokens);

        // Should get back less than or equal to what we paid (no free profit)
        assertLe(sellAmount, buyAmount, "sell should not exceed buy cost");
    }

    /**
     * Test supply increases monotonically with buys
     */
    function test_SupplyIncreasesMonotonically() public {
        uint256 supply0 = H.totalSupply();
        assertEq(supply0, 0, "should start at 0");

        H.buy{value: 0.1 ether}();
        uint256 supply1 = H.totalSupply();
        assertGt(supply1, supply0, "supply should increase");

        H.buy{value: 0.1 ether}();
        uint256 supply2 = H.totalSupply();
        assertGt(supply2, supply1, "supply should keep increasing");
    }

    /**
     * Test supply decreases monotonically with sells
     */
    function test_SupplyDecreasesMonotonically() public {
        // Buy to build supply
        uint256 tokens = H.buy{value: 1 ether}();
        uint256 supply0 = H.totalSupply();

        // Sell half
        H.sell(tokens / 2);
        uint256 supply1 = H.totalSupply();
        assertLt(supply1, supply0, "supply should decrease");

        // Sell rest
        H.sell(tokens / 2);
        uint256 supply2 = H.totalSupply();
        assertLt(supply2, supply1, "supply should keep decreasing");
    }
}
