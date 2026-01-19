// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {Escrow} from "../src/Escrow.sol";

contract DeployEscrow is Script {
    function run() external {
        uint256 buyerPrivateKey = vm.envUint("PRIVATE_KEY");
        address seller = 0x69940B828AfEC298C93687D85328146CC32c6e82;
        uint256 amount = 1 ether;

        vm.startBroadcast(buyerPrivateKey);
        Escrow escrow = new Escrow(seller, amount);
        vm.stopBroadcast();

        console.log("Escrow deployed at:", address(escrow));
        console.log("Buyer:", escrow.buyer());
        console.log("Seller:", escrow.seller());
        console.log("Escrow:", escrow.amount());
    }
}
