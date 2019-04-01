pragma solidity ^0.4.24;

import "./withMapping.sol";
import "./ERC20Interface.sol";
import "./ERC721Basic.sol";

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