// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {AddressAnalysis} from "../src/AddressAnalysis.sol";

/**
 * @title DeployScript
 * @notice Sample deployment script for Mantle Hackathon contracts
 * @dev This script demonstrates how to deploy contracts using Foundry
 */
contract DeployAddressAnalysis is Script {
    // Deployment addresses
    address public deployer;

    function setUp() public {
        deployer = vm.envAddress("DEV2_ADDRESS");
        
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
    }

    function run() public returns (address addressAnalysisAddress) {
        // Load private key for deployment      
        console.log("Starting deployment...");        
        vm.startBroadcast();

        AddressAnalysis addressAnalysis = new AddressAnalysis(
            vm.envAddress("ROUTER_5003"),
            vm.envAddress("LINK_5003"),
            uint64(vm.envUint("CHAIN_SELECTOR_11155111")), // destination chain 
            vm.envAddress("AI_CCIP_PROXY_11155111")
        );
        addressAnalysisAddress = address(addressAnalysis);

        vm.stopBroadcast();

        // Log deployment results
        console.log("=== Deployment Results ===");
        console.log("AddressAnalysis deployed to:", addressAnalysisAddress);
    }
} 