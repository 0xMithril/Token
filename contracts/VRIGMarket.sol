pragma solidity ^0.4.24;

import "./withMapping.sol";
import "./ERC20Interface.sol";
import "./ERC721Basic.sol";

interface VRIG {
    function removeAllChildren(uint _boosterId) external;
    function hasChildren(uint _id) external returns (bool);
}

/**
 * The VRIGMarket contract is a simple marketplace that allows users to
 * buy and sell Virtual Rigs artifacts with a target ERC20 token. 
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract VRIGMarket is withMapping {

    // ERC20 Token used for market transactions
    address public erc20TokenAddress;

    // Mineables VGPU artifact address 
    address public vrigArtifactAddress;

    // Modifier that checks artifact ownership
    modifier onlyArtifactOwner(uint _artifactId) {
      require( ERC721Basic(vrigArtifactAddress).ownerOf(_artifactId) == msg.sender, "Sender is not the owner of artifact [ VRIGMarket.onlyArtifactOwner() ]" );
      _;
    }

    /**
     * Constructor function
     *
     * Initializes contract with an ERC20 token address and the Mineables VRIG ERC721 
     * artifact address.
     *
     * @param _erc20TokenAddress the address of the ERC20 transaction token
     * @param _vrigArtifactAddress the address of the Mineables VRIG ERC721 token
     */
    constructor(address _erc20TokenAddress, 
                address _vrigArtifactAddress) public {
        erc20TokenAddress = _erc20TokenAddress;
        vrigArtifactAddress = _vrigArtifactAddress;
    }

    /**
     * offer function
     *
     * Public function that allows users to offer their VRIGs for sale at 
     * a given price.
     *
     * @param _artifactId the address of the the Mineables VRIG ERC721 token
     * @param _sellPrice the target sale price
     */
    function offer(uint _artifactId, uint _sellPrice) public onlyArtifactOwner(_artifactId) {
        VRIG(vrigArtifactAddress).removeAllChildren(_artifactId);
        add(_artifactId, _sellPrice);
    }
    
    /**
     * revoke function
     *
     * Public function that allows users remove their listed artifact from 
     * the marketplace
     *
     * @param _artifactId the address of the the Mineables VRIG ERC721 token
     */
    function revoke(uint _artifactId) public onlyArtifactOwner(_artifactId) {
        remove(_artifactId);
    }

    event Pre(bytes data);
    event Post(uint _artifactId);

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public {
        emit Pre(data);
        uint _artifactId = bytesToUint(data);
        emit Post(_artifactId);
        
        require( !VRIG(vrigArtifactAddress).hasChildren(_artifactId), "vRig cannot have attached children [ VGPUMarket.receiveApproval() ]" );
        uint price = get(_artifactId);
        address artifactOwner = ERC721Basic(vrigArtifactAddress).ownerOf(_artifactId);
        require( ERC20Interface(erc20TokenAddress).transferFrom(from, artifactOwner, price), "Error transferring tokens from caller [ VRIGMarket.receiveApproval() ]" );
        ERC721Basic(vrigArtifactAddress).transferFrom(artifactOwner, from, _artifactId);
        require( ERC721Basic(vrigArtifactAddress).ownerOf(_artifactId) == from, "Error confirming Artifact transfer [ VRIGMarket.receiveApproval() ]" );
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
     * Public function that allows users to buy a VRIG for sale at 
     * a given price. The user must first call approve() to delegate token
     * transfer to the seller
     *
     * @param _artifactId the address of the the Mineables VRIG ERC721 token
     */
    function buy(uint _artifactId) public {
        require(!VRIG(vrigArtifactAddress).hasChildren(_artifactId), "vRig cannot have attached children [ VGPUMarket.buy() ]");
        uint price = get(_artifactId);
        address artifactOwner = ERC721Basic(vrigArtifactAddress).ownerOf(_artifactId);
        require( ERC20Interface(erc20TokenAddress).transferFrom(msg.sender, artifactOwner, price), "Error transferring tokens from caller [ VRIGMarket.buy() ]" );
        ERC721Basic(vrigArtifactAddress).transferFrom(artifactOwner, msg.sender, _artifactId);
        require( ERC721Basic(vrigArtifactAddress).ownerOf(_artifactId) == msg.sender, "Error confirming Artifact transfer [ VRIGMarket.buy() ]" );
        remove(_artifactId);
    }

}