pragma solidity ^0.4.24;

import "./0xTokenBase.sol";
import "./SafeMath.sol";
import "./ExtendedMath.sol";
import "./Owned.sol";
import "./ERC20Interface.sol";

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallback {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// ERC20Mineable Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract ERC20Mineable is _0xTokenBase, ERC20Interface {
    using SafeMath for uint;
    using ExtendedMath for uint;
    
	string public symbol;
    string public name;

	mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor(string _symbol, string _name, uint8 _decimals, uint supply, uint _reward, 
                uint _adjustmentBlockCount, uint _initialDifficulty, uint _blockTimeInMinutes, string _metadataURI) public {
        symbol = _symbol;
        name = _name;
        super._initialize(supply, _decimals, _reward, _adjustmentBlockCount, _initialDifficulty, _blockTimeInMinutes, _metadataURI);
        
    }

    function transferFromOrigin(address to, uint tokens) public returns (bool success) {
        balances[tx.origin] = balances[tx.origin].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(tx.origin, to, tokens);
        return true;
    }
   
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
   
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
   
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallback(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

}