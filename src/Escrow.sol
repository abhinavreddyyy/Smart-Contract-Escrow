// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Smart Contract Escrow
 * @author Abhinav
 * @notice Secure two party escrow with buyer timeout
 */

contract Escrow {
    error NotBuyer();
    error NotSeller();
    error InvalidState(); // Invalid state for this action
    error DeadlineNotReached(); // Deadline to claim funds not reached
    error IncorrectETHAmount(); // Incorrect amount sent
    error ETHTransferFailed(); // ETH transfer failed

    enum Status {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        AWAITING_ACCEPTANCE,
        COMPLETED,
        REFUNDED
    }

    address public immutable buyer;
    address public immutable seller;
    uint256 public immutable amount;
    uint256 public deadline; // Time by which buyer must accept or request refund
    Status public currentStatus;
    uint256 public constant BUYER_REFUND_TIMEOUT = 3 days; // Time after which buyer can claim refund

    event Deposited(address indexed buyer, uint256 amount);
    event SellerConfirmed(address indexed seller);
    event BuyerAccepted(address indexed buyer);
    event Refunded(address indexed buyer);

    constructor(address _seller, uint256 _amount) {
        if (_seller == address(0)) {
            revert NotSeller();
        }
        if (_amount == 0) {
            revert IncorrectETHAmount();
        }
        buyer = msg.sender;
        seller = _seller;
        amount = _amount;
        currentStatus = Status.AWAITING_PAYMENT; // In the Initial state, the only true thing about the contract is that payment is awaited
    }

    function deposit() external payable {
        if (msg.sender != buyer) {
            revert NotBuyer();
        }
        if (currentStatus != Status.AWAITING_PAYMENT) {
            revert InvalidState();
        }
        if (msg.value != amount) {
            revert IncorrectETHAmount();
        }
        currentStatus = Status.AWAITING_DELIVERY;
        deadline = block.timestamp + BUYER_REFUND_TIMEOUT;
        emit Deposited(msg.sender, msg.value);
    }

    function sellerConfirmDelivery() external {
        if (msg.sender != seller) {
            revert NotSeller();
        }
        if (currentStatus != Status.AWAITING_DELIVERY) {
            revert InvalidState();
        }
        currentStatus = Status.AWAITING_ACCEPTANCE;

        emit SellerConfirmed(msg.sender);
    }

    function buyerAcceptDelivery() external {
        if (msg.sender != buyer) {
            revert NotBuyer();
        }
        if (currentStatus != Status.AWAITING_ACCEPTANCE) {
            revert InvalidState();
        }
        currentStatus = Status.COMPLETED;
        (bool success, ) = payable(seller).call{value: amount}("");
        if (!success) {
            revert ETHTransferFailed();
        }
        emit BuyerAccepted(msg.sender);
    }

    function refund() external {
        if (msg.sender != buyer) {
            revert NotBuyer();
        }
        if (
            currentStatus != Status.AWAITING_ACCEPTANCE &&
            currentStatus != Status.AWAITING_DELIVERY
        ) {
            revert InvalidState();
        }
        if (block.timestamp < deadline) {
            revert DeadlineNotReached();
        }
        currentStatus = Status.REFUNDED;
        (bool success, ) = payable(buyer).call{value: amount}("");
        if (!success) {
            revert ETHTransferFailed();
        }
        emit Refunded(msg.sender);
    }
}
