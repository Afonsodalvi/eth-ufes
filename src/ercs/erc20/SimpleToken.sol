// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleERC20Token {
    string public constant NAME = "SimpleERC20Token";
    string public constant SYMBOL = "SET";
    uint8 public constant DECIMALS = 18;

    uint256 s_totalSupply;

    mapping(address => uint256) s_balances;
    mapping(address => mapping(address => uint256)) s_allowed;

    event SimpleERC20Token_Transfer(address from, address to, uint256 value);
    event SimpleERC20Token_Approval(address owner, address spender, uint256 value);

    error SimpleERC20Token_NotEnoughBalance();

    constructor(uint256 _total) {
        s_totalSupply = _total;
        s_balances[msg.sender] = _total;
    }

    function totalSupply() public view returns (uint256) {
        return s_totalSupply;
    }

    function balanceOf(address _tokenOwner) public view returns (uint256) {
        return s_balances[_tokenOwner];
    }

    function transfer(address _receiver, uint256 _numTokens) public returns (bool) {
        if (_numTokens > s_balances[msg.sender]) revert SimpleERC20Token_NotEnoughBalance();

        s_balances[msg.sender] = s_balances[msg.sender] - _numTokens;
        s_balances[_receiver] = s_balances[_receiver] + _numTokens;

        emit SimpleERC20Token_Transfer(msg.sender, _receiver, _numTokens);

        return true;
    }

    function approve(address _delegate, uint256 _numTokens) public returns (bool) {
        s_allowed[msg.sender][_delegate] = _numTokens;
        emit SimpleERC20Token_Approval(msg.sender, _delegate, _numTokens);
        return true;
    }

    function allowance(address _owner, address _delegate) public view returns (uint256) {
        return s_allowed[_owner][_delegate];
    }

    function transferFrom(address _owner, address _buyer, uint256 _numTokens) public returns (bool) {
        require(_numTokens <= s_balances[_owner]);
        require(_numTokens <= s_allowed[_owner][msg.sender]);

        s_balances[_owner] = s_balances[_owner] - _numTokens;
        s_allowed[_owner][msg.sender] = s_allowed[_owner][msg.sender] - _numTokens;
        s_balances[_buyer] = s_balances[_buyer] + _numTokens;
        emit SimpleERC20Token_Transfer(_owner, _buyer, _numTokens);
        return true;
    }
}
