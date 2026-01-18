// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow escrow; // The contract instance, to be initialized in setUp()

    address buyer = address(1);
    address seller = address(2);
    uint256 amount = 1 ether;
    uint256 timeout = 3 days;

    function setUp() external {
        vm.deal(buyer, 10 ether); // Fund the buyer with 10 ether
        vm.deal(seller, 1 ether); // Fund the seller with 1 ether

        vm.prank(buyer);
        escrow = new Escrow(seller, amount);
    }

    /** DEPLOYMENT */
    function testInitialState() external {
        assertEq(
            uint256(escrow.currentStatus()),
            uint256(Escrow.Status.AWAITING_PAYMENT)
        );
        assertEq(escrow.buyer(), buyer);
        assertEq(escrow.seller(), seller);
        assertEq(escrow.amount(), amount);
    }

    /** DEPOSIT */
    function testDepositFailsIfNotBuyer() external {
        //vm.prank(seller);
        vm.expectRevert(Escrow.NotBuyer.selector);
        escrow.deposit{value: amount}();
    }

    function testDepositFailsInWrongState() external {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        // Now the state is AWAITING_DELIVERY
        vm.prank(buyer);
        vm.expectRevert(Escrow.InvalidState.selector);
        escrow.deposit{value: amount}();
    }

    function testDepositFailsWithWrongETHAmount() external {
        vm.prank(buyer);
        vm.expectRevert(Escrow.IncorrectETHAmount.selector);
        escrow.deposit{value: amount - 1 ether}();
    }

    function testIfDeadlineIsSetAfterDeposit() external {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        uint256 expectedDeadline = block.timestamp + 3 days;
        assertEq(escrow.deadline(), expectedDeadline);
    }

    function testSuccessfulDeposit() external {
        vm.prank(buyer);
        escrow.deposit{value: amount}();
        assertEq(
            uint256(escrow.currentStatus()),
            uint256(Escrow.Status.AWAITING_DELIVERY)
        );
    }

    /** SELLER CONFIRM DELIVERY */
    function testIfItSentToSellerOnly() external {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(address(3)); // Some random address
        vm.expectRevert(Escrow.NotSeller.selector);
        escrow.sellerConfirmDelivery();
    }

    function testIfItFailsInWrongState() external {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.sellerConfirmDelivery();

        // Now the state is AWAITING_ACCEPTANCE
        vm.prank(seller);
        vm.expectRevert(Escrow.InvalidState.selector);
        escrow.sellerConfirmDelivery();
    }

    function testStatusIsAwaitingAcceptance() external {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.sellerConfirmDelivery();

        assertEq(
            uint256(escrow.currentStatus()),
            uint256(Escrow.Status.AWAITING_ACCEPTANCE)
        );
    }

    function testSuccessfulSellerConfirmDelivery() external {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.sellerConfirmDelivery();

        assertEq(
            uint256(escrow.currentStatus()),
            uint256(Escrow.Status.AWAITING_ACCEPTANCE)
        );
    }

    /** BUYER ACCEPT DELIVERY */
    function testIfItSentToBuyerOnly() external {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.sellerConfirmDelivery();

        vm.prank(address(3)); // Some random address
        vm.expectRevert(Escrow.NotBuyer.selector);
        escrow.buyerAcceptDelivery();
    }

    function testIfItIsInCorrectState() external {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        // Now the state is AWAITING_DELIVERY
        vm.prank(buyer);
        vm.expectRevert(Escrow.InvalidState.selector);
        escrow.buyerAcceptDelivery();
    }
}
