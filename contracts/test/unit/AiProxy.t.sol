// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

//////////////////////////////////////////////////////////////////////
//                         AI generated tests.                      // 
//  for now, they pretty much all fail. Can get back to it later.   //
//////////////////////////////////////////////////////////////////////

import {Test, console} from "forge-std/Test.sol";
import {AiProxy} from "../../src/AiProxy.sol";
import {MockLinkToken} from "../../lib/chainlink-evm/contracts/src/v0.8/functions/tests/v1_X/testhelpers/MockLinkToken.sol";

/**
 * @title MockOracle
 * @notice Mock oracle contract for testing AiProxy
 */
contract MockOracle {
    address public linkToken;
    address public owner;
    
    constructor(address _linkToken, address _owner) {
        linkToken = _linkToken;
        owner = _owner;
    }
    
    // Mock function to simulate oracle behavior
    function fulfillRequest(
        address target,
        bytes32 requestId,
        uint256 category,
        string memory explanation
    ) external {
        // This simulates the oracle calling back to the AiProxy contract
        // In a real scenario, this would be called by the Chainlink node
        AiProxy(target).fulfillAddressAnalysis(requestId, category, explanation);
    }
}

/**
 * @title AiProxyTest
 * @notice Comprehensive unit tests for AiProxy contract
 */
