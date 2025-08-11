// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Chainlink, ChainlinkClient} from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

/**
 * AI Address Analysis Contract using Chainlink
 * This contract calls the Chainlink node to fetch AI analysis of Ethereum addresses
 * 
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract AiProxy is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = (1 * LINK_DIVISIBILITY) / 10; // 0.1 * 10**18
    bytes32 private jobId;
    uint256 private fee;
    string private apiUrl;

    // Structure to store AI analysis results
    struct AddressAnalysis {
        uint256 category;
        string explanation;
    }

    // Mapping to store analysis results by address
    mapping(address => AddressAnalysis) public addressAnalyses;
    
    // Mapping to track pending requests
    mapping(bytes32 => address) public pendingRequests;

    // Events
    event AddressAnalysisRequested(
        bytes32 indexed requestId,
        address indexed targetAddress
    );

    event AddressAnalysisFulfilled(
        bytes32 indexed requestId,
        address indexed targetAddress,
        uint256 category,
        string explanation
    );

    /**
     * @notice Initialize the link token and target oracle
     * @dev The oracle address must be an Operator contract for multiword response
     *
     * Sepolia Testnet details:
     * Link Token: 0x779877A7B0D9E8603169DdbD7836e478b4624789
     * Oracle: 0x8BA4C2A6569173942A93750Cc2a1022f70d6252E (Your Oracle)
     * jobId: Your job ID from the TOML definition
     *
     */
    constructor() ConfirmedOwner(msg.sender) {
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        _setChainlinkOracle(0x8BA4C2A6569173942A93750Cc2a1022f70d6252E);
        jobId = "YOUR_JOB_ID_HERE"; // Replace with your actual job ID
        apiUrl = "https://ai-leviathan.vercel.app/api/address-analysis?address=";
    }

    /**
     * @notice Request AI analysis of an Ethereum address
     * @param targetAddress The address to analyze
     */
    function requestAddressAnalysis(address targetAddress) public {
        require(targetAddress != address(0), "Invalid address");
        
        Chainlink.Request memory req = _buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillAddressAnalysis.selector
        );
        
        // Add the API URL and address as CBOR data
        req._add("apiUrl", apiUrl);
        req._add("address", _addressToString(targetAddress));
        
        // Store the pending request
        bytes32 requestId = _sendChainlinkRequest(req, ORACLE_PAYMENT);
        pendingRequests[requestId] = targetAddress;
        
        emit AddressAnalysisRequested(requestId, targetAddress);
    }

    /**
     * @notice Fulfillment function for address analysis
     * @dev This is called by the oracle. recordChainlinkFulfillment must be used.
     * @param requestId The request ID from the oracle
     * @param category The category number (1-N) that best fits the analyzed address
     * @param explanation Detailed explanation of why this address falls into the chosen category
     */
    function fulfillAddressAnalysis(
        bytes32 requestId,
        uint256 category,
        string memory explanation
    ) public recordChainlinkFulfillment(requestId) {
        address targetAddress = pendingRequests[requestId];
        require(targetAddress != address(0), "Request not found");
        
        // Store the analysis result
        addressAnalyses[targetAddress] = AddressAnalysis({
            category: category,
            explanation: explanation
        });
        
        // Clear the pending request
        delete pendingRequests[requestId];
        
        emit AddressAnalysisFulfilled(
            requestId,
            targetAddress,
            category,
            explanation
        );
    }

    /**
     * @notice Get the analysis result for a specific address
     * @param targetAddress The address to query
     * @return category The category number
     * @return explanation The explanation string
     */
    function getAddressAnalysis(address targetAddress) 
        public 
        view 
        returns (
            uint256 category,
            string memory explanation
        ) 
    {
        AddressAnalysis memory analysis = addressAnalyses[targetAddress];
        return (
            analysis.category,
            analysis.explanation
        );
    }

    /**
     * @notice Update the job ID
     * @param _jobId The new job ID
     */
    function setJobId(bytes32 _jobId) public onlyOwner {
        jobId = _jobId;
    }

    /**
     * @notice Update the oracle address
     * @param _oracle The new oracle address
     */
    function setOracle(address _oracle) public onlyOwner {
        _setChainlinkOracle(_oracle);
    }

    /**
     * @notice Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(_chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
     * @notice Convert address to string
     * @param addr The address to convert
     * @return The address as a string
     */
    function _addressToString(address addr) internal pure returns (string memory) {
        return _toHexString(uint256(uint160(addr)), 20);
    }

    /**
     * @notice Convert uint256 to hex string
     * @param value The value to convert
     * @param length The length of the hex string
     * @return The hex string
     */
    function _toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    // Hex symbols for address conversion
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
}
