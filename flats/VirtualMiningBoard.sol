pragma solidity ^0.4.24;

// File: contracts/IMithrilBooster.sol

/**
 * The IMithrilBooster contract is an abstract contract that defines behaviour to adjust rewards and difficulty and provide
 * views into various booster statistics: experience, life decrementor value, exeuction cost, socket count, virtual hash rate,
 * and accuracy.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract IMithrilBooster  {

    function adjustReward(uint _tokenId, uint _miningReward) public returns (uint rewardAmount);

    function adjustDifficulty(uint _tokenId, uint _miningTarget, uint _targetIntervalSeconds) public returns (uint adjustedMiningTarget);

    function experience(uint _id) public view returns (uint);

    function lifeDecrementer(uint _id) public view returns (uint);

    function executionCost(uint _id) public view returns (uint);

    function sockets(uint _id) public view returns (uint);

    function vHash(uint _id) public view returns (uint);

    function accuracy(uint _id) public view returns (uint);

    event AdjustReward(uint boosterId, uint adjustedReward);

    event AdjustDifficulty(uint boosterId, uint difficulty, uint adjustedDifficulty);

}

// File: contracts/Owned.sol

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sender is not contract owner [ Owned.onlyOwner() ]");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

// File: contracts/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: contracts/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: contracts/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   *  after a `safetransfer`. This function MAY throw to revert and reject the
   *  transfer. This function MUST use 50,000 gas or less. Return of other
   *  than the magic value MUST result in the transaction being reverted.
   *  Note: the contract address is always the message sender.
   * @param _from The sending address
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
   */
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

// File: contracts/SafeMath.sol

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Invalid requirement c >= a [ SafeMath.add() ]");
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Invalid requirement b <= a [ SafeMath.sub() ]");
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Invalid requirement a == 0 || c / a == b [ SafeMath.mul() ]");
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "Invalid requirement b > 0 [ SafeMath.div() ]");
        c = a / b;
    }

}

// File: contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: contracts/ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existance of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * @dev The zero address indicates there is no approved address.
   * @dev There can only be one approved address per token at a given time.
   * @dev Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for a the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * @dev An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  function transfer(address _to, uint256 _tokenId) public {
    transferFrom(tx.origin, _to, _tokenId);
  }
  
  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * @dev Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * @dev The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// File: contracts/ERC721Token.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {
  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() public view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() public view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * @dev Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * @dev Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * @dev Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

// File: contracts/ChildArtifact.sol

