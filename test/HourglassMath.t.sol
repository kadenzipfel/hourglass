// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Exp64x64} from "../src/lib/Exp64x64.sol";
import {Math64x64} from "../src/lib/Math64x64.sol";
import {HourglassMath} from "../src/lib/HourglassMath.sol";

// Desmos: https://www.desmos.com/calculator/nd1hdofteg

contract HourglassMathTest is Test {
    using Math64x64 for int128;
    using Math64x64 for uint128;
    using Math64x64 for int256;
    using Math64x64 for uint256;
    using Exp64x64 for uint128;
    using Exp64x64 for int128;

    // Make _calculateTm visibility public/external to run below test

    // function test_calculateTm() public {
    //     uint128 tm0 = HourglassMath._calculateTm(999, 1000);
    //     assertEq(tm0, 18428297329635842064);

    //     uint128 tm1 = HourglassMath._calculateTm(500, 1000);
    //     assertEq(tm1, 9223372036854775808);

    //     uint128 tm2 = HourglassMath._calculateTm(1, 1000);
    //     assertEq(tm2, 18446744073709551);
    // }

    // Make _calculateZ visibility public/external to run below test

    // function test_calculateZ() public {
    //     int128 z0 = HourglassMath._calculateZ(18428297329635842064);
    //     assertEq(z0, -9230295335538516);

    //     int128 z1 = HourglassMath._calculateZ(9223372036854775808);
    //     assertEq(z1, -7640891576956012809);

    //     int128 z2 = HourglassMath._calculateZ(18446744073709551);
    //     assertEq(z2, -564890522797642047355);
    // }

    // ================================================================
    //                 tokenXReservesAtTokenYReserves
    // ================================================================

    function testTokenXReservesAtTokenYReservesReverts() public {
        // Zero tokenYReserves
        vm.expectRevert();
        HourglassMath.tokenXReservesAtTokenYReserves(0, 10_000, 100, 1000);

        // Zero liquidity
        vm.expectRevert();
        HourglassMath.tokenXReservesAtTokenYReserves(100, 0, 100, 1000);
    }

    function testTokenXReservesAtTokenYReservesBaseCases() public {
        uint128[5] memory tokenYReservesAmounts = [
            uint128(100_000 * 1e18),
            uint128(8032 * 1e18),
            uint128(65_032 * 1e18),
            uint128(95_322 * 1e18),
            uint128(5373 * 1e18)
        ];
        uint128[5] memory liquidityAmounts = [
            uint128(100_000 * 1e18),
            uint128(86_530 * 1e18),
            uint128(39_530 * 1e18),
            uint128(140_330 * 1e18),
            uint128(1340 * 1e18)
        ];
        uint128[5] memory timeRemainingAmounts = [uint128(999), uint128(750), uint128(500), uint128(250), uint128(50)];
        uint128[5] memory marketSpanAmounts = [uint128(1000), uint128(1000), uint128(1000), uint128(1000), uint128(1000)];
        uint128[5] memory expectedTokenXReserves =
            [uint128(100_000), uint128(3_866_584), uint128(26_168), uint128(265_861), uint128(1098)];

        for (uint256 i; i < timeRemainingAmounts.length; i++) {
            uint128 result = HourglassMath.tokenXReservesAtTokenYReserves(
                tokenYReservesAmounts[i], liquidityAmounts[i], timeRemainingAmounts[i], marketSpanAmounts[i]
            ) / 1e18;

            assertEq(result, expectedTokenXReserves[i]);
        }
    }

    function testTokenXReservesAtTokenYReservesMirror(uint256 tokenYReserves) public {
        vm.assume(tokenYReserves < 1_000_000_000 * 1e18 && tokenYReserves > 1 * 1e18);

        uint128 tokenXReserves =
            HourglassMath.tokenXReservesAtTokenYReserves(tokenYReserves, 1_000_000 * 1e18, 999, 1000);
        uint128 tokenYReservesMirror =
            HourglassMath.tokenXReservesAtTokenYReserves(tokenXReserves, 1_000_000 * 1e18, 999, 1000);

        assertApproxEqAbs(tokenYReserves / 1e18, tokenYReservesMirror / 1e18, 1);
    }

    // ================================================================
    //                    tokensOutForCollateralIn
    // ================================================================

    function testTokensOutForCollateralInReverts() public {
        // Zero tokenXReserves
        vm.expectRevert();
        HourglassMath.tokensOutForCollateralIn(10, 0, 100, 100, 500, 1000);

        // Zero tokenYReserves
        vm.expectRevert();
        HourglassMath.tokensOutForCollateralIn(10, 100, 0, 100, 500, 1000);

        // Zero liquidity
        vm.expectRevert();
        HourglassMath.tokensOutForCollateralIn(10, 100, 100, 0, 500, 1000);
    }

    function testTokensOutForCollateralInBaseCases() public {
        uint256[5] memory collateralInAmounts = [
            uint256(100_000 * 1e18),
            uint256(81_400 * 1e18),
            uint256(89_400 * 1e18),
            uint256(63_000 * 1e18),
            uint256(32_600 * 1e18)
        ];
        uint256[5] memory tokenXReservesAmounts = [
            uint256(100_000 * 1e18),
            uint256(63_000 * 1e18),
            uint256(91_000 * 1e18),
            uint256(31_000 * 1e18),
            uint256(89_500 * 1e18)
        ];
        uint256[5] memory tokenYReservesAmounts = [
            uint256(100_000 * 1e18),
            uint256(100_721379115 * 1e12),
            uint256(52_4342901833 * 1e11),
            uint256(85_917982812 * 1e12),
            uint256(74_7956167113 * 1e11)
        ];
        uint256[5] memory liquidityAmounts = [
            uint256(100_000 * 1e18),
            uint256(79_400 * 1e18),
            uint256(68_000 * 1e18),
            uint256(46_500 * 1e18),
            uint256(80_700 * 1e18)
        ];
        uint128[5] memory timeRemainingAmounts = [
            uint128(999),
            uint128(800),
            uint128(500),
            uint128(300),
            uint128(50)
        ];
        uint256[5] memory expectedTokensOut = [
            uint256(149_987),
            uint256(107_119),
            uint256(141_665),
            uint256(68_026),
            uint256(51_983)
        ];

        for (uint256 i; i < timeRemainingAmounts.length; i++) {
            uint256 result = HourglassMath.tokensOutForCollateralIn(
                collateralInAmounts[i],
                tokenXReservesAmounts[i],
                tokenYReservesAmounts[i],
                liquidityAmounts[i],
                timeRemainingAmounts[i],
                1000
            ) / 1e18;

            assertEq(result, expectedTokensOut[i]);
        }
    }

    // ================================================================
    //                    tokensInForCollateralOut
    // ================================================================

    function testTokensInForCollateralOutReverts() public {
        // Zero tokenYReserves
        vm.expectRevert();
        HourglassMath.tokensInForCollateralOut(10, 100, 0, 100, 500, 1000);

        // Zero liquidity
        vm.expectRevert();
        HourglassMath.tokensInForCollateralOut(10, 100, 100, 0, 500, 1000);
    }

    function testTokensInForCollateralOutBaseCases() public {
        uint256[5] memory collateralOutAmounts = [
            uint256(50_000 * 1e18),
            uint256(34_032 * 1e18),
            uint256(62_000 * 1e18),
            uint256(23_000 * 1e18),
            uint256(10_000 * 1e18)
        ];
        uint256[5] memory tokenXReservesAmounts = [
            uint256(100_000 * 1e18),
            uint256(59_600 * 1e18),
            uint256(87_000 * 1e18),
            uint256(69_600 * 1e18),
            uint256(73_000 * 1e18)
        ];
        uint256[5] memory tokenYReservesAmounts = [
            uint256(100_000 * 1e18),
            uint256(79_0356867653 * 1e11),
            uint256(98_2864736675 * 1e11),
            uint256(91_0080760435 * 1e11),
            uint256(69_2238627315 * 1e11)
        ];
        uint256[5] memory liquidityAmounts = [
            uint256(100_000 * 1e18),
            uint256(68_500 * 1e18),
            uint256(92_400 * 1e18),
            uint256(79_000 * 1e18),
            uint256(71_000 * 1e18)
        ];
        uint128[5] memory timeRemainingAmounts = [
            uint128(999),
            uint128(700),
            uint128(500),
            uint128(300),
            uint128(50)
        ];
        uint256[5] memory expectedTokensIn = [
            uint256(150_048),
            uint256(82_685),
            uint256(408_372),
            uint256(47_133),
            uint256(66_838)
        ];

        for (uint256 i; i < timeRemainingAmounts.length; i++) {
            uint256 result = HourglassMath.tokensInForCollateralOut(
                collateralOutAmounts[i],
                tokenXReservesAmounts[i],
                tokenYReservesAmounts[i],
                liquidityAmounts[i],
                timeRemainingAmounts[i],
                1000
            ) / 1e18;

            assertEq(result, expectedTokensIn[i]);
        }
    }
}
