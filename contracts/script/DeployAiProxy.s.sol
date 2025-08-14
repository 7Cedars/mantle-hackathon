// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {AiProxy} from "../src/AiProxy.sol";

/**
 * @title DeployScript
 * @notice Sample deployment script for Mantle Hackathon contracts
 * @dev This script demonstrates how to deploy contracts using Foundry
 */
contract DeployAiProxy is Script {
    // Deployment addresses
    address public deployer;

    function setUp() public {
        deployer = vm.envAddress("DEV2_ADDRESS");
        
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
    }

    function run() public returns (address aiProxyAddress) {
        // Load private key for deployment      
        console.log("Starting deployment...");        
        vm.startBroadcast();

        AiProxy aiProxy = new AiProxy(
            vm.envAddress("ROUTER_11155111"),
            vm.envAddress("LINK_11155111"),
            vm.envAddress("ORACLE_11155111"),
            uint64(vm.envUint("CHAIN_SELECTOR_5003")), // destination chain. 
            deployer
        );
        aiProxyAddress = address(aiProxy);

        vm.stopBroadcast();

        // Log deployment results
        console.log("=== Deployment Results ===");
        console.log("AiProxy deployed to:", aiProxyAddress);
    }
} 