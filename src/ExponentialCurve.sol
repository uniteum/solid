// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @notice Pure math for exponential bonding curve with safe fixed-point pow:
///         p(s) = p0 * r^s, where r is WAD-scaled (1e18).
library ExponentialCurve {
    uint256 internal constant WAD = 1e18;

    error RTooSmall(); // rWad <= 1e18
    error ZeroDenominator(); // den == 0
    error Overflow();
    error Underflow();

    // ----------------------------
    // Public curve functions
    // ----------------------------

    /// @notice Convert rational r = num/den to WAD.
    function toWad(uint256 num, uint256 den) internal pure returns (uint256 rWad) {
        if (den == 0) {
            revert ZeroDenominator();
        }
        rWad = mulDiv(num, WAD, den);
    }

    /// @notice Marginal price at supply s: p0 * r^s
    function price(uint256 p0, uint256 rWad, uint256 s) internal pure returns (uint256) {
        if (rWad <= WAD) {
            revert RTooSmall();
        }
        uint256 rPow = powWad(rWad, s);
        return mulDiv(p0, rPow, WAD);
    }

    /// @notice Cost to mint dx from supply s (discrete geometric series).
    function cost(uint256 p0, uint256 rWad, uint256 s, uint256 dx) internal pure returns (uint256) {
        if (dx == 0) {
            return 0;
        }
        if (rWad <= WAD) {
            revert RTooSmall();
        }

        uint256 rS = powWad(rWad, s); // WAD
        uint256 rDx = powWad(rWad, dx); // WAD

        // priceAtS = p0 * rS / WAD
        uint256 priceAtS = mulDiv(p0, rS, WAD);

        // factor = (rDx - WAD) / (rWad - WAD)  (both WAD-ish, but ratio is dimensionless)
        uint256 nume = rDx - WAD;
        uint256 deno = rWad - WAD;

        // cost = priceAtS * factor
        // factor is rational; do mulDiv to keep precision: priceAtS * nume / deno
        return mulDiv(priceAtS, nume, deno);
    }

    /// @notice Refund to burn dx from supply s (requires dx <= s).
    function refund(uint256 p0, uint256 rWad, uint256 s, uint256 dx) internal pure returns (uint256) {
        if (dx == 0) {
            return 0;
        }
        if (dx > s) {
            revert Underflow();
        }
        if (rWad <= WAD) {
            revert RTooSmall();
        }

        // refund is cost evaluated starting at (s - dx)
        return cost(p0, rWad, s - dx, dx);
    }

    // ----------------------------
    // Fixed-point pow (WAD)
    // ----------------------------

    /// @notice Computes (rWad^e) in WAD, using exponentiation-by-squaring with rescaling each multiply.
    function powWad(uint256 rWad, uint256 e) internal pure returns (uint256) {
        uint256 result = WAD;
        uint256 base = rWad;

        while (e != 0) {
            if ((e & 1) != 0) {
                result = mulDiv(result, base, WAD);
            }
            e >>= 1;
            if (e != 0) {
                base = mulDiv(base, base, WAD);
            }
        }
        return result;
    }

    // ----------------------------
    // 512-bit mulDiv (floor)
    // ----------------------------

    /// @notice Computes floor(a*b/den) with full precision. Reverts on overflow or division by zero.
    function mulDiv(uint256 a, uint256 b, uint256 den) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(den > 0, "Division by zero");
                assembly {
                    result := div(prod0, den)
                }
                return result;
            }

            // Make sure the result is less than 2^256. Also prevents den == 0
            require(den > prod1, "Overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, den)
                prod0 := sub(prod0, remainder)
                prod1 := sub(prod1, lt(prod0, remainder))
            }

            // Factor powers of two out of denominator
            uint256 twos = den & (~den + 1);
            assembly {
                den := div(den, twos)
                prod0 := div(prod0, twos)
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that den is odd, it has an inverse
            // modulo 2^256 such that den * inv = 1 mod 2^256.
            uint256 inv = (3 * den) ^ 2;
            inv *= 2 - den * inv; // inverse mod 2^8
            inv *= 2 - den * inv; // inverse mod 2^16
            inv *= 2 - den * inv; // inverse mod 2^32
            inv *= 2 - den * inv; // inverse mod 2^64
            inv *= 2 - den * inv; // inverse mod 2^128
            inv *= 2 - den * inv; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2^256. Since the precoditions guarantee
            // that the outcome is less than 2^256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            assembly {
                result := mul(prod0, inv)
            }
            return result;
        }
    }
}
