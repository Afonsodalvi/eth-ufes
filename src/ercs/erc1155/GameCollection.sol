// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155URIStorage} from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

/// @title Game Collection ERC1155
/// @notice ERC1155 contract for game items/collectibles with per-token-ID supply limits
/// @dev Each token ID has its own maximum supply and URI for metadata
contract GameCollection is ERC1155, ERC1155URIStorage, Ownable {
    /// @dev Maximum supply per token ID
    mapping(uint256 => uint256) public maxSupply;
    
    /// @dev Current supply per token ID
    mapping(uint256 => uint256) public currentSupply;
    
    /// @dev Sale active status per token ID
    mapping(uint256 => bool) public saleActive;
    
    /// @dev Track if sale status was explicitly set for a token ID
    mapping(uint256 => bool) private _saleStatusSet;
    
    /// @dev Global sale active status (overrides per-token status)
    bool public globalSaleActive;
    
    /// @dev Base URI for token metadata
    string private _baseURI;
    
    event TokenSupplySet(uint256 indexed tokenId, uint256 maxSupply);
    event TokenSaleToggled(uint256 indexed tokenId, bool active);
    event GlobalSaleToggled(bool active);
    event Minted(address indexed to, uint256 indexed tokenId, uint256 amount);
    
    error MaxSupplyReached(uint256 tokenId);
    error SaleNotActive(uint256 tokenId);
    error ZeroAmount();
    error ZeroAddress();
    error InvalidTokenId(uint256 tokenId);
    error InvalidSupply();
    
    /// @notice Constructor sets initial owner and base URI
    /// @param initialOwner Address that will own the contract
    /// @param baseURI Base URI for token metadata
    constructor(address initialOwner, string memory baseURI)
        ERC1155("")
        Ownable(initialOwner)
    {
        _baseURI = baseURI;
        globalSaleActive = true;
    }
    
    /// @notice Mint tokens of a specific ID to an address
    /// @dev Checks supply limits and sale status before minting
    /// @param to Address to receive the tokens
    /// @param id Token ID to mint
    /// @param amount Amount of tokens to mint
    /// @param data Additional data to pass (for ERC1155 compatibility)
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (maxSupply[id] == 0) revert InvalidTokenId(id);
        if (!_isSaleActive(id)) revert SaleNotActive(id);
        
        uint256 current = currentSupply[id];
        uint256 max = maxSupply[id];
        
        if (current + amount > max) revert MaxSupplyReached(id);
        
        currentSupply[id] = current + amount;
        _mint(to, id, amount, data);
        
        emit Minted(to, id, amount);
    }
    
    /// @notice Batch mint multiple token IDs to an address
    /// @param to Address to receive the tokens
    /// @param ids Array of token IDs to mint
    /// @param amounts Array of amounts to mint for each ID
    /// @param data Additional data to pass (for ERC1155 compatibility)
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (ids.length != amounts.length) revert InvalidSupply();
        
        for (uint256 i = 0; i < ids.length; i++) {
            if (amounts[i] == 0) revert ZeroAmount();
            if (maxSupply[ids[i]] == 0) revert InvalidTokenId(ids[i]);
            if (!_isSaleActive(ids[i])) revert SaleNotActive(ids[i]);
            
            uint256 current = currentSupply[ids[i]];
            uint256 max = maxSupply[ids[i]];
            
            if (current + amounts[i] > max) revert MaxSupplyReached(ids[i]);
            
            currentSupply[ids[i]] = current + amounts[i];
        }
        
        _mintBatch(to, ids, amounts, data);
        
        // Emit individual events for each token minted
        for (uint256 i = 0; i < ids.length; i++) {
            emit Minted(to, ids[i], amounts[i]);
        }
    }
    
    /// @notice Owner: Set maximum supply for a token ID
    /// @param tokenId Token ID to configure
    /// @param supply Maximum supply for this token ID
    function setTokenSupply(uint256 tokenId, uint256 supply) external onlyOwner {
        if (supply == 0) revert InvalidSupply();
        if (supply < currentSupply[tokenId]) revert InvalidSupply();
        
        maxSupply[tokenId] = supply;
        emit TokenSupplySet(tokenId, supply);
    }
    
    /// @notice Owner: Batch set maximum supplies for multiple token IDs
    /// @param tokenIds Array of token IDs to configure
    /// @param supplies Array of maximum supplies for each token ID
    function setTokenSupplyBatch(
        uint256[] memory tokenIds,
        uint256[] memory supplies
    ) external onlyOwner {
        if (tokenIds.length != supplies.length) revert InvalidSupply();
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (supplies[i] == 0) revert InvalidSupply();
            if (supplies[i] < currentSupply[tokenIds[i]]) revert InvalidSupply();
            
            maxSupply[tokenIds[i]] = supplies[i];
            emit TokenSupplySet(tokenIds[i], supplies[i]);
        }
    }
    
    /// @notice Owner: Set URI for a specific token ID
    /// @param tokenId Token ID to set URI for
    /// @param tokenURI URI string for this token's metadata
    function setURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
        _setURI(tokenId, tokenURI);
    }
    
    /// @notice Owner: Set base URI for all tokens
    /// @param baseURI Base URI string
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURI = baseURI;
    }
    
    /// @notice Owner: Toggle sale status for a specific token ID
    /// @param tokenId Token ID to toggle
    /// @param active Sale status (true = active, false = inactive)
    function setTokenSaleActive(uint256 tokenId, bool active) external onlyOwner {
        saleActive[tokenId] = active;
        _saleStatusSet[tokenId] = true;
        emit TokenSaleToggled(tokenId, active);
    }
    
    /// @notice Owner: Toggle global sale status (affects all tokens)
    /// @param active Global sale status (true = active, false = inactive)
    function setGlobalSaleActive(bool active) external onlyOwner {
        globalSaleActive = active;
        emit GlobalSaleToggled(active);
    }
    
    /// @notice Get URI for a specific token ID
    /// @param tokenId Token ID to get URI for
    /// @return URI string for this token's metadata
    function uri(uint256 tokenId) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
        string memory tokenURI = ERC1155URIStorage.uri(tokenId);
        
        // If token has specific URI, return it; otherwise return baseURI + tokenId
        if (bytes(tokenURI).length > 0) {
            return tokenURI;
        }
        
        // Return base URI with token ID if no specific URI is set
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }
    
    /// @notice Check if sale is active for a token ID
    /// @dev Global sale status overrides per-token status
    /// @dev If sale status was explicitly set, use it; otherwise active by default if supply is set
    /// @param tokenId Token ID to check
    /// @return true if sale is active, false otherwise
    function _isSaleActive(uint256 tokenId) internal view returns (bool) {
        if (!globalSaleActive) return false;
        // If sale status was explicitly set, use it
        if (_saleStatusSet[tokenId]) {
            return saleActive[tokenId];
        }
        // Otherwise, active by default if supply is set
        return maxSupply[tokenId] > 0;
    }
}

