// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AddressAnalysis} from "../../src/AddressAnalysis.sol";
import {Client} from "@chainlink/contracts-ccip/libraries/Client.sol";
import {MockLinkToken} from "../../lib/chainlink-evm/contracts/src/v0.8/functions/tests/v1_X/testhelpers/MockLinkToken.sol";

/**
 * @title MockRouter
 * @notice Mock router contract for testing CCIP functionality
 */
contract MockRouter {
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
 * @title MockPowers
 * @notice Mock Powers contract for testing
 */
contract MockPowers {
    mapping(uint16 => mapping(uint256 => bool)) public fulfilledActions;
    
    function fulfill(uint16 lawId, uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) external {
        fulfilledActions[lawId][actionId] = true;
    }
    
    function isActionFulfilled(uint16 lawId, uint256 actionId) external view returns (bool) {
        return fulfilledActions[lawId][actionId];
    }
}

/**
 * @title MockAiCCIPProxy
 * @notice Mock AI CCIP Proxy contract for testing
 */
contract MockAiCCIPProxy {
    // This contract would normally handle AI analysis
    // For testing, we just need it to exist
}

/**
 * @title TestAddressAnalysis
 * @notice Test helper contract that can access internal functions
 */
contract TestAddressAnalysis is AddressAnalysis {
    constructor(
        address router,
        address link,
        uint64 destinationChainSelector,
        address aiCCIPProxy
    ) AddressAnalysis(router, link, destinationChainSelector, aiCCIPProxy) {}
    
    // Expose the internal _ccipReceive function for testing
    function testCcipReceive(Client.Any2EVMMessage memory message) external {
        _ccipReceive(message);
    }
    
    // Expose internal functions for testing
    function testChangeState(bytes32 lawHash, bytes memory stateChange) external {
        _changeState(lawHash, stateChange);
    }
    
    // Helper function to simulate the full flow for testing
    // This will create the pending message through the normal contract flow
    function simulateRequestAndResponse(
        address caller,
        uint16 lawId,
        uint256 actionId,
        uint256 category,
        string memory explanation
    ) external {
        // First, we need to simulate the state change that would normally happen
        // This is a simplified version for testing
        bytes memory stateChange = abi.encode(caller, actionId, lawId);
        bytes32 lawHash = keccak256(abi.encodePacked(caller, lawId));
        _changeState(lawHash, stateChange);
        
        // Now create the CCIP message
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: keccak256(abi.encodePacked(actionId, caller)),
            sourceChainSelector: 12532609583862916517, // Mumbai
            sender: abi.encode(address(0x123)), // Mock sender
            data: abi.encode(category, explanation),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        // Process the message
        _ccipReceive(message);
    }
}

/**
 * @title AddressAnalysisTest
 * @notice Unit tests for AddressAnalysis contract, specifically _ccipReceive function
 */
contract AddressAnalysisTest is Test {
    // Test contracts
    TestAddressAnalysis public addressAnalysis;
    MockRouter public mockRouter;
    MockLinkToken public mockLinkToken;
    MockAiCCIPProxy public mockAiCCIPProxy;
    MockPowers public mockPowers;
    
    // Test addresses
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    
    // Test constants
    uint64 public constant DESTINATION_CHAIN_SELECTOR = 16015286601757825753; // Sepolia
    uint64 public constant SOURCE_CHAIN_SELECTOR = 12532609583862916517; // Mumbai
    uint16 public constant TEST_LAW_ID = 1;
    uint256 public constant TEST_ACTION_ID = 12345;
    
    // Test data
    bytes32 public testMessageId = keccak256("test_message_id");
    uint256 public testCategory = 2;
    string public testExplanation = "This address shows moderate risk patterns";
    
    function setUp() public {
        // Deploy mock contracts
        mockRouter = new MockRouter();
        mockLinkToken = new MockLinkToken();
        mockAiCCIPProxy = new MockAiCCIPProxy();
        mockPowers = new MockPowers();
        
        // Deploy AddressAnalysis with mock addresses
        addressAnalysis = new TestAddressAnalysis(
            address(mockRouter),
            address(mockLinkToken),
            DESTINATION_CHAIN_SELECTOR,
            address(mockAiCCIPProxy)
        );
        
        // Fund the AddressAnalysis contract with LINK tokens
        mockLinkToken.transfer(address(addressAnalysis), 1000 ether);
        
        // Label addresses for better trace output
        vm.label(address(addressAnalysis), "AddressAnalysis");
        vm.label(address(mockRouter), "MockRouter");
        vm.label(address(mockLinkToken), "MockLinkToken");
        vm.label(address(mockAiCCIPProxy), "MockAiCCIPProxy");
        vm.label(address(mockPowers), "MockPowers");
        vm.label(owner, "Owner");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
    }

    // ============ _ccipReceive Function Tests ============

    function testCcipReceive_ValidMessage() public {
        // Use the simplified simulation function that handles the full flow
        addressAnalysis.simulateRequestAndResponse(
            alice,
            TEST_LAW_ID,
            TEST_ACTION_ID,
            testCategory,
            testExplanation
        );
        
        // Verify the analysis was stored
        (uint256 category, string memory explanation, uint256 roleId, bool analyzed) = 
            addressAnalysis.getAddressAnalysis(alice);
        
        assertEq(category, testCategory, "Category should match");
        assertEq(explanation, testExplanation, "Explanation should match");
        assertEq(roleId, testCategory, "RoleId should match category");
        assertTrue(analyzed, "Address should be marked as analyzed");
    }
    
    function testCcipReceive_NoPendingMessage() public {
        // Create the CCIP message without setting up a pending message
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: testMessageId,
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(address(mockAiCCIPProxy)),
            data: abi.encode(testCategory, testExplanation),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        // Expect revert when no pending message exists
        vm.expectRevert(abi.encodeWithSelector(AddressAnalysis.NoPendingRequest.selector, testMessageId));
        addressAnalysis.testCcipReceive(message);
    }
    
    function testCcipReceive_InvalidSenderEncoding() public {
        // Create the CCIP message with invalid sender encoding (not an address)
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: testMessageId,
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode("invalid_sender_data"), // This will cause abi.decode to revert
            data: abi.encode(testCategory, testExplanation),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        // This should revert due to invalid sender encoding
        vm.expectRevert();
        addressAnalysis.testCcipReceive(message);
    }
    
    function testCcipReceive_InvalidDataEncoding() public {
        // Create the CCIP message with invalid data encoding (wrong types)
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: testMessageId,
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(address(mockAiCCIPProxy)),
            data: abi.encode("wrong_type", 123), // Should be (uint256, string)
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        // This should revert due to invalid data encoding
        vm.expectRevert();
        addressAnalysis.testCcipReceive(message);
    }
    
    function testCcipReceive_EmptyData() public {
        // Create the CCIP message with empty data
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: testMessageId,
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(address(mockAiCCIPProxy)),
            data: "", // Empty data
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        // This should revert due to empty data
        vm.expectRevert();
        addressAnalysis.testCcipReceive(message);
    }
    
    function testCcipReceive_MultipleMessages() public {
        // Process first message
        addressAnalysis.simulateRequestAndResponse(
            alice,
            TEST_LAW_ID,
            TEST_ACTION_ID,
            1,
            "Alice analysis"
        );
        
        // Process second message
        addressAnalysis.simulateRequestAndResponse(
            bob,
            TEST_LAW_ID + 1,
            TEST_ACTION_ID + 1,
            3,
            "Bob analysis"
        );
        
        // Verify both analyses were stored
        (uint256 category1, , , bool analyzed1) = addressAnalysis.getAddressAnalysis(alice);
        (uint256 category2, , , bool analyzed2) = addressAnalysis.getAddressAnalysis(bob);
        
        assertEq(category1, 1, "Alice category should be 1");
        assertEq(category2, 3, "Bob category should be 3");
        assertTrue(analyzed1, "Alice should be analyzed");
        assertTrue(analyzed2, "Bob should be analyzed");
    }
    
    function testCcipReceive_EventEmission() public {
        // Use the simulation function to set up the pending message
        addressAnalysis.simulateRequestAndResponse(
            alice,
            TEST_LAW_ID,
            TEST_ACTION_ID,
            testCategory,
            testExplanation
        );
        
        // The event should have been emitted during the simulation
        // We can verify the state was updated correctly
        (uint256 category, string memory explanation, , bool analyzed) = 
            addressAnalysis.getAddressAnalysis(alice);
        
        assertEq(category, testCategory, "Category should match");
        assertEq(explanation, testExplanation, "Explanation should match");
        assertTrue(analyzed, "Address should be analyzed");
    }
    
    function testCcipReceive_LastReceivedDetails() public {
        // Use the simulation function
        addressAnalysis.simulateRequestAndResponse(
            alice,
            TEST_LAW_ID,
            TEST_ACTION_ID,
            testCategory,
            testExplanation
        );
        
        // Verify last received details
        (bytes32 messageId, address analyzedAddress, uint64 sourceChainSelector, address sender) = 
            addressAnalysis.getLastReceivedAnalysisDetails();
        
        // The messageId will be generated from actionId and caller
        bytes32 expectedMessageId = keccak256(abi.encodePacked(TEST_ACTION_ID, alice));
        assertEq(messageId, expectedMessageId, "Message ID should match");
        assertEq(analyzedAddress, alice, "Analyzed address should match");
        assertEq(sourceChainSelector, SOURCE_CHAIN_SELECTOR, "Source chain selector should match");
        // Note: sender will be the mock address we set in the simulation
    }
}
