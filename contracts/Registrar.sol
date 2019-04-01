pragma solidity ^0.4.24;

import "./RBACWithAdmin.sol";

/**
 * The Registrar contract is a registrar for the Mineables network. It holds a listing of all 
 * available Mineable Tokens that have been registered and provides access control to underlying token factories.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract Registrar is RBACWithAdmin {

  string constant ROLE_MINEABLE = "mineable";

  modifier onlyAdminOrMineable()
  {
      require(
        hasRole(msg.sender, ROLE_ADMIN) ||
        hasRole(msg.sender, ROLE_MINEABLE), 
        "Insufficent priviledges to execute this function [ Registrar.onlyAdminOrMineable() ]"
      );
      _;
  }

  /* Mineables Registry Entry */
  struct MineableEntry {
    address mineable;
    uint listPointer;
  }

  mapping(address => MineableEntry) public mineableEntries;
  address[] public mineableKeyList;

  function isMineableEntry(address tokenAddress) public constant returns(bool isIndeed) {
    if(mineableKeyList.length == 0) return false;
    return (mineableKeyList[mineableEntries[tokenAddress].listPointer] == tokenAddress);
  }

  function mineableSize() public constant returns(uint entityCount) {
    return mineableKeyList.length;
  }

  function getMineableTuple(uint index) public constant
    returns(address token, address mineable)
  {
    token = mineableKeyList[index];
    mineable = mineableEntries[token].mineable;
  }

  function getMineable(address tokenAddress)
    public
    constant
    returns(address mineable)
  { 
    require(isMineableEntry(tokenAddress), "Invalid, entry exists [ Registrar.getMineable() ]");
    return mineableEntries[tokenAddress].mineable;
  }

  function getMineableKeyAt(uint index)
    public
    constant
    returns(address token)
  { 
    return mineableKeyList[index];
  }

  function getMineableAt(uint index)
    public
    constant
    returns(address mineable)
  { 
    return mineableEntries[mineableKeyList[index]].mineable;
  }

  function putMineable(address tokenAddress, address mineable) 
    public onlyAdminOrMineable returns(bool success) 
  {
    require(!isMineableEntry(tokenAddress), "Entry already exists [ Registrar.putMineable() ]");
    mineableEntries[tokenAddress].mineable = mineable;
    mineableEntries[tokenAddress].listPointer = mineableKeyList.push(tokenAddress) - 1;
    return true;
  }

  function updateMineable(address tokenAddress, address mineable) 
    public onlyAdmin returns(bool success) 
  {
    require(isMineableEntry(tokenAddress), "Invalid, entry exists [ Registrar.updateMineable() ]");
    mineableEntries[tokenAddress].mineable = mineable;
    return true;
  }

  function removeMineable(address tokenAddress) 
    public onlyAdmin returns(bool success) 
  {
    require(isMineableEntry(tokenAddress), "Invalid, entry exists [ Registrar.removeMineable() ]");
    uint rowToDelete = mineableEntries[tokenAddress].listPointer;
    address keyToMove   = mineableKeyList[mineableKeyList.length-1];
    mineableKeyList[rowToDelete] = keyToMove;
    mineableEntries[keyToMove].listPointer = rowToDelete;
    mineableKeyList.length--;
    return true;
  }

}
