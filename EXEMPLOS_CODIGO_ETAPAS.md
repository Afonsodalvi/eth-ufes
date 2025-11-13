# 📦 Exemplos de Código por Etapa

Este arquivo contém o código completo para cada etapa.

---

## 📄 Etapa 1: Estrutura Básica

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/access/Ownable.sol";

contract NFTPayment is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public maxSupply;
    bool public saleActive;

    event NFTMinted(address indexed to, uint256 tokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address initialOwner
    ) ERC721(name_, symbol_) Ownable(initialOwner) {
        maxSupply = maxSupply_;
        saleActive = true;
    }

    function currentSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function setSaleActive(bool active) external onlyOwner {
        saleActive = active;
    }
}
```

---

## 📄 Etapa 2: Sistema de Preços

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/access/Ownable.sol";

contract NFTPayment is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public maxSupply;
    bool public saleActive;
    uint256 public priceInToken;
    uint256 public priceInETH;

    event NFTMinted(address indexed to, uint256 tokenId);
    event PriceUpdated(uint256 newTokenPrice, uint256 newETHPrice);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 priceInToken_,
        uint256 priceInETH_,
        address initialOwner
    ) ERC721(name_, symbol_) Ownable(initialOwner) {
        maxSupply = maxSupply_;
        priceInToken = priceInToken_;
        priceInETH = priceInETH_;
        saleActive = true;
    }

    function currentSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function setSaleActive(bool active) external onlyOwner {
        saleActive = active;
    }

    function setPrices(
        uint256 newPriceInToken,
        uint256 newPriceInETH
    ) external onlyOwner {
        priceInToken = newPriceInToken;
        priceInETH = newPriceInETH;
        emit PriceUpdated(newPriceInToken, newPriceInETH);
    }
}
```

---

## 📄 Etapa 3: Mint com Token ERC20

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC20/IERC20.sol";

contract NFTPayment is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public maxSupply;
    bool public saleActive;
    uint256 public priceInToken;
    uint256 public priceInETH;
    IERC20 public paymentToken;

    event NFTMinted(address indexed to, uint256 tokenId);
    event PriceUpdated(uint256 newTokenPrice, uint256 newETHPrice);
    event MintedWithToken(address indexed to, uint256 tokenId, uint256 amountPaid);

    constructor(
        string memory name_,
        string memory symbol_,
        address paymentToken_,
        uint256 maxSupply_,
        uint256 priceInToken_,
        uint256 priceInETH_,
        address initialOwner
    ) ERC721(name_, symbol_) Ownable(initialOwner) {
        paymentToken = IERC20(paymentToken_);
        maxSupply = maxSupply_;
        priceInToken = priceInToken_;
        priceInETH = priceInETH_;
        saleActive = true;
    }

    function currentSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function setSaleActive(bool active) external onlyOwner {
        saleActive = active;
    }

    function setPrices(
        uint256 newPriceInToken,
        uint256 newPriceInETH
    ) external onlyOwner {
        priceInToken = newPriceInToken;
        priceInETH = newPriceInETH;
        emit PriceUpdated(newPriceInToken, newPriceInETH);
    }

    function mintWithToken(address to) external {
        require(saleActive, "Venda nao esta ativa");
        require(_tokenIdCounter < maxSupply, "Supply maximo atingido");
        require(to != address(0), "Endereco invalido");
        
        bool success = paymentToken.transferFrom(
            msg.sender, 
            address(this), 
            priceInToken
        );
        require(success, "Transferencia de token falhou");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        
        emit MintedWithToken(to, tokenId, priceInToken);
    }
}
```

---

## 📄 Etapa 4: Mint com ETH

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC20/IERC20.sol";

contract NFTPayment is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public maxSupply;
    bool public saleActive;
    uint256 public priceInToken;
    uint256 public priceInETH;
    IERC20 public paymentToken;

    event NFTMinted(address indexed to, uint256 tokenId);
    event PriceUpdated(uint256 newTokenPrice, uint256 newETHPrice);
    event MintedWithToken(address indexed to, uint256 tokenId, uint256 amountPaid);
    event MintedWithETH(address indexed to, uint256 tokenId, uint256 amountPaid);

    constructor(
        string memory name_,
        string memory symbol_,
        address paymentToken_,
        uint256 maxSupply_,
        uint256 priceInToken_,
        uint256 priceInETH_,
        address initialOwner
    ) ERC721(name_, symbol_) Ownable(initialOwner) {
        paymentToken = IERC20(paymentToken_);
        maxSupply = maxSupply_;
        priceInToken = priceInToken_;
        priceInETH = priceInETH_;
        saleActive = true;
    }

    function currentSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function setSaleActive(bool active) external onlyOwner {
        saleActive = active;
    }

    function setPrices(
        uint256 newPriceInToken,
        uint256 newPriceInETH
    ) external onlyOwner {
        priceInToken = newPriceInToken;
        priceInETH = newPriceInETH;
        emit PriceUpdated(newPriceInToken, newPriceInETH);
    }

    function mintWithToken(address to) external {
        require(saleActive, "Venda nao esta ativa");
        require(_tokenIdCounter < maxSupply, "Supply maximo atingido");
        require(to != address(0), "Endereco invalido");
        
        bool success = paymentToken.transferFrom(
            msg.sender, 
            address(this), 
            priceInToken
        );
        require(success, "Transferencia de token falhou");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        
        emit MintedWithToken(to, tokenId, priceInToken);
    }

    function mintWithETH(address to) external payable {
        require(saleActive, "Venda nao esta ativa");
        require(_tokenIdCounter < maxSupply, "Supply maximo atingido");
        require(to != address(0), "Endereco invalido");
        require(msg.value >= priceInETH, "Valor insuficiente");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        
        if (msg.value > priceInETH) {
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - priceInETH
            }("");
            require(success, "Reembolso falhou");
        }
        
        emit MintedWithETH(to, tokenId, priceInETH);
    }
}
```