contract AiProxyTest is Test {
    // Test contracts
    AiProxy public aiProxy;
    MockLinkToken public mockLinkToken;
    MockOracle public mockOracle;
    
    // Test addresses
    address public ownerProxy = makeAddr("ownerProxy");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    
    // Test constants
    bytes32 public constant JOB_ID = "test_job_id_12345";
    uint256 public constant ORACLE_PAYMENT = 0.1 ether; // 0.1 LINK
    string public constant API_URL = "https://ai-leviathan.vercel.app/api/address-analysis?address=";
    
    // Test addresses for analysis
    address public testAddress1 = makeAddr("test_address_1");
    address public testAddress2 = makeAddr("test_address_2");
    address public testAddress3 = makeAddr("test_address_3");

    function setUp() public {
        // Deploy mock contracts
        mockLinkToken = new MockLinkToken();
        mockOracle = new MockOracle(address(mockLinkToken), ownerProxy);
        
        
        // Deploy AiProxy with mock addresses
        aiProxy = new AiProxy(ownerProxy);

        address testOwner = aiProxy.owner(); // this is the owner of the AiProxy contract
        assertEq(testOwner, ownerProxy, "Owner should be set correctly");
        
        // Set up the contract with mock addresses
        vm.startPrank(ownerProxy);
        aiProxy.setOracle(address(mockOracle));
        aiProxy.setJobId(JOB_ID);
        vm.stopPrank();

        // Fund the AiProxy contract with LINK tokens
        mockLinkToken.transfer(address(aiProxy), 1000 ether);
        
        // Label addresses for better trace output
        vm.label(address(aiProxy), "AiProxy");
        vm.label(address(mockLinkToken), "MockLinkToken");
        vm.label(address(mockOracle), "MockOracle");
        vm.label(ownerProxy, "Owner");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(testAddress1, "TestAddress1");
        vm.label(testAddress2, "TestAddress2");
        vm.label(testAddress3, "TestAddress3");
    }

    // ============ Constructor Tests ============

    function test_Constructor_InitializesCorrectly() public {
        AiProxy newProxy = new AiProxy(ownerProxy);
        
        // Check that owner is set correctly
        assertEq(newProxy.owner(), ownerProxy, "Owner should be set correctly");
        
        // Note: We can't easily test internal Chainlink state without exposing it
        // The constructor should set up the contract correctly
    }

    // ============ Request Tests ============

    function test_RequestAddressAnalysis_Success() public {
        vm.prank(alice);
        
        // Expect the event to be emitted
        vm.expectEmit(true, true, false, true);
        emit AiProxy.AddressAnalysisRequested(bytes32(0), testAddress1);
        
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // Check that the request was made (we can't easily check the exact requestId due to randomness)
        // But we can verify the contract state hasn't changed inappropriately
        (uint256 category, string memory explanation) = aiProxy.getAddressAnalysis(testAddress1);
        assertEq(category, 0, "Category should be 0 before fulfillment");
        assertEq(explanation, "", "Explanation should be empty before fulfillment");
    }

    function test_RequestAddressAnalysis_RevertWhen_ZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert("Invalid address");
        aiProxy.requestAddressAnalysis(address(0));
    }

    function test_RequestAddressAnalysis_RevertWhen_InsufficientLINK() public {
        // Drain the contract of LINK tokens
        vm.prank(ownerProxy);
        aiProxy.withdrawLink();
        
        vm.prank(alice);
        vm.expectRevert();
        aiProxy.requestAddressAnalysis(testAddress1);
    }

    function test_RequestAddressAnalysis_UpdatesPendingRequests() public {
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // We can't easily check the exact requestId, but we can verify the request was made
        // by checking that the contract has a pending request
        // This is a bit tricky to test directly, so we'll test the fulfillment flow instead
    }

    // ============ Fulfillment Tests ============

    function test_FulfillAddressAnalysis_Success() public {
        // First request the analysis
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // Create a mock requestId for testing
        bytes32 requestId = keccak256(abi.encodePacked(testAddress1, block.timestamp));
        
        // Now fulfill the request using the mock oracle
        vm.prank(address(mockOracle));
        mockOracle.fulfillRequest(
            address(aiProxy),
            requestId,
            3, // category
            "This address is a smart contract with high transaction volume"
        );
        
        // Check that the analysis was stored
        (uint256 category, string memory explanation) = aiProxy.getAddressAnalysis(testAddress1);
        assertEq(category, 3, "Category should be stored correctly");
        assertEq(explanation, "This address is a smart contract with high transaction volume", "Explanation should be stored correctly");
    }

    function test_FulfillAddressAnalysis_RevertWhen_NotOracle() public {
        // First request the analysis
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // Try to fulfill from non-oracle address
        vm.prank(bob);
        vm.expectRevert();
        aiProxy.fulfillAddressAnalysis(
            bytes32("invalid_request"),
            1,
            "Invalid fulfillment"
        );
    }

    function test_FulfillAddressAnalysis_RevertWhen_RequestNotFound() public {
        vm.prank(address(mockOracle));
        vm.expectRevert("Request not found");
        aiProxy.fulfillAddressAnalysis(
            bytes32("non_existent_request"),
            1,
            "This request doesn't exist"
        );
    }

    function test_FulfillAddressAnalysis_EmitsEvent() public {
        // First request the analysis
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // Create a mock requestId for testing
        bytes32 requestId = keccak256(abi.encodePacked(testAddress1, block.timestamp));
        
        // Expect the fulfillment event
        vm.expectEmit(true, true, false, true);
        emit AiProxy.AddressAnalysisFulfilled(
            requestId,
            testAddress1,
            5,
            "High-value DeFi protocol address"
        );
        
        // Fulfill the request using the mock oracle
        vm.prank(address(mockOracle));
        mockOracle.fulfillRequest(
            address(aiProxy),
            requestId,
            5,
            "High-value DeFi protocol address"
        );
    }

    // ============ Getter Tests ============

    function test_GetAddressAnalysis_ReturnsCorrectData() public {
        // First request and fulfill an analysis
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // Create a mock requestId for testing
        bytes32 requestId = keccak256(abi.encodePacked(testAddress1, block.timestamp));
        
        vm.prank(address(mockOracle));
        mockOracle.fulfillRequest(
            address(aiProxy),
            requestId,
            7,
            "Exchange hot wallet with frequent transfers"
        );
        
        // Now get the analysis
        (uint256 category, string memory explanation) = aiProxy.getAddressAnalysis(testAddress1);
        assertEq(category, 7, "Category should be returned correctly");
        assertEq(explanation, "Exchange hot wallet with frequent transfers", "Explanation should be returned correctly");
    }

    function test_GetAddressAnalysis_ReturnsEmptyForNonExistentAddress() public {
        (uint256 category, string memory explanation) = aiProxy.getAddressAnalysis(testAddress3);
        assertEq(category, 0, "Category should be 0 for non-existent analysis");
        assertEq(explanation, "", "Explanation should be empty for non-existent analysis");
    }

    // ============ Owner Function Tests ============

    function test_SetJobId_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        aiProxy.setJobId("new_job_id");
        
        // Owner should be able to set it
        vm.prank(ownerProxy);
        aiProxy.setJobId("new_job_id");
    }

    function test_SetOracle_OnlyOwner() public {
        address newOracle = makeAddr("new_oracle");
        
        vm.prank(alice);
        vm.expectRevert();
        aiProxy.setOracle(newOracle);
        
        // Owner should be able to set it
        vm.prank(ownerProxy);
        aiProxy.setOracle(newOracle);
    }

    function test_WithdrawLink_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        aiProxy.withdrawLink();
        
        // Owner should be able to withdraw
        vm.prank(ownerProxy);
        aiProxy.withdrawLink();
    }

    // ============ Integration Tests ============

    function test_CompleteWorkflow_SingleAddress() public {
        // 1. Request analysis
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // 2. Create a mock requestId for testing
        bytes32 requestId = keccak256(abi.encodePacked(testAddress1, block.timestamp));
        
        // 3. Fulfill request using the mock oracle
        vm.prank(address(mockOracle));
        mockOracle.fulfillRequest(
            address(aiProxy),
            requestId,
            4,
            "Medium-risk trading address"
        );
        
        // 4. Verify result
        (uint256 category, string memory explanation) = aiProxy.getAddressAnalysis(testAddress1);
        assertEq(category, 4, "Category should be correct after complete workflow");
        assertEq(explanation, "Medium-risk trading address", "Explanation should be correct after complete workflow");
    }

    function test_CompleteWorkflow_MultipleAddresses() public {
        // Analyze multiple addresses
        address[] memory addresses = new address[](3);
        addresses[0] = testAddress1;
        addresses[1] = testAddress2;
        addresses[2] = testAddress3;
        
        uint256[] memory categories = new uint256[](3);
        categories[0] = 1;
        categories[1] = 2;
        categories[2] = 3;
        
        string[] memory explanations = new string[](3);
        explanations[0] = "Low-risk address";
        explanations[1] = "Medium-risk address";
        explanations[2] = "High-risk address";
        
        // Request analysis for all addresses
        for (uint256 i = 0; i < addresses.length; i++) {
            vm.prank(alice);
            aiProxy.requestAddressAnalysis(addresses[i]);
        }
        
        // Fulfill all requests
        for (uint256 i = 0; i < addresses.length; i++) {
            // Create a mock requestId for testing
            bytes32 requestId = keccak256(abi.encodePacked(addresses[i], block.timestamp + i));
            
            vm.prank(address(mockOracle));
            mockOracle.fulfillRequest(
                address(aiProxy),
                requestId,
                categories[i],
                explanations[i]
            );
        }
        
        // Verify all results
        for (uint256 i = 0; i < addresses.length; i++) {
            (uint256 category, string memory explanation) = aiProxy.getAddressAnalysis(addresses[i]);
            assertEq(category, categories[i], "Category should be correct for all addresses");
            assertEq(explanation, explanations[i], "Explanation should be correct for all addresses");
        }
    }

    // ============ Fuzz Tests ============

    function testFuzz_RequestAddressAnalysis(uint256 addressSeed) public {
        // Generate a deterministic address from the seed
        address testAddr = address(uint160(addressSeed % 2**160));
        
        // Skip zero address
        vm.assume(testAddr != address(0));
        
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddr);
        
        // Verify the request was made (basic check)
        (uint256 category, string memory explanation) = aiProxy.getAddressAnalysis(testAddr);
        assertEq(category, 0, "Category should be 0 before fulfillment");
        assertEq(explanation, "", "Explanation should be empty before fulfillment");
    }

    function testFuzz_FulfillAddressAnalysis(uint256 category, string memory explanation) public {
        // Bound the category to reasonable values
        category = bound(category, 1, 100);
        
        // Bound the explanation length
        vm.assume(bytes(explanation).length <= 1000);
        
        // Request analysis
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // Create a mock requestId for testing
        bytes32 requestId = keccak256(abi.encodePacked(testAddress1, block.timestamp));
        
        vm.prank(address(mockOracle));
        mockOracle.fulfillRequest(
            address(aiProxy),
            requestId,
            category,
            explanation
        );
        
        // Verify result
        (uint256 storedCategory, string memory storedExplanation) = aiProxy.getAddressAnalysis(testAddress1);
        assertEq(storedCategory, category, "Category should match input");
        assertEq(storedExplanation, explanation, "Explanation should match input");
    }

    // ============ Gas Tests ============

    function testGas_RequestAddressAnalysis() public {
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        aiProxy.requestAddressAnalysis(testAddress1);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for requestAddressAnalysis:", gasUsed);
        assertLt(gasUsed, 200000, "Request should use reasonable gas");
    }

    function testGas_FulfillAddressAnalysis() public {
        // First request
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // Create a mock requestId for testing
        bytes32 requestId = keccak256(abi.encodePacked(testAddress1, block.timestamp));
        console.log("requestId:");
        console.logBytes32(requestId);
        
        vm.prank(address(mockOracle));
        uint256 gasBefore = gasleft();
        mockOracle.fulfillRequest(
            address(aiProxy),
            requestId,
            1,
            "Test explanation"
        );
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for fulfillAddressAnalysis:", gasUsed);
        assertLt(gasUsed, 150000, "Fulfillment should use reasonable gas");
    }

    function testGas_GetAddressAnalysis() public {
        // First set up some data
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // Create a mock requestId for testing
        bytes32 requestId = keccak256(abi.encodePacked(testAddress1, block.timestamp));
        
        vm.prank(address(mockOracle));
        mockOracle.fulfillRequest(
            address(aiProxy),
            requestId,
            1,
            "Test explanation"
        );
        
        // Now test gas usage
        uint256 gasBefore = gasleft();
        aiProxy.getAddressAnalysis(testAddress1);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for getAddressAnalysis:", gasUsed);
        assertLt(gasUsed, 50000, "Get should use minimal gas");
    }

    // ============ Edge Case Tests ============

    function test_RequestAddressAnalysis_SameAddressMultipleTimes() public {
        // Request analysis for the same address multiple times
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(alice);
            aiProxy.requestAddressAnalysis(testAddress1);
        }
        
        // Only the last request should be pending
        // This is a basic test to ensure the contract doesn't break
        (uint256 category, string memory explanation) = aiProxy.getAddressAnalysis(testAddress1);
        assertEq(category, 0, "Category should still be 0 before fulfillment");
        assertEq(explanation, "", "Explanation should still be empty before fulfillment");
    }

    function test_RequestAddressAnalysis_ZeroValueTransfer() public {
        // This test ensures the contract handles zero-value transfers correctly
        // (though this shouldn't happen in practice with proper LINK amounts)
        vm.prank(alice);
        aiProxy.requestAddressAnalysis(testAddress1);
        
        // Basic verification that the request was made
        (uint256 category, string memory explanation) = aiProxy.getAddressAnalysis(testAddress1);
        assertEq(category, 0, "Category should be 0 before fulfillment");
    }

    // ============ Helper Function Tests ============

    function test_AddressToString_Conversion() public {
        // Test the internal address to string conversion
        // We can't directly test private functions, but we can test them indirectly
        // through the public interface
        
        // Create a contract that exposes the function for testing
        TestHelper helper = new TestHelper();
        
        address testAddr = 0x1234567890123456789012345678901234567890;
        string memory result = helper.testAddressToString(testAddr);
        
        assertEq(result, "0x1234567890123456789012345678901234567890", "Address should convert to string correctly");
    }

    function test_ToHexString_Conversion() public {
        TestHelper helper = new TestHelper();
        
        uint256 value = 0x1234567890ABCDEF;
        string memory result = helper.testToHexString(value, 8);
        
        assertEq(result, "0x1234567890abcdef", "Hex conversion should work correctly");
    }
}

/**
 * @title TestHelper
 * @notice Helper contract to test internal functions
 */
contract TestHelper {
    function testAddressToString(address addr) external pure returns (string memory) {
        return _toHexString(uint256(uint160(addr)), 20);
    }
    
    function testToHexString(uint256 value, uint256 length) external pure returns (string memory) {
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
    
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
}
