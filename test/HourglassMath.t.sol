// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Exp64x64} from "../src/lib/Exp64x64.sol";
import {Math64x64} from "../src/lib/Math64x64.sol";
import {HourglassMath} from "../src/lib/HourglassMath.sol";

// Desmos: https://www.desmos.com/calculator/sbptupjc98

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

    function test_tokenXReservesAtTokenYReserves__reverts() public {
        // Zero tokenYReserves
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        HourglassMath.tokenXReservesAtTokenYReserves(0, 10_000, 100, 1000);

        // Zero liquidity
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        HourglassMath.tokenXReservesAtTokenYReserves(100, 0, 100, 1000);

        // timeRemaining > marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.tokenXReservesAtTokenYReserves(100, 1000, 1000, 100);

        // timeRemaining == marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.tokenXReservesAtTokenYReserves(100, 1000, 1000, 1000);
    }

    function test_tokenXReservesAtTokenYReserves__baseCases() public {
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
        int128[5] memory timeRemainingAmounts = [int128(999), int128(750), int128(500), int128(250), int128(50)];
        int128[5] memory marketSpanAmounts = [int128(1000), int128(1000), int128(1000), int128(1000), int128(1000)];
        uint128[5] memory expectedTokenXReserves =
            [uint128(100_000), uint128(3_866_584), uint128(26_168), uint128(265_861), uint128(1098)];

        for (uint256 i; i < timeRemainingAmounts.length; i++) {
            uint128 result = HourglassMath.tokenXReservesAtTokenYReserves(
                tokenYReservesAmounts[i], liquidityAmounts[i], timeRemainingAmounts[i], marketSpanAmounts[i]
            ) / 1e18;

            assertEq(result, expectedTokenXReserves[i]);
        }
    }

    function test_tokenXReservesAtTokenYReserves__mirror(uint256 tokenYReserves) public {
        vm.assume(tokenYReserves < 1_000_000_000 * 1e18 && tokenYReserves > 1 * 1e18);

        uint128 tokenXReserves =
            HourglassMath.tokenXReservesAtTokenYReserves(tokenYReserves, 1_000_000 * 1e18, 999, 1000);
        uint128 tokenYReservesMirror =
            HourglassMath.tokenXReservesAtTokenYReserves(tokenXReserves, 1_000_000 * 1e18, 999, 1000);

        assertApproxEqAbs(tokenYReserves / 1e18, tokenYReservesMirror / 1e18, 1);
    }

    // ================================================================
    //                     liquidityAtTokenReserves
    // ================================================================

    function test_liquidityAtTokenReserves__reverts() public {
        // Zero tokenXReserves
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        HourglassMath.liquidityAtTokenReserves(0, 10_000, 100, 1000);

        // Zero tokenYReserves
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        HourglassMath.liquidityAtTokenReserves(100, 0, 100, 1000);

        // timeRemaining > marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.liquidityAtTokenReserves(100, 1000, 1000, 100);

        // timeRemaining == marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.liquidityAtTokenReserves(100, 1000, 1000, 1000);
    }

    function test_liquidityAtTokenReserves__baseCases() public {
        uint128[5] memory tokenXReservesAmounts = [
            uint128(100_000 * 1e18),
            uint128(55_375 * 1e18),
            uint128(3782 * 1e18),
            uint128(153_031 * 1e18),
            uint128(3_405_230 * 1e18)
        ];
        uint128[5] memory tokenYReservesAmounts = [
            uint128(100_000 * 1e18),
            uint128(37_652 * 1e18),
            uint128(98_345 * 1e18),
            uint128(240_239 * 1e18),
            uint128(12_304_023 * 1e18)
        ];
        int128[5] memory timeRemainingAmounts = [int128(500), int128(900), int128(300), int128(100), int128(480)];
        int128[5] memory marketSpanAmounts = [int128(1000), int128(1000), int128(1000), int128(1000), int128(1000)];
        uint128[5] memory expectedLiquidity =
            [uint128(100_000), uint128(45_615), uint128(8086), uint128(181_855), uint128(5_914_283)];

        for (uint256 i; i < timeRemainingAmounts.length; i++) {
            uint128 result = HourglassMath.liquidityAtTokenReserves(
                tokenXReservesAmounts[i], tokenYReservesAmounts[i], timeRemainingAmounts[i], marketSpanAmounts[i]
            ) / 1e18;

            assertEq(result, expectedLiquidity[i]);
        }
    }

    function test_liquidityAtTokenReserves__mirror(uint128 tokenXReserves, uint128 tokenYReserves) public {
        vm.assume(tokenXReserves < 1_000_000_000 * 1e18 && tokenXReserves > 1 * 1e18);
        vm.assume(tokenYReserves < 1_000_000_000 * 1e18 && tokenYReserves > 1 * 1e18);

        uint128 liquidity = HourglassMath.liquidityAtTokenReserves(tokenXReserves, tokenYReserves, 500, 1000);
        uint128 tokenXReservesMirror =
            HourglassMath.tokenXReservesAtTokenYReserves(tokenYReserves, liquidity, 500, 1000);

        assertApproxEqAbs(tokenXReserves / 1e18, tokenXReservesMirror / 1e18, 1);
    }

    // ================================================================
    //                    tokensOutForCollateralIn
    // ================================================================

    function test_tokensOutForCollateralIn__reverts() public {
        // Zero tokenXReserves
        vm.expectRevert();
        HourglassMath.tokensOutForCollateralIn(10, 0, 100, 100, 500, 1000);

        // Zero tokenYReserves
        vm.expectRevert();
        HourglassMath.tokensOutForCollateralIn(10, 100, 0, 100, 500, 1000);

        // Zero liquidity
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        HourglassMath.tokensOutForCollateralIn(10, 100, 100, 0, 500, 1000);

        // timeRemaining > marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.tokensOutForCollateralIn(10, 100, 100, 100, 10000, 1000);

        // timeRemaining == marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.tokensOutForCollateralIn(10, 100, 100, 100, 1000, 1000);
    }

    function test_tokensOutForCollateralIn__baseCases() public {
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
        int128[5] memory timeRemainingAmounts = [
            int128(999),
            int128(800),
            int128(500),
            int128(300),
            int128(50)
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

    function test_tokensInForCollateralOut__reverts() public {
        // Zero tokenXReserves
        vm.expectRevert();
        HourglassMath.tokensInForCollateralOut(10, 0, 100, 100, 500, 1000);

        // Zero tokenYReserves
        vm.expectRevert();
        HourglassMath.tokensInForCollateralOut(10, 100, 0, 100, 500, 1000);

        // Zero liquidity
        vm.expectRevert(abi.encodeWithSignature("ZeroValue()"));
        HourglassMath.tokensInForCollateralOut(10, 100, 100, 0, 500, 1000);

        // timeRemaining > marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.tokensInForCollateralOut(10, 100, 100, 100, 10000, 1000);

        // timeRemaining == marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.tokensInForCollateralOut(10, 100, 100, 100, 1000, 1000);
    }

    function test_tokensInForCollateralOut__baseCases() public {
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
        int128[5] memory timeRemainingAmounts = [
            int128(999),
            int128(700),
            int128(500),
            int128(300),
            int128(50)
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

    // ================================================================
    //                    collateralInForTokensOut
    // ================================================================

    function test_collateralInForTokensOut__reverts() public {
        // Zero tokenXReserves
        vm.expectRevert();
        HourglassMath.collateralInForTokensOut(10, 0, 100, 100, 500, 1000);

        // Zero tokenYReserves
        vm.expectRevert();
        HourglassMath.collateralInForTokensOut(10, 100, 0, 100, 500, 1000);

        // Zero liquidity
        vm.expectRevert();
        HourglassMath.collateralInForTokensOut(10, 100, 100, 0, 500, 1000);

        // timeRemaining > marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.collateralInForTokensOut(10, 100, 100, 100, 10000, 1000);

        // timeRemaining == marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.collateralInForTokensOut(10, 100, 100, 100, 1000, 1000);
    }

    // function test_collateralInForTokensOut__baseCases() public {
    //     uint256[5] memory collateralOutAmounts = [
    //         uint256(50_000 * 1e18),
    //         uint256(34_032 * 1e18),
    //         uint256(62_000 * 1e18),
    //         uint256(23_000 * 1e18),
    //         uint256(10_000 * 1e18)
    //     ];
    //     uint256[5] memory tokenXReservesAmounts = [
    //         uint256(100_000 * 1e18),
    //         uint256(59_600 * 1e18),
    //         uint256(87_000 * 1e18),
    //         uint256(69_600 * 1e18),
    //         uint256(73_000 * 1e18)
    //     ];
    //     uint256[5] memory tokenYReservesAmounts = [
    //         uint256(100_000 * 1e18),
    //         uint256(79_0356867653 * 1e11),
    //         uint256(98_2864736675 * 1e11),
    //         uint256(91_0080760435 * 1e11),
    //         uint256(69_2238627315 * 1e11)
    //     ];
    //     uint256[5] memory liquidityAmounts = [
    //         uint256(100_000 * 1e18),
    //         uint256(68_500 * 1e18),
    //         uint256(92_400 * 1e18),
    //         uint256(79_000 * 1e18),
    //         uint256(71_000 * 1e18)
    //     ];
    //     int128[5] memory timeRemainingAmounts = [
    //         int128(999),
    //         int128(700),
    //         int128(500),
    //         int128(300),
    //         int128(50)
    //     ];
    //     uint256[5] memory expectedTokensIn = [
    //         uint256(150_048),
    //         uint256(82_685),
    //         uint256(408_372),
    //         uint256(47_133),
    //         uint256(66_838)
    //     ];

    //     for (uint256 i; i < timeRemainingAmounts.length; i++) {
    //         uint256 result = HourglassMath.collateralInForTokensOut(
    //             collateralOutAmounts[i],
    //             tokenXReservesAmounts[i],
    //             tokenYReservesAmounts[i],
    //             liquidityAmounts[i],
    //             timeRemainingAmounts[i],
    //             1000
    //         ) / 1e18;

    //         assertEq(result, expectedTokensIn[i]);
    //     }
    // }

    // ================================================================
    //                    collateralOutForTokensIn
    // ================================================================

    function test_collateralOutForTokensIn__reverts() public {
        // Zero tokenXReserves
        vm.expectRevert();
        HourglassMath.collateralOutForTokensIn(10, 0, 100, 100, 500, 1000);

        // Zero tokenYReserves
        vm.expectRevert();
        HourglassMath.collateralOutForTokensIn(10, 100, 0, 100, 500, 1000);

        // Zero liquidity
        vm.expectRevert();
        HourglassMath.collateralOutForTokensIn(10, 100, 100, 0, 500, 1000);

        // timeRemaining > marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.collateralOutForTokensIn(10, 100, 100, 100, 10000, 1000);

        // timeRemaining == marketSpan
        vm.expectRevert(abi.encodeWithSignature("InvalidTime()"));
        HourglassMath.collateralOutForTokensIn(10, 100, 100, 100, 1000, 1000);
    }

    function test_collateralOutForTokensIn__baseCases() public {
        uint256[5] memory tokenXInAmounts = [
            uint256(57_200 * 1e18),
            uint256(63_500 * 1e18),
            uint256(67_700 * 1e18),
            uint256(76_200 * 1e18),
            uint256(49_800 * 1e18)
        ];
        uint256[5] memory tokenXReservesAmounts = [
            uint256(55_000 * 1e18),
            uint256(60_700 * 1e18),
            uint256(76_000 * 1e18),
            uint256(41_700 * 1e18),
            uint256(56_000 * 1e18)
        ];
        uint256[5] memory tokenYReservesAmounts = [
            uint256(133_608076 * 1e15),
            uint256(103_046051 * 1e15),
            uint256(82_2477138863 * 1e11),
            uint256(164_447680621 * 1e12),
            uint256(224_645880628 * 1e12)
        ];
        uint256[5] memory liquidityAmounts = [
            uint256(79_1674289457 * 1e11),
            uint256(79_0159969228 * 1e11),
            uint256(79_0366228199 * 1e11),
            uint256(79_1021842019 * 1e11),
            uint256(68_2158463306 * 1e11)
        ];
        int128[5] memory timeRemainingAmounts = [
            int128(300),
            int128(950),
            int128(500),
            int128(700),
            int128(50)
        ];
        uint256[5] memory expectedCollateralOut = [
            uint256(42_885),
            uint256(34100),
            uint256(27_943),
            uint256(59_764),
            uint256(58_358)
        ];

        for (uint256 i; i < timeRemainingAmounts.length; i++) {
            uint256 result = HourglassMath.collateralOutForTokensIn(
                tokenXInAmounts[i],
                tokenXReservesAmounts[i],
                tokenYReservesAmounts[i],
                liquidityAmounts[i],
                timeRemainingAmounts[i],
                1000
            ) / 1e18;

            assertEq(result, expectedCollateralOut[i]);
        }
    }
}