---

## 📄 Token Mock para Testes

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Test Token", "TEST") {
        _mint(msg.sender, 1000000 * 10**18);
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
```

---

## 📋 Valores de Teste Recomendados

### Para Deploy no Remix:

**Constructor Parameters:**
```
name_: "Meu NFT"
symbol_: "NFT"
paymentToken_: [endereço do MockToken após deploy]
maxSupply_: 1000
priceInToken_: 100000000000000000000 (100 tokens)
priceInETH_: 100000000000000000 (0.1 ETH)
initialOwner_: [seu endereço]
```

### Para Aprovar Tokens:
```
spender: [endereço do contrato NFT]
amount: 100000000000000000000 (100 tokens)
```

### Para Mint com ETH:
```
to: [seu endereço]
value: 100000000000000000 (0.1 ETH em wei)
```

---

## 🎯 Checklist de Testes por Etapa

### Etapa 1 ✅
- [ ] `maxSupply()` retorna 1000
- [ ] `saleActive()` retorna true
- [ ] `currentSupply()` retorna 0
- [ ] Owner consegue chamar `setSaleActive(false)`

### Etapa 2 ✅
- [ ] `priceInToken()` retorna 100 * 10^18
- [ ] `priceInETH()` retorna 0.1 ETH
- [ ] Owner consegue atualizar preços
- [ ] Evento `PriceUpdated` é emitido

### Etapa 3 ✅
- [ ] Token foi aprovado antes do mint
- [ ] `mintWithToken()` transfere tokens
- [ ] NFT é mintado corretamente
- [ ] `currentSupply()` aumenta
- [ ] Evento `MintedWithToken` é emitido

### Etapa 4 ✅
- [ ] `mintWithETH()` funciona com valor exato
- [ ] `mintWithETH()` funciona com valor em excesso (reembolso)
- [ ] `mintWithETH()` falha com valor insuficiente
- [ ] Contrato recebe ETH correto
- [ ] Evento `MintedWithETH` é emitido

---

## 💡 Dicas para o Professor

1. **Comece devagar**: Deixe os alunos entenderem cada conceito antes de avançar
2. **Teste cada etapa**: Não avance até todos testarem a etapa atual
3. **Use exemplos práticos**: Explique wei, decimais, approve, etc.
4. **Encoraje perguntas**: Blockchain pode ser confuso para iniciantes
5. **Mostre os erros**: Erros comuns ajudam no aprendizado

---

## 🐛 Erros Comuns e Soluções

### "execution reverted: ERC20: transfer amount exceeds allowance"
**Causa**: Token não foi aprovado  
**Solução**: Chame `approve()` no token antes de `mintWithToken()`

### "execution reverted: Venda nao esta ativa"
**Causa**: `saleActive` está false  
**Solução**: Owner precisa chamar `setSaleActive(true)`

### "execution reverted: Valor insuficiente"
**Causa**: ETH enviado é menor que `priceInETH`  
**Solução**: Envie pelo menos `priceInETH` wei

### "execution reverted: Supply maximo atingido"
**Causa**: Todos os NFTs foram mintados  
**Solução**: Não há solução, precisa aumentar `maxSupply` no contrato

---

## 📚 Glossário Rápido

- **Wei**: Menor unidade de ETH (1 ETH = 10^18 wei)
- **Payable**: Função que pode receber ETH
- **msg.value**: Quantidade de ETH enviada na transação
- **Approve**: Autorizar um contrato a gastar seus tokens
- **transferFrom**: Transferir tokens de uma conta para outra
- **SafeMint**: Mint seguro que verifica se o destinatário pode receber NFTs
- **OnlyOwner**: Modificador que permite apenas ao dono executar
- **NonReentrant**: Previne ataques de reentrância

---

**Bons estudos! 🚀**


