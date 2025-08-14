// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {AiCCIPProxy} from "../src/AiCCIPProxy.sol"; 

/**
 * @title DeployScript
 * @notice Sample deployment script for Mantle Hackathon contracts
 * @dev This script demonstrates how to deploy contracts using Foundry
 */
contract DeployAiCcipProxy is Script {
    // Deployment addresses
    address public deployer;

    function setUp() public {
        deployer = vm.envAddress("DEV2_ADDRESS");
        
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
    }

    function run() public returns (address aiCcipProxyAddress) {
        // Load private key for deployment      
        console.log("Starting deployment...");        
        vm.startBroadcast();

        AiCCIPProxy aiCcipProxy = new AiCCIPProxy(
            vm.envAddress("ROUTER_11155111"),
            vm.envAddress("LINK_11155111"),
            vm.envAddress("ORACLE_11155111"),
            uint64(vm.envUint("CHAIN_SELECTOR_5003")), // destination chain. 
            vm.envString("API_URL"),
            vm.envBytes32("JOB_ID"),
            deployer
        );
        aiCcipProxyAddress = address(aiCcipProxy);

        vm.stopBroadcast();

        // Log deployment results
        console.log("=== Deployment Results ===");
        console.log("AiCcipProxy deployed to:", aiCcipProxyAddress);
    }
} 