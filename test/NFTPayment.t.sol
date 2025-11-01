// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {NFTPayment} from "src/ercs/erc721/NFTPayment.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @notice Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 1e18);
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract NFTPaymentTest is Test {
    NFTPayment private nft;
    MockERC20 private paymentToken;
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    
    uint256 private constant PRICE_TOKEN = 100 * 1e18; // 100 tokens
    uint256 private constant PRICE_ETH = 0.1 ether; // 0.1 ETH
    uint256 private constant MAX_SUPPLY = 1000;
    uint256 private constant ONE = 1e18;
    

    
    function setUp() public {
        // Deploy mock ERC20 token
        paymentToken = new MockERC20("Payment Token", "PAY");
        
        // Deploy NFT contract
        nft = new NFTPayment(
            "UFES NFT",
            "UFES",
            address(paymentToken),
            PRICE_TOKEN,
            PRICE_ETH,
            MAX_SUPPLY,
            owner
        );
        
        // Give tokens to test users
        paymentToken.mint(alice, 10000 * ONE);
        paymentToken.mint(bob, 10000 * ONE);
    }
    
    function testInitialState() public {
        assertEq(nft.owner(), owner);
        assertEq(address(nft.paymentToken()), address(paymentToken));
        assertEq(nft.priceInToken(), PRICE_TOKEN);
        assertEq(nft.priceInETH(), PRICE_ETH);
        assertEq(nft.maxSupply(), MAX_SUPPLY);
        assertTrue(nft.saleActive());
        assertEq(nft.currentSupply(), 0);
    }
    
    function testMintWithToken() public {
        vm.startPrank(alice);
        
        // Approve NFT contract to spend tokens
        paymentToken.approve(address(nft), PRICE_TOKEN);
        
        // Mint NFT
        nft.mintWithToken(alice);
        vm.stopPrank();
        
        // Check NFT ownership
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.currentSupply(), 1);
        
        // Check payment token was transferred
        assertEq(paymentToken.balanceOf(alice), 10000 * ONE - PRICE_TOKEN);
        assertEq(paymentToken.balanceOf(address(nft)), PRICE_TOKEN);
    }
    
    function testMintWithETH() public {
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        
        nft.mintWithETH{value: PRICE_ETH}(alice);
        
        // Check NFT ownership
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.currentSupply(), 1);
        
        // Check contract received ETH
        assertEq(address(nft).balance, PRICE_ETH);
    }
    
    function testMintWithETHExcessRefund() public {
        vm.deal(alice, 10 ether);
        uint256 excessAmount = 0.5 ether;
        vm.prank(alice);
        
        nft.mintWithETH{value: PRICE_ETH + excessAmount}(alice);
        
        // Check NFT was minted
        assertEq(nft.ownerOf(0), alice);
        
        // Check contract received only exact price
        assertEq(address(nft).balance, PRICE_ETH);
        
        // Check excess was refunded (alice should have 10 - PRICE_ETH - excessAmount + excessAmount back)
        assertEq(alice.balance, 10 ether - PRICE_ETH);
    }
    
    function testMintMultipleNFTsWithToken() public {
        vm.startPrank(alice);
        paymentToken.approve(address(nft), PRICE_TOKEN * 5);
        
        // Mint 5 NFTs
        for (uint256 i = 0; i < 5; i++) {
            nft.mintWithToken(alice);
        }
        vm.stopPrank();
        
        assertEq(nft.balanceOf(alice), 5);
        assertEq(nft.currentSupply(), 5);
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(4), alice);
    }
    
    function testMintMultipleNFTsWithETH() public {
        vm.deal(alice, 10 ether);
        vm.startPrank(alice);
        
        // Mint 5 NFTs
        for (uint256 i = 0; i < 5; i++) {
            nft.mintWithETH{value: PRICE_ETH}(alice);
        }
        vm.stopPrank();
        
        assertEq(nft.balanceOf(alice), 5);
        assertEq(nft.currentSupply(), 5);
    }
    
    function testMintWithInsufficientToken() public {
        vm.startPrank(alice);
        paymentToken.approve(address(nft), PRICE_TOKEN - 1);
        
        // Should fail - insufficient allowance
        vm.expectRevert();
        nft.mintWithToken(alice);
        vm.stopPrank();
    }
    
    function testMintWithInsufficientETH() public {
        vm.deal(alice, PRICE_ETH - 1);
        vm.prank(alice);
        
        vm.expectRevert(abi.encodeWithSignature("InsufficientPayment()"));
        nft.mintWithETH{value: PRICE_ETH - 1}(alice);
    }
    
    function testMintWithTokenWhenSaleInactive() public {
        vm.prank(owner);
        nft.setSaleActive(false);
        
        vm.startPrank(alice);
        paymentToken.approve(address(nft), PRICE_TOKEN);
        
        vm.expectRevert(abi.encodeWithSignature("SaleNotActive()"));
        nft.mintWithToken(alice);
        vm.stopPrank();
    }
    
    function testMintWithETHWhenSaleInactive() public {
        vm.deal(alice, 10 ether);
        vm.prank(owner);
        nft.setSaleActive(false);
        
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("SaleNotActive()"));
        nft.mintWithETH{value: PRICE_ETH}(alice);
    }
    
    function testMintExceedsMaxSupply() public {
        // Give alice enough tokens to mint all NFTs
        paymentToken.mint(alice, PRICE_TOKEN * MAX_SUPPLY);
        
        vm.startPrank(alice);
        paymentToken.approve(address(nft), PRICE_TOKEN * (MAX_SUPPLY + 1));
        
        // Mint up to max supply
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            nft.mintWithToken(alice);
        }
        
        // Verify we reached max supply
        assertEq(nft.currentSupply(), MAX_SUPPLY);
        
        // Next mint should fail
        vm.expectRevert(abi.encodeWithSignature("MaxSupplyReached()"));
        nft.mintWithToken(alice);
        vm.stopPrank();
    }
    
    function testOwnerSetPrices() public {
        uint256 newTokenPrice = 200 * ONE;
        uint256 newETHPrice = 0.2 ether;
        
        vm.prank(owner);
        nft.setPrices(newTokenPrice, newETHPrice);
        
        assertEq(nft.priceInToken(), newTokenPrice);
        assertEq(nft.priceInETH(), newETHPrice);
    }
    
    function testNonOwnerCannotSetPrices() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.setPrices(100 * ONE, 0.1 ether);
    }
    
    function testOwnerSetPaymentToken() public {
        MockERC20 newToken = new MockERC20("New Token", "NEW");
        vm.prank(owner);
        nft.setPaymentToken(address(newToken));
        
        assertEq(address(nft.paymentToken()), address(newToken));
    }
    
    function testOwnerToggleSale() public {
        vm.prank(owner);
        nft.setSaleActive(false);
        assertFalse(nft.saleActive());
        
        vm.prank(owner);
        nft.setSaleActive(true);
        assertTrue(nft.saleActive());
    }
    
    function testOwnerWithdrawTokens() public {
        // First, mint with tokens to get some tokens in contract
        vm.startPrank(alice);
        paymentToken.approve(address(nft), PRICE_TOKEN);
        nft.mintWithToken(alice);
        vm.stopPrank();
        
        uint256 contractBalance = paymentToken.balanceOf(address(nft));
        uint256 ownerBalanceBefore = paymentToken.balanceOf(owner);
        
        vm.prank(owner);
        nft.withdrawTokens(address(paymentToken), contractBalance);
        
        assertEq(paymentToken.balanceOf(address(nft)), 0);
        assertEq(paymentToken.balanceOf(owner), ownerBalanceBefore + contractBalance);
    }
    
    function testOwnerWithdrawETH() public {
        // First, mint with ETH to get some ETH in contract
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        nft.mintWithETH{value: PRICE_ETH}(alice);
        
        uint256 contractBalance = address(nft).balance;
        assertEq(contractBalance, PRICE_ETH);
        
        uint256 ownerBalanceBefore = owner.balance;
        
        // Withdraw ETH
        vm.prank(owner);
        nft.withdrawETH();
        
        assertEq(address(nft).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
    }
    
    function testOwnerSetBaseURI() public {
        // First, mint a token to test URI
        vm.startPrank(alice);
        paymentToken.approve(address(nft), PRICE_TOKEN);
        nft.mintWithToken(alice);
        vm.stopPrank();
        
        // Set base URI
        string memory newURI = "https://example.com/api/token/";
        vm.prank(owner);
        nft.setBaseURI(newURI);
        
        // Check URI was set (indirectly via tokenURI)
        string memory uri = nft.tokenURI(0);
        assertTrue(bytes(uri).length > 0);
        assertEq(uri, string.concat(newURI, "0"));
    }
    
    function testMixedPayments() public {
        // Alice mints with token
        vm.startPrank(alice);
        paymentToken.approve(address(nft), PRICE_TOKEN);
        nft.mintWithToken(alice);
        vm.stopPrank();
        
        // Bob mints with ETH
        vm.deal(bob, 10 ether);
        vm.prank(bob);
        nft.mintWithETH{value: PRICE_ETH}(bob);
        
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.balanceOf(bob), 1);
        assertEq(nft.currentSupply(), 2);
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), bob);
    }
    
    function testEnumerateTokens() public {
        vm.startPrank(alice);
        paymentToken.approve(address(nft), PRICE_TOKEN * 3);
        
        // Mint 3 NFTs
        for (uint256 i = 0; i < 3; i++) {
            nft.mintWithToken(alice);
        }
        vm.stopPrank();
        
        // Test basic ownership functions (ERC721Enumerable was removed)
        assertEq(nft.balanceOf(alice), 3);
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), alice);
        assertEq(nft.currentSupply(), 3);
    }
    
    function testMintWithZeroAddress() public {
        vm.startPrank(alice);
        paymentToken.approve(address(nft), PRICE_TOKEN);
        
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        nft.mintWithToken(address(0));
        vm.stopPrank();
        
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        nft.mintWithETH{value: PRICE_ETH}(address(0));
    }
}

