pragma solidity ^0.4.24;

import "./0xTokenBase.sol";
import "./ERC20Interface.sol";
import "./strings.sol";
import "./InitializeOnce.sol";

contract MineableERC20 is _0xTokenBase, InitializeOnce {
  using strings for *;

  string public symbol;
  string public name;
  ERC20Interface erc20Contract;
  address tokenAddress;
  address tokenOwner;
  
  /* 
   * There are 2 different types of deposits, a hard deposit whereby the target tokens are locked within the 
   * MineableERC20 Contract until they are mined. The alternative soft deposit, uses the ERC20 approve() method to 
   * delegate transfer permission to the ERC20 contract from the token owners address. 
  **/
  bool hardDeposit;

  function initialize(
        address _tokenAddress,
        string _tokenSymbol,
        string _tokenName,
        uint8 _tokenDecimals,
        uint _initialReward,
        uint _blocksPerDifficultyAdjustment,
        uint _initialDifficulty,
        uint _blockTimeInMinutes,
        bool _hardDeposit,
        string _metadataURI) 
    public notInitialized {
      tokenOwner = msg.sender;
      hardDeposit = _hardDeposit;
      erc20Contract = ERC20Interface(_tokenAddress);
      uint bal;
      if(hardDeposit){
          bal = erc20Contract.balanceOf(this); // hard deposit - call ERC20.transfer() first
      } else {
          bal = erc20Contract.allowance(msg.sender, this); // soft deposit - call ERC20.approve() first
      }
      require(bal > 0, "Balance must be greater than 0 [ MineableERC20.initialize() ]");
      require(_tokenAddress != address(0), "Invalid token address 0x0 [ MineableERC20.initialize() ]");
      tokenAddress = _tokenAddress;
      symbol = "0x".toSlice().concat(_tokenSymbol.toSlice());      
      name = _tokenName.toSlice().concat(" - 💎 Mineable 0xToken".toSlice());

      super._initialize(bal, _tokenDecimals, _initialReward, _blocksPerDifficultyAdjustment, _initialDifficulty, _blockTimeInMinutes, _metadataURI);
      initialized = true;
  }

  function mint(uint256 nonce) isInitialized public returns (bool success) {
      require(remainingSupply() >= getMiningReward(), "Remaining supply must be greater than reward [ MineableERC20.mint() ]");
      require(msg.sender != address(0x0), "Invalid token address 0x0 [ MineableERC20.mint() ]");
      return super.mint(nonce); 
  }

  function _reward() internal returns (uint) {
      uint amount = getMiningReward();
      if(hardDeposit) {
          erc20Contract.transfer(msg.sender, amount);
      } else {
          erc20Contract.transferFrom(tokenOwner, msg.sender, amount);
      }
      return amount;
  }

  function remainingSupply() public returns (uint){
      if(hardDeposit){
          return erc20Contract.balanceOf(this);
      } else {
          return erc20Contract.allowance(tokenOwner, this);
      }
  }
    
  function balanceOf(address _tokenOwner) public returns (uint balance){
      return erc20Contract.balanceOf(_tokenOwner);
  }
  
}