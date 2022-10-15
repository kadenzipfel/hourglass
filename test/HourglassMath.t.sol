// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Exp64x64} from "../src/lib/Exp64x64.sol";
import {Math64x64} from "../src/lib/Math64x64.sol";
import {HourglassMath} from "../src/lib/HourglassMath.sol";

// Desmos: https://www.desmos.com/calculator/uqdttqegtp

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

    function test_tokenXReservesAtTokenYReserves__mirror(uint256 tokenYReserves)
        public
    {
        vm.assume(tokenYReserves < 1_000_000_000 * 1e18 && tokenYReserves > 1 * 1e18);

        uint128 tokenXReserves = HourglassMath.tokenXReservesAtTokenYReserves(tokenYReserves, 1_000_000 * 1e18, 999, 1000);
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
}
