// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Client} from "@chainlink/contracts-ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/applications/CCIPReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";
import {Chainlink, ChainlinkClient} from "@chainlink/contracts/src/v0.8/operatorforwarder/ChainlinkClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

/**
 * AI CCIP Proxy Contract
 * This contract combines CCIP cross-chain messaging with AI address analysis
 * 
 * Flow:
 * 1. Receive address via CCIP from another chain
 * 2. Send address to AI for analysis via Chainlink
 * 3. Receive AI analysis results
 * 4. Send analysis results back to original sender via CCIP
 * 
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract AiCCIPProxy is CCIPReceiver, ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    // Custom errors
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);

    // Chainlink AI Analysis constants
    uint256 private constant ORACLE_PAYMENT = (1 * LINK_DIVISIBILITY) / 10; // 0.1 * 10**18
    bytes32 private jobId;
    string private apiUrl;

    // CCIP constants
    LinkTokenInterface private s_linkToken;
    uint64 private s_destinationChainSelector;

    // Structure to store AI analysis results
    struct AddressAnalysis {
        uint256 category;
        string explanation;
    }

    // Mapping to store analysis results by address
    mapping(address => AddressAnalysis) public addressAnalyses;
    
    // Mapping to track pending AI requests with CCIP context
    mapping(bytes32 => PendingRequest) public pendingRequests;

    // Structure to store pending request context
    struct PendingRequest {
        address targetAddress;
        address originalSender;
        uint64 sourceChainSelector;
        bytes32 ccipMessageId;
    }

    // Events
    event AddressReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        address receivedAddress
    );

    event AddressAnalysisRequested(
        bytes32 indexed requestId,
        address indexed targetAddress,
        address originalSender,
        uint64 sourceChainSelector
    );

    event AddressAnalysisFulfilled(
        bytes32 indexed requestId,
        address indexed targetAddress,
        uint256 category,
        string explanation
    );

    event ReplySent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        uint256 category,
        string explanation,
        address feeToken,
        uint256 fees
    );

    /**
     * @notice Constructor initializes the contract with router, link token, and oracle addresses
     * @param router The address of the CCIP router contract
     * @param destinationChainSelector The destination chain selector for replies
     * @param owner_ The owner of the contract
     */
    constructor(
        address router, 
        address link,
        address oracle,
        uint64 destinationChainSelector,
        address owner_
    ) CCIPReceiver(router) ConfirmedOwner(owner_) {
        s_destinationChainSelector = destinationChainSelector;
        s_linkToken = LinkTokenInterface(link);
        
        // Set up Chainlink
        _setChainlinkToken(link);
        _setChainlinkOracle(oracle);
        jobId = "582d4373649642e0994ab29295c45db0";
        apiUrl = "https://ai-leviathan.vercel.app/api/address-analysis?address=";
    }

    /**
     * @notice Handle a received message from another chain
     * @param any2EvmMessage The message received from the source chain
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        // Decode the received address
        address receivedAddress = abi.decode(any2EvmMessage.data, (address));
        address sender = abi.decode(any2EvmMessage.sender, (address));
        
        // Emit event with received address details
        emit AddressReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            sender,
            receivedAddress
        );

        // Request AI analysis of the received address
        _requestAddressAnalysis(receivedAddress, sender, any2EvmMessage.sourceChainSelector, any2EvmMessage.messageId);
    }

    /**
     * @notice Internal function to request AI analysis of an address
     * @param targetAddress The address to analyze
     * @param originalSender The original sender from CCIP
     * @param sourceChainSelector The source chain selector
     * @param ccipMessageId The original CCIP message ID
     */
    function _requestAddressAnalysis(
        address targetAddress,
        address originalSender,
        uint64 sourceChainSelector,
        bytes32 ccipMessageId
    ) internal {
        require(targetAddress != address(0), "Invalid address");
        
        Chainlink.Request memory req = _buildChainlinkRequest(
            jobId,
            address(this), 
            this.fulfillAddressAnalysis.selector
        );
        
        // Add the API URL and address as CBOR data
        req._add("apiUrl", string.concat(apiUrl, _addressToString(targetAddress)));
        
        // Store the pending request with CCIP context
        bytes32 requestId = _sendChainlinkRequest(req, ORACLE_PAYMENT);
        pendingRequests[requestId] = PendingRequest({
            targetAddress: targetAddress,
            originalSender: originalSender,
            sourceChainSelector: sourceChainSelector,
            ccipMessageId: ccipMessageId
        });
        
        emit AddressAnalysisRequested(requestId, targetAddress, originalSender, sourceChainSelector);
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
        PendingRequest memory pendingRequest = pendingRequests[requestId];
        require(pendingRequest.targetAddress != address(0), "Request not found");
        
        // Store the analysis result
        addressAnalyses[pendingRequest.targetAddress] = AddressAnalysis({
            category: category,
            explanation: explanation
        });
        
        // Send the analysis results back to the original sender
        _sendReplyBack(
            pendingRequest.originalSender,
            category,
            explanation
        );
        
        // Clear the pending request
        delete pendingRequests[requestId];
        
        emit AddressAnalysisFulfilled(
            requestId,
            pendingRequest.targetAddress,
            category,
            explanation
        );
    }

    /**
     * @notice Send analysis results to a receiver on another chain
     * @param receiver The address of the recipient on the destination blockchain
     * @param category The AI analysis category
     * @param explanation The AI analysis explanation
     * @return messageId The ID of the message that was sent
     */
    function sendReply(
        address receiver,
        uint256 category,
        string memory explanation
    ) external onlyOwner returns (bytes32 messageId) {
        return _sendReplyBack(receiver, category, explanation);
    }

    /**
     * @notice Internal function to send analysis results back to the original sender
     * @param receiver The address to send back to (original sender)
     * @param category The AI analysis category
     * @param explanation The AI analysis explanation
     * @return messageId The ID of the message that was sent
     */
    function _sendReplyBack(
        address receiver,
        uint256 category,
        string memory explanation
    ) internal returns (bytes32 messageId) {
        // Create an EVM2AnyMessage struct in memory
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(category, explanation), // Encode both category and explanation
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({
                    gasLimit: 2_000_000, // 2M gas limit. 
                    allowOutOfOrderExecution: true
                })
            ),
            feeToken: address(s_linkToken)
        });

        // Get the fee required to send the message
        uint256 fees = IRouterClient(getRouter()).getFee(
            s_destinationChainSelector,
            evm2AnyMessage
        );

        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

        // Approve the Router to transfer LINK tokens on contract's behalf
        s_linkToken.approve(getRouter(), fees);

        // Send the message through the router
        messageId = IRouterClient(getRouter()).ccipSend(s_destinationChainSelector, evm2AnyMessage);

        // Emit event for the reply message
        emit ReplySent(
            messageId,
            s_destinationChainSelector,
            receiver,
            category,
            explanation,
            address(s_linkToken),
            fees
        );

        return messageId;
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
     * @notice Get the fee required to send a reply to another chain
     * @param receiver The address of the recipient on the destination blockchain
     * @param category The AI analysis category
     * @param explanation The AI analysis explanation
     * @return fees The fees required to send the message
     */
    function getReplyFee(
        address receiver,
        uint256 category,
        string memory explanation
    ) external view returns (uint256 fees) {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(category, explanation),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({
                    gasLimit: 200_000,
                    allowOutOfOrderExecution: true
                })
            ),
            feeToken: address(s_linkToken)
        });

        return IRouterClient(getRouter()).getFee(s_destinationChainSelector, evm2AnyMessage);
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
     * @notice Update the destination chain selector
     * @param _destinationChainSelector The new destination chain selector
     */
    function setDestinationChainSelector(uint64 _destinationChainSelector) public onlyOwner {
        s_destinationChainSelector = _destinationChainSelector;
    }

    /**
     * @notice Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        require(
            s_linkToken.transfer(msg.sender, s_linkToken.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
     * @notice Get the current LINK balance of the contract
     * @return balance The current LINK balance
     */
    function getLinkBalance() external view returns (uint256 balance) {
        return s_linkToken.balanceOf(address(this));
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
