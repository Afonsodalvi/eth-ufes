// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title NFT with Dual Payment (ERC20 Token or ETH)
/// @notice ERC721 NFT contract that accepts payment in ERC20 tokens or ETH
/// @dev Supports minting with either payment method, with separate pricing
contract NFTPayment is ERC721, Ownable, ReentrancyGuard {
    /// @dev Token used for payment (ERC20)
    IERC20 public paymentToken;
    
    /// @dev Price in payment token (wei/token units)
    uint256 public priceInToken;
    
    /// @dev Price in ETH (wei)
    uint256 public priceInETH;
    
    /// @dev Maximum supply of NFTs
    uint256 public maxSupply;
    
    /// @dev Current token ID counter
    uint256 private _tokenIdCounter;
    
    /// @dev Base URI for token metadata
    string private _baseTokenURI;
    
    /// @dev Sale active status
    bool public saleActive;
    
    event MintedWithToken(address indexed to, uint256 tokenId, uint256 amountPaid);
    event MintedWithETH(address indexed to, uint256 tokenId, uint256 amountPaid);
    event PaymentTokenUpdated(address indexed oldToken, address indexed newToken);
    event PriceUpdated(uint256 newTokenPrice, uint256 newETHPrice);
    event SaleStatusUpdated(bool active);
    
    error InsufficientPayment();
    error MaxSupplyReached();
    error SaleNotActive();
    error ZeroAddress();
    error ZeroAmount();
    
    constructor(
        string memory name_,
        string memory symbol_,
        address paymentToken_,
        uint256 priceInToken_,
        uint256 priceInETH_,
        uint256 maxSupply_,
        address initialOwner
    ) ERC721(name_, symbol_) Ownable(initialOwner) {
        if (paymentToken_ == address(0)) revert ZeroAddress();
        if (maxSupply_ == 0) revert ZeroAmount();
        
        paymentToken = IERC20(paymentToken_);
        priceInToken = priceInToken_;
        priceInETH = priceInETH_;
        maxSupply = maxSupply_;
        saleActive = true;
    }
    
    /// @notice Mint NFT paying with ERC20 token
    /// @dev Requires approval from user to this contract
    /// @param to Address to receive the NFT
    function mintWithToken(address to) external nonReentrant {
        if (!saleActive) revert SaleNotActive();
        if (_tokenIdCounter >= maxSupply) revert MaxSupplyReached();
        if (to == address(0)) revert ZeroAddress();
        
        // Transfer payment token from user to this contract
        bool success = paymentToken.transferFrom(msg.sender, address(this), priceInToken);
        require(success, "NFTPayment: token transfer failed");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(to, tokenId);
        
        emit MintedWithToken(to, tokenId, priceInToken);
    }
    
    /// @notice Mint NFT paying with ETH
    /// @param to Address to receive the NFT
    function mintWithETH(address to) external payable nonReentrant {
        if (!saleActive) revert SaleNotActive();
        if (_tokenIdCounter >= maxSupply) revert MaxSupplyReached();
        if (to == address(0)) revert ZeroAddress();
        if (msg.value < priceInETH) revert InsufficientPayment();
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(to, tokenId);
        
        // Refund excess ETH if any
        if (msg.value > priceInETH) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - priceInETH}("");
            require(refundSuccess, "NFTPayment: ETH refund failed");
        }
        
        emit MintedWithETH(to, tokenId, priceInETH);
    }
    
    /// @notice Owner: Update payment token address
    function setPaymentToken(address newPaymentToken) external onlyOwner {
        if (newPaymentToken == address(0)) revert ZeroAddress();
        address oldToken = address(paymentToken);
        paymentToken = IERC20(newPaymentToken);
        emit PaymentTokenUpdated(oldToken, newPaymentToken);
    }
    
    /// @notice Owner: Update prices for both payment methods
    function setPrices(uint256 newPriceInToken, uint256 newPriceInETH) external onlyOwner {
        priceInToken = newPriceInToken;
        priceInETH = newPriceInETH;
        emit PriceUpdated(newPriceInToken, newPriceInETH);
    }
    
    /// @notice Owner: Toggle sale status
    function setSaleActive(bool active) external onlyOwner {
        saleActive = active;
        emit SaleStatusUpdated(active);
    }
    
    /// @notice Owner: Set base URI for token metadata
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    /// @notice Owner: Withdraw ERC20 tokens from contract
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
    
    /// @notice Owner: Withdraw ETH from contract
    function withdrawETH() external payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "NFTPayment: ETH withdrawal failed");
    }
    
    /// @notice Get current token supply
    function currentSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }
    
    /// @notice Override baseURI
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    /// @notice Required overrides for ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
    
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721)
    {
        super._increaseBalance(account, value);
    }

}