/**
 * The ChildArtifact contract is an ERC721 implementation that represents a Virtual GPU (vGPU) or other virtual device
 * that is capable of mutating statistics of it's parent artifact. It is paired many to one with a BaseArtifact contract. A
 * vRig is a virtual artifact that holds a number of slots for child artifacts, typically Virtual GPUs.
 * A Child Artifact such as a virtual GPU contains statistic modifiers that can be applied to base statistics of its parent,
 * thereby allowing for flexible, configurable artifacts. 
 *
 * For example, a Base Artifact vRig might have 3 child vGPUs that each affect the base hash power statistic. So having
 * a vGPU with 300Mhs, 200Mhs, and 100Mhs, would result in a combined base rig hash power of 600Mhs, that is reflected when
 * applied through a BoostableMineableToken contract.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract ChildArtifact is ERC721Token("0xCHILD", "Mithril Child Artifact"), Owned {
    
    /*
     * Statistics struct containing programmable statistic modifiers
    **/
    struct ChildArtifactStats {
        // Name of artifact
        string name;
        // booster parent id
        uint parent;
        // life of artifact
        uint life;
        // statistic modifiers [op],[value]
        uint[] statisticModifiers;
    }
    
    event MintChildArtifact(address owner, uint id, string name);
    
    // the mapping of artifacts with their paired ChildArtifactStats structs
    mapping (uint => ChildArtifactStats) artifacts;

    /**
     * mint function
     *
     * Creates a new child artifact, assigning an owner, name, life counter and statistics modifiers,
     * and returning a unique artifact identifier. Only the contract owner can mint new artifacts.
     *
     * @param _owner the target owner of the artifact
     * @param _name the name assigned to the target artifact
     * @param _life the life counter assigned to the target artifact
     * @param _statisticModifiers the statistics modifiers of the artifact
     */
    function mint(address _owner, string _name, uint _life, uint[] _statisticModifiers, string _uriMetadata) 
    	public onlyOwner returns (uint _boosterId) {
        _boosterId = totalSupply().add(1);

        ChildArtifactStats storage booster = artifacts[_boosterId];
        booster.name = _name;
        booster.statisticModifiers = _statisticModifiers;
        booster.life = _life;

        super._mint(_owner, _boosterId);
        super._setTokenURI(_boosterId, _uriMetadata);
        
        emit MintChildArtifact(_owner, _boosterId, _name);
    }
    
    /**
     * isChildArtifact function
     *
     * Returns true, indicating that this artifact is intended to be attached to a base parent artifact
     */
    function isChildArtifact() public pure returns (bool) {
		 return true;
	}

    /**
     * decrementLife function
     *
     * Public function that decrements the life counter of a target artifact. Used by parent when performing mint operation.
     *
     * @param _id the id of the artifact
     */
    function decrementLife(uint _id) public returns (uint remainingLife) {
        // TODO RESTORE ME!!
        // require(ownerOf(_id) == tx.origin, , "Sender is not the owner of artifact [ ChildArtifact.decrementLife() ]");
        if(artifacts[_id].life > 0) {
            artifacts[_id].life = artifacts[_id].life.sub(1);
        }
        return artifacts[_id].life;
    }

    /**
     * artifactAt function
     *
     * Public view function that returns all relevent fields of a particular artifact
     *
     * @param _id the id of the artifact
     */
    function artifactAt(uint _id) public view 
        returns(
        string name,
        uint parent,
        uint life,
        uint[] statisticModifiers) {
        name = artifacts[_id].name;
        parent = artifacts[_id].parent;
        life = artifacts[_id].life;
        statisticModifiers = artifacts[_id].statisticModifiers;
    }

    /**
     * statisticModifiers function
     *
     * Public view function that returns the statistics modifiers of a target artifact
     *
     * @param _id the child artifact id
     */
	function statisticModifiers(uint _id) public view 
        returns(uint[] statMods) {
        statMods = artifacts[_id].statisticModifiers;
    }

    /**
     * name function
     *
     * Public view function that returns the name of a target artifact
     *
     * @param _id the child artifact id
     */
	function name(uint _id) public view returns (string) {
        return artifacts[_id].name;
    }

    /**
     * name function
     *
     * Public view function that returns the life counter of a target artifact
     *
     * @param _id the child artifact id
     */
    function life(uint _id) public view returns (uint) {
        return artifacts[_id].life;
    }
    
    /**
     * name function
     *
     * Public view function that returns the parent artifact of a target child artifact
     *
     * @param _id the child artifact id
     */
    function getParentArtifact(uint _id) public view returns (uint) {
        return artifacts[_id].parent;
    }

    /**
     * detach function
     *
     * Public function detaches a child artifact from it's parent
     *
     * @param _id the child artifact id
     */
    function detach(uint _id) public {
        require(ownerOf(_id) == tx.origin, "Sender is not the owner of artifact [ ChildArtifact.detach() ]");
        artifacts[_id].parent = 0;
    }
    
    /**
     * attach function
     *
     * Public function attaches a child artifact to a target parent artifact
     *
     * @param _id the child artifact id
     * @param _parent the parent artifact id
     */
    function attach(uint _id, uint _parent) public {
        require(ownerOf(_id) == tx.origin, "Sender is not the owner of artifact [ ChildArtifact.attach() ]");
        artifacts[_id].parent = _parent;
    }

    /**
     * Parse a modifier tuple
     */
    function parseModifier(uint _id, uint _modifierIdx) 
        public view
        returns (uint target, uint op) 
    {
        uint remain = artifacts[_id].statisticModifiers[_modifierIdx];

        // Modifier
        op = remain % 10 ** 4;
        remain = remain / 10 ** 4;

        // Operation
        target = remain % 10 ** 2;
    }
    
}

// File: contracts/BaseArtifact.sol

