// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Client} from "@chainlink/contracts-ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/applications/CCIPReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {OwnerIsCreator} from "@chainlink/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/// @title - A contract for sending an address to another chain and receiving an answer back.
contract CCIPSendReceive is CCIPReceiver, OwnerIsCreator {
    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error InvalidResponseSender(address expectedSender, address actualSender);
    error NoPendingRequest(bytes32 messageId);

    // Event emitted when an address is sent to another chain.
    event AddressSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address sentAddress, // The address being sent.
        address feeToken, // The token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the CCIP message.
    );

    // Event emitted when an answer is received from another chain.
    event AnswerReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        address returnedAddress // The address that was returned in the answer.
    );

    // Link Token interface for fee payments
    LinkTokenInterface private s_linkToken;

    // Mapping to track pending requests: messageId => (destinationChainSelector, receiver, sentAddress)
    mapping(bytes32 => PendingRequest) private s_pendingRequests;



    // Store the last received answer details
    bytes32 private s_lastReceivedMessageId;
    address private s_lastReturnedAddress;
    uint64 private s_lastSourceChainSelector;
    address private s_lastSender;
    bool private s_lastResponseValid;
    uint64 private s_destinationChainSelector; 

    // Structure to store pending request details
    struct PendingRequest {
        uint64 destinationChainSelector;
        address receiver;
        address sentAddress;
        bool exists;
    }

    /// @notice Constructor initializes the contract with the router and link token addresses.
    /// @param router The address of the router contract.
    /// @param link The address of the link contract.
    constructor(address router, address link, uint64 destinationChainSelector) CCIPReceiver(router) {
        s_destinationChainSelector = destinationChainSelector;
        s_linkToken = LinkTokenInterface(link);
    }

    /// @notice Send an address to a receiver on another chain
    /// @param receiver The address of the recipient on the destination blockchain
    /// @param addressToSend The address to send
    /// @return messageId The ID of the message that was sent
    function sendAddress(
        address receiver,
        address addressToSend
    ) external onlyOwner returns (bytes32 messageId) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: abi.encode(addressToSend), // ABI-encoded address
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and allowing out-of-order execution
                Client.GenericExtraArgsV2({
                    gasLimit: 200_000, // Gas limit for the callback on the destination chain
                    allowOutOfOrderExecution: true // Allows the message to be executed out of order relative to other messages from the same sender
                })
            ),
            // Set the feeToken address, indicating LINK will be used for fees
            feeToken: address(s_linkToken)
        });

        // Get the fee required to send the message
        uint256 fees = IRouterClient(getRouter()).getFee(
            s_destinationChainSelector,
            evm2AnyMessage
        );

        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

        // Approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        s_linkToken.approve(getRouter(), fees);

        // Send the message through the router and store the returned message ID
        messageId = IRouterClient(getRouter()).ccipSend(s_destinationChainSelector, evm2AnyMessage);

        // Store the pending request details for validation when we receive the answer
        s_pendingRequests[messageId] = PendingRequest({
            destinationChainSelector: s_destinationChainSelector,
            receiver: receiver,
            sentAddress: addressToSend,
            exists: true
        });

        // Emit an event with message details
        emit AddressSent(
            messageId,
            s_destinationChainSelector,
            receiver,
            addressToSend,
            address(s_linkToken),
            fees
        );

        return messageId;
    }

    /// @notice Handle a received message from another chain (the answer)
    /// @param any2EvmMessage The message received from the source chain
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        // Decode the returned address from the answer
        address returnedAddress = abi.decode(any2EvmMessage.data, (address));
        
        // Get the sender address
        address sender = abi.decode(any2EvmMessage.sender, (address));
        
        // Store the message details
        s_lastReceivedMessageId = any2EvmMessage.messageId;
        s_lastReturnedAddress = returnedAddress;
        s_lastSourceChainSelector = any2EvmMessage.sourceChainSelector;
        s_lastSender = sender;

        // Try to find a pending request that matches this response
        // We'll check if this sender was one of our recent receivers
        // bool isValidResponse = false;
        // address originalAddress = address(0);

        // For simplicity, we'll check if the sender matches any of our pending requests
        // In a more sophisticated implementation, you might want to include the original messageId
        // in the response data to make this validation more precise
        // for (uint256 i = 0; i < 100; i++) { // Limit search to prevent infinite loops
        //     // This is a simplified approach - in practice you might want to include
        //     // the original messageId in the response for exact matching
        //     if (s_pendingRequests[any2EvmMessage.messageId].exists) {
        //         PendingRequest memory request = s_pendingRequests[any2EvmMessage.messageId];
        //         if (request.receiver == sender) {
        //             isValidResponse = true;
        //             originalAddress = request.sentAddress;
        //             // Clean up the pending request
        //             delete s_pendingRequests[any2EvmMessage.messageId];
        //             break;
        //         }
        //     }
        // }

        // If we couldn't find a matching pending request, we'll still accept the response
        // but mark it as potentially invalid
        // if (!isValidResponse) {
            // In a production environment, you might want to be more strict here
            // and revert if the response doesn't come from an expected sender
            // revert InvalidResponseSender(expectedSender, sender);
        // }

        // s_lastResponseValid = isValidResponse;

        // Emit event with received answer details
        emit AnswerReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            sender,
            returnedAddress
        );
    }

    /// @notice Get the fee required to send an address to another chain
    /// @param receiver The address of the recipient on the destination blockchain
    /// @param addressToSend The address to send
    /// @return fees The fees required to send the message
    function getFee(
        address receiver,
        address addressToSend
    ) external view returns (uint256 fees) {
        // Create an EVM2AnyMessage struct in memory
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(addressToSend),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({
                    gasLimit: 200_000,
                    allowOutOfOrderExecution: true
                })
            ),
            feeToken: address(s_linkToken)
        });

        // Get the fee required to send the message
        return IRouterClient(getRouter()).getFee(s_destinationChainSelector, evm2AnyMessage);
    }

    /// @notice Fetches the details of the last received answer
    /// @return messageId The ID of the last received message
    /// @return returnedAddress The last returned address
    /// @return sourceChainSelector The source chain selector
    /// @return sender The sender address
    /// @return isValidResponse Whether the response was from an expected sender
    function getLastReceivedAnswerDetails()
        external
        view
        returns (
            bytes32 messageId,
            address returnedAddress,
            uint64 sourceChainSelector,
            address sender,
            bool isValidResponse
        )
    {
        return (
            s_lastReceivedMessageId,
            s_lastReturnedAddress,
            s_lastSourceChainSelector,
            s_lastSender,
            s_lastResponseValid
        );
    }

    /// @notice Check if a messageId has a pending request
    /// @param messageId The message ID to check
    /// @return exists Whether there's a pending request for this messageId
    /// @return destinationChainSelector The destination chain selector
    /// @return receiver The receiver address
    /// @return sentAddress The address that was sent
    function getPendingRequest(bytes32 messageId)
        external
        view
        returns (
            bool exists,
            uint64 destinationChainSelector,
            address receiver,
            address sentAddress
        )
    {
        PendingRequest memory request = s_pendingRequests[messageId];
        return (
            request.exists,
            request.destinationChainSelector,
            request.receiver,
            request.sentAddress
        );
    }

    /// @notice Clear a pending request (useful for cleanup)
    /// @param messageId The message ID to clear
    function clearPendingRequest(bytes32 messageId) external onlyOwner {
        if (!s_pendingRequests[messageId].exists) {
            revert NoPendingRequest(messageId);
        }
        delete s_pendingRequests[messageId];
    }

    /// @notice Allow the owner to withdraw LINK tokens from the contract
    function withdrawLink() external onlyOwner {
        require(
            s_linkToken.transfer(msg.sender, s_linkToken.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /// @notice Get the current LINK balance of the contract
    /// @return balance The current LINK balance
    function getLinkBalance() external view returns (uint256 balance) {
        return s_linkToken.balanceOf(address(this));
    }
}
