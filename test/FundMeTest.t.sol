// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FundMe} from "../src/FundMe.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

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
        assertEq(fundMe.i_owner(), msg.sender);
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
}
