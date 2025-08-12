// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Test, console} from "forge-std/Test.sol";
import {CCIPSendReceive} from "../../src/CCIPSendReceive.sol";
import {Client} from "@chainlink/contracts-ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

/**
 * @title MockRouterClient
 * @notice Mock router client for testing CCIP functionality
 */
contract MockRouterClient {
    uint256 public mockFee = 0.1 ether; // 0.1 LINK
    bytes32 public mockMessageId = keccak256("mock_message_id");
    
    function getFee(uint64, Client.EVM2AnyMessage memory) external view returns (uint256) {
        return mockFee;
    }
    
    function ccipSend(uint64, Client.EVM2AnyMessage memory) external returns (bytes32) {
        return mockMessageId;
    }
    
    function setMockFee(uint256 _fee) external {
        mockFee = _fee;
    }
    
    function setMockMessageId(bytes32 _messageId) external {
        mockMessageId = _messageId;
    }
}

/**
 * @title TestCCIPSendReceive
 * @notice Test helper contract that can access internal functions
 */
contract TestCCIPSendReceive is CCIPSendReceive {
    constructor(
        address router,
        address link,
        uint64 destinationChainSelector
    ) CCIPSendReceive(router, link, destinationChainSelector) {}
    
    // Expose the internal _ccipReceive function for testing
    function testCcipReceive(Client.Any2EVMMessage memory message) external {
        _ccipReceive(message);
    }
}

/**
 * @title MockLinkToken
 * @notice Mock LINK token for testing
 */
contract MockLinkToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() {
        // Give initial balance to deployer
        balanceOf[msg.sender] = 1000 ether;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }
}

/**
 * @title CCIPSendReceiveTest
 * @notice Comprehensive unit tests for CCIPSendReceive contract
 */
