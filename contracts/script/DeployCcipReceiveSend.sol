// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {CCIPReceiveSend} from "../src/CCIPReceiveSend.sol";

/**
 * @title DeployScript
 * @notice Sample deployment script for Mantle Hackathon contracts
 * @dev This script demonstrates how to deploy contracts using Foundry
 */
contract DeployCcipReceiveSend is Script {
    // Deployment addresses
    address public deployer;
    address public router;
    address public link;
    uint64 public destinationChainSelector;

    function setUp() public {
        deployer = vm.envAddress("DEV2_ADDRESS");
        console.log("Deployer address:", deployer);

        if (block.chainid != 11155111) {
            revert("This is not the Mainnet Sepolia");
        }

        router = vm.envAddress("ROUTER_11155111");
        link = vm.envAddress("LINK_11155111");
        destinationChainSelector = uint64(vm.envUint("CHAIN_SELECTOR_5003"));
    }

    function run() public returns (address ccipReceiveSendAddress) {
        // Load private key for deployment      
        console.log("Starting deployment...");        
        vm.startBroadcast();

        CCIPReceiveSend ccipReceiveSend = new CCIPReceiveSend(router, link, destinationChainSelector);
        ccipReceiveSendAddress = address(ccipReceiveSend);

        vm.stopBroadcast();

        // Log deployment results
        console.log("=== Deployment Results ===");
        console.log("CCIPReceiveSend deployed to:", ccipReceiveSendAddress);
    }
} 