/**
 * The BaseArtifact contract is an ERC721 implementation that represents a Virtual Mining Rig (vRig). A
 * vRig is a virtual artifact that holds a number of slots for child artifacts, typically Virtual GPUs. It
 * is paired 0 to many with ChildArtifact contract instances. The vRig exposes behavior for owners to configure 
 * by adding/removing child artifacts, whereby a sourced set of statistics and underlying merged statistics 
 * are maintained base upon artifact combinations.
 *
 * For example, a Base Artifact vRig might have 3 child vGPUs that each affect the base hash power statistic. So having
 * a vGPU with 300Mhs, 200Mhs, and 100Mhs, would result in a combined base rig hash power of 600Mhs, that is reflected when
 * applied through a BoostableMineableToken contract.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract BaseArtifact is ERC721Token, Owned {
    
    /*
     * Statistics struct that holds references to child artifacts
    **/
    struct BaseArtifactStats {        
        // Name of booster
        string name;

        // socket artifact token ids
        uint[] childArtifacts;

        // base statistics
        uint[] statistics;

        // combined statistics with child artifacts
        uint[] mergedStatistics;
    }
    
    // Mapping of artifact statistics
    mapping (uint => BaseArtifactStats) boosters;

    // contract address of child artifact. Cardinality: 1 -> n
    address public childArtifactAddress;

    // events
    event MintBaseArtifact(address owner, uint tokenId, string name, uint[] statistics);

    event AddChildArtifact(uint boosterId, uint artifactId);

    event RemoveChildArtifact(uint boosterId, uint artifactId);

    /**
     * Constructor function
     *
     * Initializes contract with a symbol, name and child artifact address
     *
     * @param _childArtifactAddress the address of the child artifact
     * @param _symbol the symbol of the artifact (ie. vGPU)
     * @param _name the long name of the artifact (ie. Virtual GPU)
     */
    constructor(address _childArtifactAddress, string _symbol, string _name) 
        ERC721Token(_symbol, _name)
        public 
    {
        childArtifactAddress = _childArtifactAddress;
    }

    /* detach child artifacts first, then transfer */
    function transfer(address _to, uint256 _tokenId) public {
        removeAllChildren(_tokenId);
        super.transfer(_to, _tokenId);
    }
    
    /**
     * mint function
     *
     * Creates a new base artifact, assigning an owner, name and initial statistics,
     * and returning a unique artifact identifier. Only the contract owner can mint new artifacts.
     *
     * @param _owner the target owner of the artifact
     * @param _name the name assigned to the target artifact
     * @param _statistics the initial statistics of the artifact
     */
    function mint(address _owner, string _name, uint[] _statistics, string _uriMetadata) 
    	public onlyOwner returns (uint _boosterId) 
    {
        _boosterId = totalSupply().add(1);
        
        BaseArtifactStats storage booster = boosters[_boosterId];
        booster.name = _name;
        booster.statistics = _statistics;
        booster.mergedStatistics = _statistics;

        super._mint(_owner, _boosterId);
        super._setTokenURI(_boosterId, _uriMetadata);
        
        emit MintBaseArtifact(_owner, _boosterId, _name, _statistics);
    }

    /**
     * _checkDuplicateChild function
     *
     * Internal function that validates that a child artifact is not already attached to the 
     * parent artifact,
     *
     * returns a boolean flag indicating if child artifact is already attached
     *
     * @param _boosterId the base artifact id
     * @param _artifactId the child artifact id
     */
    function _checkDuplicateChild(uint _boosterId, uint _artifactId) internal view returns (bool){
        require(ownerOf(_boosterId) == tx.origin, "Sender is not the owner of artifact [ BaseArtifact._checkDuplicateChild() ]");
        for (uint i = 0; i < boosters[_boosterId].childArtifacts.length; i++){
            if(boosters[_boosterId].childArtifacts[i] == _artifactId) {
                return true;
            }
        }
        return false;
    }

     /**
     * _safeAddChild function
     *
     * Internal function that adds a child artifact to this base artifact
     *
     * @param _boosterId the base artifact id
     * @param _artifactId the child artifact id
     */
    function _safeAddChild(uint _boosterId, uint _artifactId) internal {
        require(!_checkDuplicateChild(_boosterId, _artifactId), "Sender is not the owner of artifact [ BaseArtifact._safeAddChild() ]");
        boosters[_boosterId].childArtifacts.push(_artifactId);
        ChildArtifact(childArtifactAddress).attach(_artifactId, _boosterId);
    }

    /**
     * configureChildren function
     *
     * Public function that allows the owner of a base artifact to reconfigure
     * it's children. The function will remove all existing children, add the new
     * child configuration and merge the base statistics to reflect the changes.
     *
     * @param _boosterId the base artifact id
     * @param _children array of child artifact ids
     */
    function configureChildren(uint _boosterId, uint[] _children) public {
        require(ownerOf(_boosterId) == tx.origin, "Sender is not the owner of artifact [ BaseArtifact.configureChildren() ]");
        // delete boosters[_boosterId].childArtifacts;
        removeAllChildren(_boosterId);

        for(uint i; i < _children.length; i++) {
           _safeAddChild(_boosterId, _children[i]);
        }

        // merge the new stats
        merge(_boosterId);
    }

    /**
     * addChildArtifact function
     *
     * Public function that allows the owner of a base artifact to add a single
     * child artifact to it's existing configuration.
     *
     * @param _boosterId the base artifact id
     * @param _artifactId the child artifact id
     */
    function addChildArtifact(uint _boosterId, uint _artifactId) public {
		require(ownerOf(_boosterId) == tx.origin, "Sender is not the owner of artifact [ BaseArtifact.addChildArtifact() ]");
		ChildArtifact artifact = ChildArtifact(childArtifactAddress);

		// ensure there is no parent
		require(artifact.getParentArtifact(_artifactId) == 0);
        _safeAddChild(_boosterId, _artifactId);

        // merge the new stats
        merge(_boosterId);

        emit AddChildArtifact(_boosterId, _artifactId);
	}

    /**
     * removeChildArtifact function
     *
     * Public function that allows the owner to remove an artifact at a particular
     * position
     *
     * @param _boosterId the base artifact id
     * @param _index the array position of the artifact
     */
    function removeChildArtifact(uint _boosterId, uint _index) public {
        require(ownerOf(_boosterId) == tx.origin, "Sender is not the owner of artifact [ BaseArtifact.removeChildArtifact() ]");

        if (_index >= boosters[_boosterId].childArtifacts.length) return;

        ChildArtifact(childArtifactAddress).detach(boosters[_boosterId].childArtifacts[_index]);

        for (uint i = _index; i < boosters[_boosterId].childArtifacts.length - 1; i++){
            boosters[_boosterId].childArtifacts[i] = boosters[_boosterId].childArtifacts[i+1];
        }
        // uint targetId = boosters[_boosterId].childArtifacts[boosters[_boosterId].childArtifacts.length-1];
        delete boosters[_boosterId].childArtifacts[boosters[_boosterId].childArtifacts.length-1];
        boosters[_boosterId].childArtifacts.length--;

        // merge the new stats
        merge(_boosterId);

        emit RemoveChildArtifact(_boosterId, _index);

    }

    /**
     * removeAllChildren function
     *
     * Public function that allows the owner to remove add child artifacts from it's
     * base artifact
     *
     * @param _boosterId the base artifact id
     */
    function removeAllChildren(uint _boosterId) public {
        require(ownerOf(_boosterId) == tx.origin, "Sender is not the owner of artifact [ BaseArtifact.removeAllChildren() ]");

        if (boosters[_boosterId].childArtifacts.length <= 0) return;

        for (uint i = 0; i < boosters[_boosterId].childArtifacts.length; i++) {
            uint childId = boosters[_boosterId].childArtifacts[i];
         //   delete boosters[_boosterId].childArtifacts[i];
            ChildArtifact(childArtifactAddress).detach(childId);
            emit RemoveChildArtifact(_boosterId, childId);
        }
        boosters[_boosterId].childArtifacts.length = 0;

        // reset stats
        boosters[_boosterId].mergedStatistics = boosters[_boosterId].statistics;
    }
    

    /**
     * baseStats function
     *
     * Public view function that returns the base statistics of a target artifact
     *
     * @param _id the base artifact id
     */
    function baseStats(uint _id) view public returns (string, uint[], uint[]) {
        return (boosters[_id].name, boosters[_id].statistics, boosters[_id].childArtifacts );
    }

    /**
     * mergedStats function
     *
     * Public view function that returns the calculated merged statistics of a target artifact after applying
     * all statistics of underlying child artifacts
     *
     * @param _id the base artifact id
     */
    function mergedStats(uint _id) view public returns (string, uint[], uint[]) {
        return (boosters[_id].name, boosters[_id].mergedStatistics, boosters[_id].childArtifacts );
    }

    /**
     * name function
     *
     * Public view function that returns a target artifact's name
     *
     * @param _id the base artifact id
     */
    function name(uint _id) public view returns (string) {
        return boosters[_id].name;
    }

    /**
     * childArtifacts function
     *
     * Public view function that returns a target child artifacts array
     *
     * @param _id the base artifact id
     */
    function childArtifacts(uint _id) public view returns (uint[]) {
        return boosters[_id].childArtifacts;
    }

    /**
     * hasChildren function
     *
     * Public view function that checks if an artifact has child artifacts
     *
     * @param _id the base artifact id
     */
    function hasChildren(uint _id) public view returns (bool) {
        return childArtifacts(_id).length > 0;
    }

    /**
     * checkMerged function
     *
     * Public view function that checks the merged statistics of a base artifact with a list
     * of potential child artifacts, returning the resulting statistics
     *
     * @param _id the base artifact id
     * @param _childArtifacts the child artifacts to apply to the base artifact
     */
    function checkMerged(uint _id, uint[] _childArtifacts) public view returns (uint [] statistics) {
        statistics = boosters[_id].statistics;

        uint len = _childArtifacts.length;
        for (uint i = 0; i < len; i++) {
            statistics = mergeArtifact(_childArtifacts[i], statistics);
        }
    }
    
    /**
     * merge function
     *
     * Internal function that merges the statistics of child artifacts into the base merged statistics
     * array.
     *
     * @param _id the base artifact id
     */
    function merge(uint _id) internal returns (uint [] statistics) {

        statistics = boosters[_id].statistics;
      
        uint len = boosters[_id].childArtifacts.length;
        for (uint i = 0; i < len; i++) {
            statistics = mergeArtifact(boosters[_id].childArtifacts[i], statistics);
        }
        // actually modify the statistics
        boosters[_id].mergedStatistics = statistics;

    }

    /**
     * mergeArtifact function
     *
     * Internal function that merges the statistics of a single child artifact, returning
     * the resulting merged statistics array
     *
     * @param _childId the child artifact id
     * @param _statistics the initial statistics array to merge with
     */
    function mergeArtifact(uint _childId, uint[] _statistics) internal view 
        returns (uint [] statistics)
    {
        uint[] memory statisticModifiers = ChildArtifact(childArtifactAddress).statisticModifiers(_childId);

        // loop through statisticModifiers
        for (uint i = 0; i < statisticModifiers.length; i++) {
            uint idx; uint op;
            (idx, op) = parseOp(statisticModifiers[i]);
            _statistics[idx] = operate(_statistics[idx], op);
        }

        statistics = _statistics;
    }

    /**
     * operate function
     *
     * Internal function that performs an operation on a target statistic.
     *
     * @param _target the target statistic to perform the operation on
     * @param _mod the modifier/operation tuple
     *
     * Operations:
     *       1 - add
     *       2 - substract
     *       3 - multiply
     *       4 - divide
     *       5 - add percentage to
     *       6 - subtract percentage from
     *       7 - require greater than
     *       8 - require less than
     *       9 - add exp value -> 808 = 8 * 10^8 = 800000000
     *                         -> 420 = 4 * 10^20
     *                         -> 700 = 7 * 10^0 = 7
     *       examples:
     *           1009 -> 1, 009: add 9
     *           5312 -> 5, 312: add 312%
     *           6075 -> 1, 075: substract 75%
     *           7100 -> 7, 100: require greater than 100
     */
    function operate(uint _target, uint _mod) internal returns (uint256 result) {
        uint modifierValue;
        uint operation;
        (modifierValue, operation) = parseModifier(_mod);

        if(operation == 1) {
            result = _target.add(modifierValue);
        } else if (operation == 2) {
            result = _target.sub(modifierValue);
        } else if (operation == 3) {
            result = _target.mul(modifierValue);
        } else if (operation == 4) {
            result = _target.div(modifierValue);
        } else if (operation == 5) {
            result = _target.add(_target.mul(modifierValue).div(100));
        } else if (operation == 6) {
            result = _target.sub(_target.mul(modifierValue).div(100));
        } else if (operation == 7) {
            require(_target > modifierValue, "Op 7: target is greater than modifier value [ BaseArtifact.operate() ]");
            result = _target;
        } else if (operation == 8) {
            require(_target < modifierValue, "Op 8: target is less than modifier value [ BaseArtifact.operate() ]");
            result = _target;
        }else if (operation == 9) {
            uint multiplier;
            uint exp;
            ( multiplier, exp) = parseBigNum(modifierValue);
            result = _target.add(multiplier * 10 ** exp);
        } else {
            result = _target;
        }
    }

    /**
     * Parse an exponential number tuple
     */
    function parseBigNum(uint num) public pure returns (uint multiplier, uint exp) {
        uint remain = num;

        exp = remain % 10 ** 2;
        remain = remain / 10 ** 2;
        
        multiplier = remain % 10 ** 1;
    }

    /**
     * Parse an operation tuple
     */
    function parseOp(uint num) public pure returns (uint target, uint op ) {
        uint remain = num;
        // Modifier
        op = remain % 10 ** 4;
        remain = remain / 10 ** 4;
        
        // Operation
        target = remain % 10 ** 2;
    }

    /**
     * Parse a modifier tuple
     */
    function parseModifier(uint num) internal pure returns (uint modifierValue, uint operation) {
        uint remain = num;
        // Modifier
        modifierValue = remain % 10 ** 3;
        remain = remain / 10 ** 3;
        
        // Operation
        operation = remain % 10 ** 1;
    }

}