contract CCIPSendReceiveTest is Test {
    // Test contracts
    TestCCIPSendReceive public ccipContract;
    MockRouterClient public mockRouter;
    MockLinkToken public mockLinkToken;
    
    // Test addresses
    address public owner = makeAddr("owner");
    address public receiver = makeAddr("receiver");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    
    // Test constants
    uint64 public constant DESTINATION_CHAIN_SELECTOR = 16015286601757825753; // Sepolia
    uint64 public constant SOURCE_CHAIN_SELECTOR = 12532609583862916517; // Mumbai
    uint256 public constant INITIAL_LINK_BALANCE = 10 ether;
    
    // Test addresses to send
    address public testAddress1 = makeAddr("test_address_1");
    address public testAddress2 = makeAddr("test_address_2");

    function setUp() public {
        // Deploy mock contracts
        mockRouter = new MockRouterClient();
        mockLinkToken = new MockLinkToken();
        
        // Deploy TestCCIPSendReceive contract
        vm.prank(owner);
        ccipContract = new TestCCIPSendReceive(
            address(mockRouter),
            address(mockLinkToken),
            DESTINATION_CHAIN_SELECTOR
        );
        
        // Fund the contract with LINK tokens
        mockLinkToken.mint(address(ccipContract), INITIAL_LINK_BALANCE);
        
        // Label addresses for better trace output
        vm.label(address(ccipContract), "CCIPSendReceive");
        vm.label(address(mockRouter), "MockRouter");
        vm.label(address(mockLinkToken), "MockLinkToken");
        vm.label(owner, "Owner");
        vm.label(receiver, "Receiver");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(testAddress1, "TestAddress1");
        vm.label(testAddress2, "TestAddress2");
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsCorrectValues() public {
        assertEq(ccipContract.owner(), owner, "Owner should be set correctly");
        assertEq(ccipContract.getRouter(), address(mockRouter), "Router should be set correctly");
        assertEq(ccipContract.getLinkBalance(), INITIAL_LINK_BALANCE, "Initial LINK balance should be correct");
    }

    // ============ sendAddress Tests ============

    function test_SendAddress_Success() public {
        vm.startPrank(owner);
        
        bytes32 messageId = ccipContract.sendAddress(receiver, testAddress1);
        
        // Verify the message was sent
        assertEq(messageId, mockRouter.mockMessageId(), "Message ID should match");
        
        // Verify pending request was stored
        (bool exists, uint64 destChain, address recv, address sentAddr) = ccipContract.getPendingRequest(messageId);
        assertTrue(exists, "Pending request should exist");
        assertEq(destChain, DESTINATION_CHAIN_SELECTOR, "Destination chain should match");
        assertEq(recv, receiver, "Receiver should match");
        assertEq(sentAddr, testAddress1, "Sent address should match");
        
        vm.stopPrank();
    }

    function test_SendAddress_RevertsIfNotOwner() public {
        vm.prank(alice);
        
        vm.expectRevert("Only callable by owner");
        ccipContract.sendAddress(receiver, testAddress1);
    }

    function test_SendAddress_RevertsIfInsufficientBalance() public {
        // Set a very high fee
        mockRouter.setMockFee(1000 ether);
        
        vm.prank(owner);
        
        vm.expectRevert(abi.encodeWithSelector(
            CCIPSendReceive.NotEnoughBalance.selector,
            INITIAL_LINK_BALANCE,
            1000 ether
        ));
        ccipContract.sendAddress(receiver, testAddress1);
    }

    function test_SendAddress_EmitsAddressSentEvent() public {
        vm.startPrank(owner);
        
        vm.expectEmit(true, true, false, true);
        emit CCIPSendReceive.AddressSent(
            mockRouter.mockMessageId(),
            DESTINATION_CHAIN_SELECTOR,
            receiver,
            testAddress1,
            address(mockLinkToken),
            mockRouter.mockFee()
        );
        
        ccipContract.sendAddress(receiver, testAddress1);
        
        vm.stopPrank();
    }

    // ============ testCcipReceive Tests ============

    function test_TestCcipReceive_Success() public {
        // First send an address to create a pending request
        vm.prank(owner);
        bytes32 messageId = ccipContract.sendAddress(receiver, testAddress1);
        
        // Create a mock response message
        Client.Any2EVMMessage memory responseMessage = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(receiver),
            data: abi.encode(testAddress2),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        // Simulate receiving the response
        ccipContract.testCcipReceive(responseMessage);
        
        // Verify the response details were stored
        (
            bytes32 storedMessageId,
            address returnedAddress,
            uint64 sourceChain,
            address sender,
            bool isValidResponse
        ) = ccipContract.getLastReceivedAnswerDetails();
        
        assertEq(storedMessageId, messageId, "Message ID should match");
        assertEq(returnedAddress, testAddress2, "Returned address should match");
        assertEq(sourceChain, SOURCE_CHAIN_SELECTOR, "Source chain should match");
        assertEq(sender, receiver, "Sender should match");
        assertTrue(isValidResponse, "Response should be valid");
        
        // Verify pending request was cleaned up
        (bool existsAfter,,,) = ccipContract.getPendingRequest(messageId);
        assertFalse(existsAfter, "Pending request should be cleaned up");
    }

    function test_TestCcipReceive_EmitsAnswerReceivedEvent() public {
        // First send an address to create a pending request
        vm.prank(owner);
        bytes32 messageId = ccipContract.sendAddress(receiver, testAddress1);
        
        // Create a mock response message
        Client.Any2EVMMessage memory responseMessage = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(receiver),
            data: abi.encode(testAddress2),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        // Expect the event to be emitted
        vm.expectEmit(true, true, false, true);
        emit CCIPSendReceive.AnswerReceived(
            messageId,
            SOURCE_CHAIN_SELECTOR,
            receiver,
            testAddress1,
            testAddress2,
            true
        );
        
        // Simulate receiving the response
        ccipContract.testCcipReceive(responseMessage);
    }

    function test_TestCcipReceive_HandlesInvalidResponse() public {
        // Create a response message without a corresponding pending request
        Client.Any2EVMMessage memory responseMessage = Client.Any2EVMMessage({
            messageId: keccak256("invalid_message"),
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(alice),
            data: abi.encode(testAddress2),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        // This should not revert but mark the response as invalid
        ccipContract.testCcipReceive(responseMessage);
        
        // Verify the response details were stored but marked as invalid
        (,,,, bool isValidResponse) = ccipContract.getLastReceivedAnswerDetails();
        assertFalse(isValidResponse, "Response should be marked as invalid");
    }

    // ============ getFee Tests ============

    function test_GetFee_ReturnsCorrectFee() public {
        uint256 fee = ccipContract.getFee(DESTINATION_CHAIN_SELECTOR, receiver, testAddress1);
        assertEq(fee, mockRouter.mockFee(), "Fee should match router's fee");
    }

    function test_GetFee_WorksWithDifferentParameters() public {
        uint256 fee1 = ccipContract.getFee(DESTINATION_CHAIN_SELECTOR, alice, testAddress1);
        uint256 fee2 = ccipContract.getFee(DESTINATION_CHAIN_SELECTOR, bob, testAddress2);
        
        assertEq(fee1, mockRouter.mockFee(), "Fee should be consistent");
        assertEq(fee2, mockRouter.mockFee(), "Fee should be consistent");
    }

    // ============ getLastReceivedAnswerDetails Tests ============

    function test_GetLastReceivedAnswerDetails_ReturnsDefaultValues() public {
        (
            bytes32 messageId,
            address returnedAddress,
            uint64 sourceChain,
            address sender,
            bool isValidResponse
        ) = ccipContract.getLastReceivedAnswerDetails();
        
        assertEq(messageId, bytes32(0), "Message ID should be default");
        assertEq(returnedAddress, address(0), "Returned address should be default");
        assertEq(sourceChain, 0, "Source chain should be default");
        assertEq(sender, address(0), "Sender should be default");
        assertFalse(isValidResponse, "Valid response should be default");
    }

    // ============ getPendingRequest Tests ============

    function test_GetPendingRequest_ReturnsCorrectValues() public {
        vm.prank(owner);
        bytes32 messageId = ccipContract.sendAddress(receiver, testAddress1);
        
        (bool exists, uint64 destChain, address recv, address sentAddr) = ccipContract.getPendingRequest(messageId);
        
        assertTrue(exists, "Request should exist");
        assertEq(destChain, DESTINATION_CHAIN_SELECTOR, "Destination chain should match");
        assertEq(recv, receiver, "Receiver should match");
        assertEq(sentAddr, testAddress1, "Sent address should match");
    }

    function test_GetPendingRequest_ReturnsFalseForNonExistentRequest() public {
        bytes32 nonExistentMessageId = keccak256("non_existent");
        
        (bool exists,,,) = ccipContract.getPendingRequest(nonExistentMessageId);
        assertFalse(exists, "Request should not exist");
    }

    // ============ clearPendingRequest Tests ============

    function test_ClearPendingRequest_Success() public {
        vm.startPrank(owner);
        
        // First create a pending request
        bytes32 messageId = ccipContract.sendAddress(receiver, testAddress1);
        
        // Verify it exists
        (bool exists,,,) = ccipContract.getPendingRequest(messageId);
        assertTrue(exists, "Request should exist before clearing");
        
        // Clear the request
        ccipContract.clearPendingRequest(messageId);
        
        // Verify it was cleared
        (bool existsAfter,,,) = ccipContract.getPendingRequest(messageId);
        assertFalse(existsAfter, "Request should not exist after clearing");
        
        vm.stopPrank();
    }

    function test_ClearPendingRequest_RevertsIfNotOwner() public {
        vm.prank(alice);
        
        vm.expectRevert("Only callable by owner");
        ccipContract.clearPendingRequest(keccak256("test"));
    }

    function test_ClearPendingRequest_RevertsIfRequestDoesNotExist() public {
        vm.prank(owner);
        
        vm.expectRevert(abi.encodeWithSelector(
            CCIPSendReceive.NoPendingRequest.selector,
            keccak256("non_existent")
        ));
        ccipContract.clearPendingRequest(keccak256("non_existent"));
    }

    // ============ withdrawLink Tests ============

    function test_WithdrawLink_Success() public {
        uint256 initialOwnerBalance = mockLinkToken.balanceOf(owner);
        uint256 contractBalance = ccipContract.getLinkBalance();
        
        vm.prank(owner);
        ccipContract.withdrawLink();
        
        // Verify LINK was transferred to owner
        assertEq(mockLinkToken.balanceOf(owner), initialOwnerBalance + contractBalance, "Owner should receive LINK");
        assertEq(ccipContract.getLinkBalance(), 0, "Contract should have 0 LINK balance");
    }

    function test_WithdrawLink_RevertsIfNotOwner() public {
        vm.prank(alice);
        
        vm.expectRevert("Only callable by owner");
        ccipContract.withdrawLink();
    }

    // ============ getLinkBalance Tests ============

    function test_GetLinkBalance_ReturnsCorrectBalance() public {
        uint256 balance = ccipContract.getLinkBalance();
        assertEq(balance, INITIAL_LINK_BALANCE, "Balance should match initial amount");
    }

    // ============ Integration Tests ============

    function test_CompleteWorkflow_SendAndReceive() public {
        // Step 1: Send address
        vm.startPrank(owner);
        bytes32 messageId = ccipContract.sendAddress(receiver, testAddress1);
        
        // Verify pending request
        (bool exists,,,) = ccipContract.getPendingRequest(messageId);
        assertTrue(exists, "Pending request should exist");
        
        // Step 2: Simulate receiving response
        Client.Any2EVMMessage memory responseMessage = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(receiver),
            data: abi.encode(testAddress2),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        ccipContract.testCcipReceive(responseMessage);
        
        // Step 3: Verify response details
        (
            bytes32 storedMessageId,
            address returnedAddress,
            uint64 sourceChain,
            address sender,
            bool isValidResponse
        ) = ccipContract.getLastReceivedAnswerDetails();
        
        assertEq(storedMessageId, messageId, "Message ID should match");
        assertEq(returnedAddress, testAddress2, "Returned address should match");
        assertTrue(isValidResponse, "Response should be valid");
        
        // Step 4: Verify pending request was cleaned up
        (bool existsAfter,,,) = ccipContract.getPendingRequest(messageId);
        assertFalse(existsAfter, "Pending request should be cleaned up");
        
        vm.stopPrank();
    }

    // ============ Edge Cases and Fuzz Tests ============

    function testFuzz_SendAddress_WithDifferentAddresses(address randomAddress) public {
        vm.assume(randomAddress != address(0));
        
        vm.prank(owner);
        bytes32 messageId = ccipContract.sendAddress(receiver, randomAddress);
        
        // Verify the address was stored correctly
        (,,, address sentAddr) = ccipContract.getPendingRequest(messageId);
        assertEq(sentAddr, randomAddress, "Sent address should match");
    }

    function testFuzz_SendAddress_WithDifferentReceivers(address randomReceiver) public {
        vm.assume(randomReceiver != address(0));
        
        vm.prank(owner);
        bytes32 messageId = ccipContract.sendAddress(randomReceiver, testAddress1);
        
        // Verify the receiver was stored correctly
        (,, address recv,) = ccipContract.getPendingRequest(messageId);
        assertEq(recv, randomReceiver, "Receiver should match");
    }

    // ============ Gas Optimization Tests ============

    function test_GasUsage_SendAddress() public {
        vm.startPrank(owner);
        
        uint256 gasBefore = gasleft();
        ccipContract.sendAddress(receiver, testAddress1);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for sendAddress:", gasUsed);
        
        // This is just for monitoring, no assertions needed
        vm.stopPrank();
    }

    function test_GasUsage_TestCcipReceive() public {
        // First send an address
        vm.prank(owner);
        bytes32 messageId = ccipContract.sendAddress(receiver, testAddress1);
        
        // Create response message
        Client.Any2EVMMessage memory responseMessage = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(receiver),
            data: abi.encode(testAddress2),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        // Measure gas usage
        uint256 gasBefore = gasleft();
        ccipContract.testCcipReceive(responseMessage);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for testCcipReceive:", gasUsed);
        
        // This is just for monitoring, no assertions needed
    }
}
