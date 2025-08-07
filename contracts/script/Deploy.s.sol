// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";

/**
 * @title DeployScript
 * @notice Sample deployment script for Mantle Hackathon contracts
 * @dev This script demonstrates how to deploy contracts using Foundry
 */
contract DeployScript is Script {
    // Deployment addresses
    address public deployer;
    
    // Contract addresses (will be set after deployment)
    address public tokenAddress;
    address public vaultAddress;
    address public governanceAddress;

    function setUp() public {
        // Load deployment parameters from environment
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
    }

    function run() public {
        // Load private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("Starting deployment...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy contracts here
        // Example: deploy a simple token
        // MyToken token = new MyToken("Mantle Token", "MTL");
        // tokenAddress = address(token);
        
        // Example: deploy a vault
        // MyVault vault = new MyVault(address(token));
        // vaultAddress = address(vault);
        
        // Example: deploy governance contract
        // MyGovernance governance = new MyGovernance();
        // governanceAddress = address(governance);

        vm.stopBroadcast();

        // Log deployment results
        console.log("=== Deployment Results ===");
        console.log("Token deployed to:", tokenAddress);
        console.log("Vault deployed to:", vaultAddress);
        console.log("Governance deployed to:", governanceAddress);
        
        // Save deployment addresses to environment
        vm.setEnv("TOKEN_CONTRACT_ADDRESS", vm.toString(tokenAddress));
        vm.setEnv("VAULT_CONTRACT_ADDRESS", vm.toString(vaultAddress));
        vm.setEnv("GOVERNANCE_CONTRACT_ADDRESS", vm.toString(governanceAddress));
    }

    /**
     * @notice Post-deployment configuration
     * @dev This function can be called after deployment to configure contracts
     */
    function configure() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("Configuring deployed contracts...");
        
        vm.startBroadcast(deployerPrivateKey);

        // Configure contracts here
        // Example: grant roles, set parameters, etc.
        
        vm.stopBroadcast();
        
        console.log("Configuration completed");
    }
} 