// File: contracts/VirtualMiningBoard.sol

/*
 * The VirtualMiningBoard contract represents a Virtual Mining Board Device use to affect minting statistics
 * for Mineables tokens. It encasulates the following minimum statistics:
 *
 *      [0]: experience ( total alltime nubmer of successful mintings )
 *		[1]: lifeDecrement ( defaulted to 1, this can optionally be increased in 'virtual overclocking' scenarios)
 *		[2]: executionCost (additional cost in Mithril)
 *      [3]: sockets ( # of slots for adding vGPUs or other components )
 *      [4]: vHash ( the combined current Virtual Hashing power, default to 0 )
 *      [5]: accuracy ( total reward as a percent default to 100 )
 *      [6]: level
 *
 **/
contract VirtualMiningBoard is BaseArtifact, IMithrilBooster {
	using SafeMath for uint;

	uint MAXIMUM_TARGET = 2**234;

    uint CEILING = 2**256-1;

    modifier onlyTokenOwner(uint _tokenId){
      require(ownerOf(_tokenId) == tx.origin, "Sender is not the owner of token [ VirtualMiningBoard.onlyTokenOwner() ]");
      _;
    }
 
    /**
     * Constructor function
     *
     * Initializes contract with a child artifact address, a symbol, and a name
     *
     * @param _childArtifactAddress the address of the Mineables ERC721 child artifact
     * @param _symbol the symbol of this token contract
     * @param _name the name of this token contract
     */
    constructor(address _childArtifactAddress, string _symbol, string _name) 
    	BaseArtifact(_childArtifactAddress, _symbol, _name)
    	public { }

    /**
     * mint function
     *
     * Creates a Virtual Mining Board artifact, assigning an owner, name and initial statistics,
     * and returning a unique artifact identifier. Only the contract owner can mint new artifacts.
     *
     * @param _owner the target owner of the artifact
     * @param _name the name assigned to the target artifact
     * @param _statistics the initial statistics of the artifact
     */
    function mint(address _owner, string _name, uint[] _statistics, string _uriMetadata) 
        public onlyOwner returns (uint _boosterId) 
    {
        // minimum base statistics
        require(_statistics.length >= 7, "Must be a minimum of 7 statistics to mint a new base artifact [ VirtualMiningBoard.mint() ]");
        _boosterId = super.mint(_owner, _name, _statistics, _uriMetadata);
    }

    /**
     * addChildArtifact function
     *
     * Public protected function that allows the owner of a base artifact to add a single
     * child artifact to it's existing configuration, validating that there are
     * enough available sockets.
     *
     * @param _boosterId the base artifact id
     * @param _artifactId the child artifact id
     */
    function addChildArtifact(uint _boosterId, uint _artifactId) 
        public 
        onlyTokenOwner(_boosterId) {
        // ensure there are enough slots
        require(boosters[_boosterId].childArtifacts.length < sockets(_boosterId), "Not enough socket space to add child artifact [ VirtualMiningBoard.addChildArtifact() ]" );
        super.addChildArtifact(_boosterId, _artifactId);
    }

    /**
     * adjustDifficulty function
     *
     * Public protected function that allows the owner of a base artifact to adjust the difficulty
     * of a mining target based upon calculating the adjusted virtual hashrate of the artifact with
     * all of it's socketed items.
     *
     * @param _tokenId the base artifact id
     * @param _miningTarget the mining difficulty target
     */
    function adjustDifficulty(uint _tokenId, uint _miningTarget, uint _targetIntervalSeconds) 
    	public 
    	onlyTokenOwner(_tokenId)
		returns (uint adjustedMiningTarget) {

        uint difficulty = uint(2**234).div(_miningTarget);
    	uint virtualHashrate = vHash(_tokenId);
        uint alpha = uint(2**22).mul(difficulty);
        uint beta = uint(_targetIntervalSeconds).mul(virtualHashrate);

        if(beta > alpha) {
            adjustedMiningTarget = MAXIMUM_TARGET;
            emit AdjustDifficulty(_tokenId, _miningTarget, adjustedMiningTarget);
            cycle(_tokenId);
            return adjustedMiningTarget;
        }
        
        uint denominator = alpha.sub(beta);
        if(denominator < CEILING) {
            adjustedMiningTarget = CEILING.div( denominator );
            if(adjustedMiningTarget > MAXIMUM_TARGET){
                adjustedMiningTarget = MAXIMUM_TARGET;
            }
        } else {
            adjustedMiningTarget = MAXIMUM_TARGET;
        }

        emit AdjustDifficulty(_tokenId, _miningTarget, adjustedMiningTarget);
        cycle(_tokenId);
        
    }

    /**
     * adjustDifficulty function
     *
     * Public protected function that allows the owner of a base artifact to adjust the block reward
     * of a minable based upon calculating the adjusted virtual accuracy of the artifact with
     * all of it's socketed items.
     *
     * @param _tokenId the base artifact id
     * @param _miningReward the mining reward
     */
    function adjustReward(uint _tokenId, uint _miningReward) 
        public 
        // TODO RESTORE ME
        //onlyTokenOwner(_tokenId)
        returns (uint adjustedReward) {

        uint acc = accuracy(_tokenId);
        adjustedReward = _miningReward.mul(acc).div(100);
        // only cycle if the mining reward was updated
        if(adjustedReward != _miningReward) {
            cycle(_tokenId);
            emit AdjustReward(_tokenId, adjustedReward);
        }

    }

    /**
     * cycle function
     *
     * Internal function that cycles this artifact upon a successful mint transaction.
     *
     * @param _id the base artifact id
     */
    function cycle(uint _id) internal {
		// +1 to exp
		boosters[_id].mergedStatistics[0].add(1);

        uint len = childArtifacts(_id).length;
        uint [] memory toDelete = new uint[](len);
        uint count = 0;
        for (uint i = 0; i < len; i++) {
            uint remainingLife = ChildArtifact(childArtifactAddress).decrementLife( childArtifacts(_id)[i] );
            if(remainingLife == 0) {
                toDelete[count++] = i;
            }
        }

        for (uint j = 0; j < count; j++) {
            removeChildArtifact(_id, toDelete[j]);
        }

    }

    /**
     * experience function
     *
     * Public view function that returns a target artifact's experience
     *
     * @param _id the base artifact id
     */
 	function experience(uint _id) public view returns (uint) {
    	return boosters[_id].mergedStatistics[0];
    }

    /**
     * lifeDecrementer function
     *
     * Public view function that returns a target artifact's life decrementer
     *
     * @param _id the base artifact id
     */
    function lifeDecrementer(uint _id) public view returns (uint) {
    	return boosters[_id].mergedStatistics[1];
    }

    /**
     * executionCost function
     *
     * Public view function that returns a target artifact's execution cost
     *
     * @param _id the base artifact id
     */
    function executionCost(uint _id) public view returns (uint) {
    	return boosters[_id].mergedStatistics[2];
    }

    /**
     * sockets function
     *
     * Public view function that returns a target artifact's socket count
     *
     * @param _id the base artifact id
     */
    function sockets(uint _id) public view returns (uint) {
    	return boosters[_id].mergedStatistics[3];
    }

    /**
     * vHash function
     *
     * Public view function that returns a target artifact's Virtual Hash Rate
     *
     * @param _id the base artifact id
     */
    function vHash(uint _id) public view returns (uint) {
    	return boosters[_id].mergedStatistics[4];
    }

    /**
     * accuracy function
     *
     * Public view function that returns a target artifact's accuracy
     *
     * @param _id the base artifact id
     */
    function accuracy(uint _id) public view returns (uint) {
    	return boosters[_id].mergedStatistics[5];
    }

    /**
     * level function
     *
     * Public view function that returns a target artifact's level
     *
     * @param _id the base artifact id
     */
    function level(uint _id) public view returns (uint) {
        return boosters[_id].mergedStatistics[6];
    }

}
