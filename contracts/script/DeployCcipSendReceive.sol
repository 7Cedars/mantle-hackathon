// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {CCIPSendReceive} from "../src/CCIPSendReceive.sol";

/**
 * @title DeployScript
 * @notice Sample deployment script for Mantle Hackathon contracts
 * @dev This script demonstrates how to deploy contracts using Foundry
 */
contract DeployCcipSendReceive is Script {
    // Deployment addresses
    address public deployer;
    address public router;
    address public link;
    uint64 public destinationChainSelector;

    function setUp() public {
        deployer = vm.envAddress("DEV2_ADDRESS");
        console.log("Deployer address:", deployer);

        if (block.chainid != 5003) {
            revert("This is not the Mantle Testnet");
        }

        router = vm.envAddress("ROUTER_5003");
        link = vm.envAddress("LINK_5003");
        destinationChainSelector = uint64(vm.envUint("CHAIN_SELECTOR_11155111"));
    }

    function run() public returns (address ccipSendReceiveAddress) {
        // Load private key for deployment      
        console.log("Starting deployment...");        
        vm.startBroadcast();

        CCIPSendReceive ccipSendReceive = new CCIPSendReceive(router, link, destinationChainSelector);
        ccipSendReceiveAddress = address(ccipSendReceive);

        vm.stopBroadcast();

        // Log deployment results
        console.log("=== Deployment Results ===");
        console.log("CCIPSendReceive deployed to:", ccipSendReceiveAddress);
    }
} 