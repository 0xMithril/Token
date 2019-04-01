pragma solidity ^0.4.24;

// File: contracts/withMapping.sol

/**
 * The withMapping contract is designed to add dynamic collection functionality to target contracts.
 * It provides create, update, delete, and collection accessors to underlying entities. This particular
 * implementation requires data to be uint. 
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract withMapping {

    /**
     * EntityStruct structure
     *
     * Structure that contains the data/pointer tuple
     *
     */
    struct EntityStruct {
      uint entityData;
      uint listPointer;
    }

    // mapping of the pointers / entities
    mapping(uint => EntityStruct) public entityStructs;

    // the entity list
    uint[] public entityList;

    /**
     * isEntity function
     *
     * Public view function that checks for the existance of an entity in the list
     *
     * @param entityAddress the entity list pointer
     */
    function isEntity(uint entityAddress) public view returns(bool isIndeed) {
      if(entityList.length == 0) return false;
      return (entityList[entityStructs[entityAddress].listPointer] == entityAddress);
    }

    /**
     * size function
     *
     * Public view function that returns the length of the underlying list
     *
     */
    function size() public view returns(uint entityCount) {
      return entityList.length;
    }

    /**
     * add function
     *
     * Public function adds a new entity to the list
     *
     * @param entityAddress the entity list pointer
     * @param entityData the data to add
     */
    function add(uint entityAddress, uint entityData) internal returns(bool success) {
      // require(!isEntity(entityAddress), "Entity already exists in collection [ withMapping.add() ]");
      entityStructs[entityAddress].entityData = entityData;
      entityStructs[entityAddress].listPointer = entityList.push(entityAddress) - 1;
      return true;
    }

    /**
     * get function
     *
     * Public function that returns an entity at a certain address
     *
     * @param entityAddress the entity list pointer
     */
    function get(uint entityAddress) public view returns(uint) {
    	require(isEntity(entityAddress), "Entity does not exist in collection [ withMapping.get() ]");
      return entityStructs[entityAddress].entityData;
    }

    /**
     * getAt function
     *
     * Public function that returns an entity at a certain index
     *
     * @param index the entity index
     */
    function getAt(uint index) public view
      returns(uint artifactId, uint price)
    {
      artifactId = entityList[index];
      price = entityStructs[artifactId].entityData;
    }

    /**
     * update function
     *
     * Public function that replaces an entities value
     *
     * @param entityAddress the entity list pointer
     * @param entityData the data to update
     */
    function update(uint entityAddress, uint entityData) internal returns(bool success) {
      require(isEntity(entityAddress), "Entity does not exist in collection [ withMapping.update() ]");
      entityStructs[entityAddress].entityData = entityData;
      return true;
    }

    /**
     * remove function
     *
     * Public function that removes an entity from the collection
     *
     * @param entityAddress the entity list pointer
     */
    function remove(uint entityAddress) internal returns(bool success) {
      require(isEntity(entityAddress), "Entity does not exist in collection [ withMapping.remove() ]");
      uint rowToDelete = entityStructs[entityAddress].listPointer;
      uint keyToMove   = entityList[entityList.length-1];
      entityList[rowToDelete] = keyToMove;
      entityStructs[keyToMove].listPointer = rowToDelete;
      entityList.length--;
      return true;
    }

}

// File: contracts/ERC20Interface.sol

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
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

// File: contracts/VGPUMarket.sol

interface VGPU {
    function getParentArtifact(uint _id) external view returns (uint);
}

/**
 * The VGPUMarket contract is a simple marketplace that allows users to
 * buy and sell VGPU artifacts with a target ERC20 token. 
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract VGPUMarket is withMapping {

    // ERC20 Token used for market transactions
    address public erc20TokenAddress;

    // Mineables VGPU artifact address 
    address public vgpuArtifactAddress;

    // Modifier that checks artifact ownership
    modifier onlyArtifactOwner(uint _artifactId) {
      require( ERC721Basic(vgpuArtifactAddress).ownerOf(_artifactId) == msg.sender, "Sender is not the owner of artifact [ VGPUMarket.onlyArtifactOwner() ]" );
      _;
    }

    /**
     * Constructor function
     *
     * Initializes contract with an ERC20 token address and the Mineables VGPU ERC721 
     * artifact address.
     *
     * @param _erc20TokenAddress the address of the ERC20 transaction token
     * @param _vgpuArtifactAddress the address of the Mineables VGPU ERC721 token
     */
    constructor(address _erc20TokenAddress, 
                address _vgpuArtifactAddress) public {
        erc20TokenAddress = _erc20TokenAddress;
        vgpuArtifactAddress = _vgpuArtifactAddress;
    }

    /**
     * offer function
     *
     * Public function that allows users to offer their VGPUs for sale at 
     * a given price.
     *
     * @param _artifactId the address of the the Mineables VGPU ERC721 token
     * @param _sellPrice the target sale price
     */
    function offer(uint _artifactId, uint _sellPrice) public onlyArtifactOwner(_artifactId) {
        require( VGPU(vgpuArtifactAddress).getParentArtifact(_artifactId) == 0, "Artifact is attached to a parent artifact [ VGPUMarket.offer() ]" );
        add(_artifactId, _sellPrice);
    }
    
    /**
     * revoke function
     *
     * Public function that allows users remove their listed artifact from 
     * the marketplace
     *
     * @param _artifactId the address of the the Mineables VGPU ERC721 token
     */
    function revoke(uint _artifactId) public onlyArtifactOwner(_artifactId) {
        remove(_artifactId);
    }

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public {
        uint _artifactId = bytesToUint(data);
        uint price = get(_artifactId);
        address artifactOwner = ERC721Basic(vgpuArtifactAddress).ownerOf(_artifactId);
        require( ERC20Interface(erc20TokenAddress).transferFrom(from, artifactOwner, price), "Token transfer from sender was not successful [ VGPUMarket.receiveApproval() ]" );
        ERC721Basic(vgpuArtifactAddress).transferFrom(artifactOwner, from, _artifactId);
        require( ERC721Basic(vgpuArtifactAddress).ownerOf(_artifactId) == from, "Artifact was not successfully transferred to sender [ VGPUMarket.receiveApproval() ]" );
        remove(_artifactId);
    }

    function bytesToUint(bytes b) private pure returns (uint256){
        uint number;
        for(uint i = 0; i<b.length; i++){
            number = number + uint( b[i])*(2**(8*(b.length-(i+1))) );
        }
        return number;
    }

    /**
     * buy function
     *
     * Public function that allows users to buy a VGPU for sale at 
     * a given price. The user must first call approve() to delegate token
     * transfer to the seller
     *
     * @param _artifactId the address of the the Mineables VGPU ERC721 token
     */
    function buy(uint _artifactId) public {
        uint price = get(_artifactId);
        address artifactOwner = ERC721Basic(vgpuArtifactAddress).ownerOf(_artifactId);
        require( ERC20Interface(erc20TokenAddress).transferFrom(msg.sender, artifactOwner, price), "Token transfer from sender was not successful [ VGPUMarket.buy() ]" );
        ERC721Basic(vgpuArtifactAddress).transferFrom(artifactOwner, msg.sender, _artifactId);
        require( ERC721Basic(vgpuArtifactAddress).ownerOf(_artifactId) == msg.sender, "Artifact was not successfully transferred to sender [ VGPUMarket.buy() ]" );
        remove(_artifactId);
    }

}
