// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @title Deploy script Governance 
/// @notice Governance is a simple example of a DAO. It acts as an introductory example of the Powers protocol. 
/// 
/// @author 7Cedars

pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
// import { console2 } from "forge-std/console2.sol";

// core protocol
import { Powers } from "@powers/Powers.sol";
import { IPowers } from "@powers/interfaces/IPowers.sol";
import { ILaw } from "@powers/interfaces/ILaw.sol";
import { PowersTypes } from "@powers/interfaces/PowersTypes.sol";


/// @notice core script to deploy a dao
/// Note the {run} function for deploying the dao can be used without changes.
/// Note  the {initiateConstitution} function for creating bespoke constitution for the DAO.
/// Note the {getFounders} function for setting founders' roles.
contract DeployGovernance is Script {
    uint256 blocksPerHour;
    address addressAnalysis;

    function run() external returns (address payable powers_) {
        addressAnalysis = 0x37ebF5dC32e3e851B8f7927a9B849d1Aa2c6C417; // for now all hardcoded. 

        // Deploy the DAO and a mock erc20 votes contract.
        vm.startBroadcast();
        Powers powers = new Powers(
            "Power to the User",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreieioptfopmddgpiowg6duuzsd4n6koibutthev72dnmweczjybs4q" //  Adapt later. -- should fit with general UI. 
        );
        vm.stopBroadcast();

        powers_ = payable(address(powers));

        // // Create the constitution.
        PowersTypes.LawInitData[] memory lawInitData = createConstitution(powers_);

        // constitute dao.
        vm.startBroadcast();
        powers.constitute(lawInitData);
        vm.stopBroadcast();

        return (powers_);
    }

    function createConstitution(
        address payable powers_
    ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](2);
        
        //////////////////////////////////////////////////////////////////
        //                       Electoral laws                         // 
        //////////////////////////////////////////////////////////////////
        // This law uses an AI to assign roles to different types of users. 
        // User receive executive powers according to their role.
        // anyone can call the role. It is throttled to avoid over use of the api and bridges.  
        conditions.allowedRole = type(uint256).max; // public role  
        conditions.throttleExecution = minutesToBlocks(1); // this law can be called once every minute. 
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "AI role assignment: Let an AI assess your on-chain activity and assign you a role accordingly.",
            targetLaw: addressAnalysis,
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        //////////////////////////////////////////////////////////////////
        //                       Executive laws                         // 
        //////////////////////////////////////////////////////////////////


       
    }

    //////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        // 
    //////////////////////////////////////////////////////////////

    function minutesToBlocks(uint256 min) public view returns (uint32 blocks) {
        blocks = uint32(min * 360_000 / 60);
    }
} 