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

/// @title - A contract for receiving an address from another chain and sending it back.
contract CCIPReceiveSend is CCIPReceiver, OwnerIsCreator {
    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);

    // Event emitted when an address is received from another chain.
    event AddressReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        address receivedAddress // The address that was received.
    );

    // Event emitted when an address is sent to another chain.
    event AddressSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address sentAddress, // The address being sent.
        address feeToken, // The token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the CCIP message.
    );

    // Link Token interface for fee payments
    LinkTokenInterface private s_linkToken;

    // Store the last received address and message details
    bytes32 private s_lastReceivedMessageId;
    address private s_lastReceivedAddress;
    uint64 private s_lastSourceChainSelector;
    address private s_lastSender;
    uint64 private s_destinationChainSelector; 

    /// @notice Constructor initializes the contract with the router and link token addresses.
    /// @param router The address of the router contract.
    /// @param link The address of the link contract.
    constructor(address router, address link, uint64 destinationChainSelector) CCIPReceiver(router) {
        s_destinationChainSelector = destinationChainSelector;
        s_linkToken = LinkTokenInterface(link);
    }

    /// @notice Handle a received message from another chain
    /// @param any2EvmMessage The message received from the source chain
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        // Decode the received address
        address receivedAddress = abi.decode(any2EvmMessage.data, (address));
        
        // Store the message details
        s_lastReceivedMessageId = any2EvmMessage.messageId;
        s_lastReceivedAddress = receivedAddress;
        s_lastSourceChainSelector = any2EvmMessage.sourceChainSelector;
        s_lastSender = abi.decode(any2EvmMessage.sender, (address));

        // Emit event with received address details
        emit AddressReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            s_lastSender,
            receivedAddress
        );

        // Automatically send the address back to the sender on the source chain
        _sendAddressBack(s_lastSender, receivedAddress);
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

    /// @notice Internal function to send address back to the sender
    /// @param receiver The address to send back to (original sender)
    /// @param addressToSend The address to send back
    function _sendAddressBack(
        address receiver,
        address addressToSend
    ) internal {
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
        uint256 fees = IRouterClient(getRouter()).getFee(
            s_destinationChainSelector,
            evm2AnyMessage
        );

        // Check if we have enough balance to send the message back
        if (fees <= s_linkToken.balanceOf(address(this))) {
            // Approve the Router to transfer LINK tokens
            s_linkToken.approve(getRouter(), fees);

            // Send the message back
            bytes32 messageId = IRouterClient(getRouter()).ccipSend(s_destinationChainSelector, evm2AnyMessage);

            // Emit event for the return message
            emit AddressSent(
                messageId,
                s_destinationChainSelector,
                receiver,
                addressToSend,
                address(s_linkToken),
                fees
            );
        }
        // If not enough balance, the message won't be sent back
        // In a production environment, you might want to handle this differently
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

    /// @notice Fetches the details of the last received message
    /// @return messageId The ID of the last received message
    /// @return receivedAddress The last received address
    /// @return sourceChainSelector The source chain selector
    /// @return sender The sender address
    function getLastReceivedMessageDetails()
        external
        view
        returns (
            bytes32 messageId,
            address receivedAddress,
            uint64 sourceChainSelector,
            address sender
        )
    {
        return (
            s_lastReceivedMessageId,
            s_lastReceivedAddress,
            s_lastSourceChainSelector,
            s_lastSender
        );
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
