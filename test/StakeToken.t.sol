// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {StakeToken} from "src/projects/StakeToken.sol";

contract StakeTokenTest is Test {
    StakeToken private token;
    address private owner = address(this);
    address private alice = address(0xA11CE);
    address private bob = address(0xB0B);

    uint256 private constant ONE = 1e18;

    function setUp() public {
        token = new StakeToken("UFES Stake Token", "UFES", owner);
        // Mint initial balances
        token.mint(alice, 1_000 * ONE);
        token.mint(bob, 500 * ONE);
    }

    function testOwnerCanMint() public {
        uint256 prev = token.balanceOf(alice);
        token.mint(alice, 100 * ONE);
        assertEq(token.balanceOf(alice), prev + 100 * ONE);
    }

    function testNonOwnerCannotMint() public {
        vm.prank(alice);
        vm.expectRevert();
        token.mint(alice, 1);
    }

    function testBurn() public {
        vm.prank(alice);
        token.burn(10 * ONE);
        assertEq(token.balanceOf(alice), 990 * ONE);
    }

    function testStakeAndUnstakeFlow() public {
        // Alice stakes 100 UFES
        vm.startPrank(alice);
        token.stake(100 * ONE);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 900 * ONE);
        assertEq(token.balanceOf(address(token)), 100 * ONE);
        assertEq(token.stakedOf(alice), 100 * ONE);

        // Advance time by 2 hours → expect ~200 points (1 point per token per hour)
        vm.warp(block.timestamp + 2 hours);
        uint256 pointsView = token.pointsOf(alice);
        assertEq(pointsView, 200 * ONE, "points view after 2h should be 200 per 100 staked");

        // Claim points and check reset
        vm.prank(alice);
        uint256 claimed = token.claimPoints();
        assertEq(claimed, 200 * ONE);
        assertEq(token.pointsOf(alice), 0);

        // Unstake 60
        vm.prank(alice);
        token.unstake(60 * ONE);
        assertEq(token.stakedOf(alice), 40 * ONE);
        assertEq(token.balanceOf(alice), 960 * ONE);
        assertEq(token.balanceOf(address(token)), 40 * ONE);

        // Advance 1 hour → expect 40 points pending
        vm.warp(block.timestamp + 1 hours);
        assertEq(token.pointsOf(alice), 40 * ONE);
    }

    function testMultipleStakesAccrual() public {
        vm.startPrank(alice);
        token.stake(50 * ONE);
        vm.warp(block.timestamp + 1 hours);
        // 50 points pending
        assertEq(token.pointsOf(alice), 50 * ONE);

        // Stake more, should realize previous pending then continue
        token.stake(50 * ONE); // total staked 100
        // After stake, previously pending (50) is realized; pending resets to 0
        assertEq(token.pointsOf(alice), 50 * ONE);

        vm.warp(block.timestamp + 3 hours);
        // Now 100 tokens for 3 hours => 300 points, plus 50 realized = 350 total
        assertEq(token.pointsOf(alice), 350 * ONE);

        // Claim
        uint256 claimed = token.claimPoints();
        assertEq(claimed, 350 * ONE);
        assertEq(token.pointsOf(alice), 0);
        vm.stopPrank();
    }
}


