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

    function test_tokenXReservesAtTokenYReserves__reverts() public {
        // Zero tokenYReserves
        vm.expectRevert(abi.encodeWithSignature("NegativeOrZeroValue()"));
        HourglassMath.tokenXReservesAtTokenYReserves(0, 10_000, 100, 1000);

        // Zero liquidity
        vm.expectRevert(abi.encodeWithSignature("NegativeOrZeroValue()"));
        HourglassMath.tokenXReservesAtTokenYReserves(100, 0, 100, 1000);

        // Negative tokenYReserves
        vm.expectRevert(abi.encodeWithSignature("NegativeOrZeroValue()"));
        HourglassMath.tokenXReservesAtTokenYReserves(-100, 10_000, 100, 1000);

        // Negative liquidity
        vm.expectRevert(abi.encodeWithSignature("NegativeOrZeroValue()"));
        HourglassMath.tokenXReservesAtTokenYReserves(100, -1000, 100, 1000);

        // tokenYReserves > liquidity
        vm.expectRevert();
        HourglassMath.tokenXReservesAtTokenYReserves(1000, 100, 100, 1000);

        // timeRemaining > marketSpan
        vm.expectRevert();
        HourglassMath.tokenXReservesAtTokenYReserves(100, 1000, 1000, 100);
    }
}
