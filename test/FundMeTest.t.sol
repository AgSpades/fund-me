// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {FundMe} from "../src/FundMe.sol";
import {Test, console} from "forge-std/Test.sol";

contract FundMeTest is Test {
    uint256 favNumber = 0;
    bool greatCourse = false;
    FundMe fundMe = new FundMe();

    function setUp() external {
        favNumber = 1337;
        greatCourse = true;
        console.log("This will get printed first!");
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.i_owner(), address(this));
    }
}
