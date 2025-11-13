// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {GameCollection} from "src/ercs/erc1155/GameCollection.sol";

contract GameCollectionTest is Test {
    GameCollection private gameCollection;
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    string private constant BASE_URI = "https://api.game.com/tokens/";

    function setUp() public {
        gameCollection = new GameCollection(owner, BASE_URI);
    }

    function testInitialState() public {
        assertEq(gameCollection.owner(), owner);
        assertTrue(gameCollection.globalSaleActive());
        assertEq(gameCollection.balanceOf(alice, 0), 0);
        assertEq(gameCollection.balanceOf(bob, 0), 0);
    }

    function testSetTokenSupply() public {
        uint256 tokenId = 1;
        uint256 supply = 100;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, supply);

        assertEq(gameCollection.maxSupply(tokenId), supply);
        assertEq(gameCollection.currentSupply(tokenId), 0);
    }

    function testSetTokenSupplyBatch() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256[] memory supplies = new uint256[](3);
        supplies[0] = 100;
        supplies[1] = 200;
        supplies[2] = 300;

        vm.prank(owner);
        gameCollection.setTokenSupplyBatch(tokenIds, supplies);

        assertEq(gameCollection.maxSupply(1), 100);
        assertEq(gameCollection.maxSupply(2), 200);
        assertEq(gameCollection.maxSupply(3), 300);
    }

    function testMint() public {
        uint256 tokenId = 1;
        uint256 supply = 100;
        uint256 amount = 10;

        // Set supply
        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, supply);

        // Mint tokens
        vm.prank(owner);
        gameCollection.mint(alice, tokenId, amount, "");

        assertEq(gameCollection.balanceOf(alice, tokenId), amount);
        assertEq(gameCollection.currentSupply(tokenId), amount);
        assertEq(gameCollection.maxSupply(tokenId), supply);
    }

    function testMintMultiple() public {
        uint256 tokenId = 1;
        uint256 supply = 100;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, supply);

        // Mint multiple times
        vm.startPrank(owner);
        gameCollection.mint(alice, tokenId, 10, "");
        gameCollection.mint(alice, tokenId, 20, "");
        gameCollection.mint(bob, tokenId, 30, "");
        vm.stopPrank();

        assertEq(gameCollection.balanceOf(alice, tokenId), 30);
        assertEq(gameCollection.balanceOf(bob, tokenId), 30);
        assertEq(gameCollection.currentSupply(tokenId), 60);
    }

    function testMintBatch() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256[] memory supplies = new uint256[](3);
        supplies[0] = 100;
        supplies[1] = 200;
        supplies[2] = 300;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        // Set supplies
        vm.prank(owner);
        gameCollection.setTokenSupplyBatch(tokenIds, supplies);

        // Batch mint
        vm.prank(owner);
        gameCollection.mintBatch(alice, tokenIds, amounts, "");

        assertEq(gameCollection.balanceOf(alice, 1), 10);
        assertEq(gameCollection.balanceOf(alice, 2), 20);
        assertEq(gameCollection.balanceOf(alice, 3), 30);

        assertEq(gameCollection.currentSupply(1), 10);
        assertEq(gameCollection.currentSupply(2), 20);
        assertEq(gameCollection.currentSupply(3), 30);
    }

    function testMintExceedsMaxSupply() public {
        uint256 tokenId = 1;
        uint256 supply = 100;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, supply);

        // Try to mint more than max supply
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("MaxSupplyReached(uint256)", tokenId));
        gameCollection.mint(alice, tokenId, supply + 1, "");
    }

    function testMintWithoutSupplySet() public {
        uint256 tokenId = 999;

        // Try to mint without setting supply
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("InvalidTokenId(uint256)", tokenId));
        gameCollection.mint(alice, tokenId, 10, "");
    }

    function testMintZeroAmount() public {
        uint256 tokenId = 1;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, 100);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        gameCollection.mint(alice, tokenId, 0, "");
    }

    function testMintToZeroAddress() public {
        uint256 tokenId = 1;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, 100);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        gameCollection.mint(address(0), tokenId, 10, "");
    }

    function testNonOwnerCannotMint() public {
        uint256 tokenId = 1;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, 100);

        vm.prank(alice);
        vm.expectRevert();
        gameCollection.mint(alice, tokenId, 10, "");
    }

    function testSetTokenSaleActive() public {
        uint256 tokenId = 1;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, 100);

        // Disable sale
        vm.prank(owner);
        gameCollection.setTokenSaleActive(tokenId, false);
        assertFalse(gameCollection.saleActive(tokenId));

        // Try to mint should fail
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("SaleNotActive(uint256)", tokenId));
        gameCollection.mint(alice, tokenId, 10, "");

        // Enable sale
        vm.prank(owner);
        gameCollection.setTokenSaleActive(tokenId, true);
        assertTrue(gameCollection.saleActive(tokenId));

        // Now mint should work
        vm.prank(owner);
        gameCollection.mint(alice, tokenId, 10, "");
        assertEq(gameCollection.balanceOf(alice, tokenId), 10);
    }

    function testSetGlobalSaleActive() public {
        uint256 tokenId = 1;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, 100);

        // Disable global sale
        vm.prank(owner);
        gameCollection.setGlobalSaleActive(false);
        assertFalse(gameCollection.globalSaleActive());

        // Try to mint should fail
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("SaleNotActive(uint256)", tokenId));
        gameCollection.mint(alice, tokenId, 10, "");

        // Enable global sale
        vm.prank(owner);
        gameCollection.setGlobalSaleActive(true);
        assertTrue(gameCollection.globalSaleActive());

        // Now mint should work
        vm.prank(owner);
        gameCollection.mint(alice, tokenId, 10, "");
        assertEq(gameCollection.balanceOf(alice, tokenId), 10);
    }

    function testSetURI() public {
        uint256 tokenId = 1;
        string memory customURI = "https://custom.game.com/item1";

        vm.prank(owner);
        gameCollection.setURI(tokenId, customURI);

        string memory uri = gameCollection.uri(tokenId);
        assertEq(uri, customURI);
    }

    function testSetBaseURI() public {
        string memory newBaseURI = "https://newapi.game.com/tokens/";

        vm.prank(owner);
        gameCollection.setBaseURI(newBaseURI);

        // URI should use base URI for tokens without specific URI
        string memory uri = gameCollection.uri(1);
        assertTrue(bytes(uri).length > 0);
    }

    function testURIWithBaseURI() public {
        uint256 tokenId = 42;

        // Token without specific URI should use base URI + tokenId
        string memory uri = gameCollection.uri(tokenId);
        assertEq(uri, string(abi.encodePacked(BASE_URI, "42")));
    }

    function testUpdateSupplyAfterMinting() public {
        uint256 tokenId = 1;
        uint256 initialSupply = 100;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, initialSupply);

        // Mint some tokens
        vm.prank(owner);
        gameCollection.mint(alice, tokenId, 50, "");

        assertEq(gameCollection.currentSupply(tokenId), 50);

        // Try to set supply lower than current
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("InvalidSupply()"));
        gameCollection.setTokenSupply(tokenId, 40);

        // Set supply higher should work
        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, 200);
        assertEq(gameCollection.maxSupply(tokenId), 200);
        assertEq(gameCollection.currentSupply(tokenId), 50);
    }

    function testMultipleTokenTypes() public {
        // Configure multiple token types
        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = 1; // Sword
        tokenIds[1] = 2; // Shield
        tokenIds[2] = 3; // Potion
        tokenIds[3] = 4; // Key

        uint256[] memory supplies = new uint256[](4);
        supplies[0] = 1000;
        supplies[1] = 500;
        supplies[2] = 2000;
        supplies[3] = 100;

        vm.prank(owner);
        gameCollection.setTokenSupplyBatch(tokenIds, supplies);

        // Mint different items to different users
        vm.startPrank(owner);
        gameCollection.mint(alice, 1, 10, ""); // Alice gets 10 swords
        gameCollection.mint(alice, 2, 5, ""); // Alice gets 5 shields
        gameCollection.mint(bob, 3, 20, ""); // Bob gets 20 potions
        gameCollection.mint(bob, 4, 1, ""); // Bob gets 1 key
        vm.stopPrank();

        assertEq(gameCollection.balanceOf(alice, 1), 10);
        assertEq(gameCollection.balanceOf(alice, 2), 5);
        assertEq(gameCollection.balanceOf(bob, 3), 20);
        assertEq(gameCollection.balanceOf(bob, 4), 1);

        assertEq(gameCollection.currentSupply(1), 10);
        assertEq(gameCollection.currentSupply(2), 5);
        assertEq(gameCollection.currentSupply(3), 20);
        assertEq(gameCollection.currentSupply(4), 1);
    }

    function testBatchMintPartialSupply() public {
        uint256 tokenId = 1;
        uint256 supply = 100;

        vm.prank(owner);
        gameCollection.setTokenSupply(tokenId, supply);

        // Mint close to max supply
        vm.startPrank(owner);
        gameCollection.mint(alice, tokenId, 90, "");

        // Try to mint more than remaining supply
        vm.expectRevert(abi.encodeWithSignature("MaxSupplyReached(uint256)", tokenId));
        gameCollection.mint(alice, tokenId, 20, "");

        // Mint remaining supply should work
        gameCollection.mint(alice, tokenId, 10, "");
        vm.stopPrank();

        assertEq(gameCollection.balanceOf(alice, tokenId), 100);
        assertEq(gameCollection.currentSupply(tokenId), 100);
    }

    function testNonOwnerCannotSetSupply() public {
        vm.prank(alice);
        vm.expectRevert();
        gameCollection.setTokenSupply(1, 100);
    }

    function testNonOwnerCannotSetURI() public {
        vm.prank(alice);
        vm.expectRevert();
        gameCollection.setURI(1, "https://test.com");
    }

    function testNonOwnerCannotToggleSale() public {
        vm.prank(alice);
        vm.expectRevert();
        gameCollection.setTokenSaleActive(1, true);

        vm.prank(alice);
        vm.expectRevert();
        gameCollection.setGlobalSaleActive(false);
    }
}
