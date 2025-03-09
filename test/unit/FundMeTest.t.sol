// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FundMe} from "../../src/FundMe.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address alice = makeAddr("alice");

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(alice, STARTING_BALANCE); // we are giving our fake user some starting balance
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testFundFailsWIthoutEnoughETH() public {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.fund(); // <- We send 0 value
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testCheckPriceFeedVersion() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    /*function testFundUpdatesFundDataStructure() public {
    fundMe.fund{value: 10 ether}(); //we are calling the fund fn in the contract and sending 10 ether
    uint256 amountFunded = fundMe.getAddressToAmountFunded(address(this));
    assertEq(amountFunded, 10 ether);

    }*/

    function testFundUpdatesFundDataStructure() public {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(alice);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(alice);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, alice);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(alice);
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }

    function testPrintStorageData() public view {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }
}
