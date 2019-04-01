pragma solidity ^0.4.24;

import "./VirtualMiningBoard.sol";
import "./ChildArtifact.sol";
import "./ERC20Interface.sol";

contract ArtifactMarket {
    
    /* artifactId and price */
	mapping(uint => uint) public vrigMarket;
    uint public vrigMarketSize;
	
	/* artifactId and price */
	mapping(uint => uint) public vgpuMarket;
    uint public vgpuMarketSize;
	
	address public erc20TokenAddress;

    address public vrigArtifactAddress;
    
    address public vgpuArtifactAddress;
    
    constructor(address _erc20TokenAddress, 
                address _vrigArtifactAddress, 
                address _vgpuArtifactAddress) public {
        erc20TokenAddress = _erc20TokenAddress;
        vrigArtifactAddress = _vrigArtifactAddress;
        vgpuArtifactAddress = _vgpuArtifactAddress;
    }

    function offerVrig(uint _artifactId, uint _sellPriceInMithril) public {
        require( ERC721Basic(vrigArtifactAddress).ownerOf(_artifactId) == msg.sender, "Sender is not the owner of artifact [ ArtifactMarket.offerVrig() ]" );
        VirtualMiningBoard(vrigArtifactAddress).removeAllChildren(_artifactId);
        vrigMarket[_artifactId] = _sellPriceInMithril;
        vrigMarketSize++;
    }
    
    function removeVrigOffer(uint _artifactId) public {
        require( vrigMarket[_artifactId] != 0x0 );
        require( ERC721Basic(vrigArtifactAddress).ownerOf(_artifactId) == msg.sender, "Sender is not the owner of artifact [ ArtifactMarket.removeVrigOffer() ]" );
        delete vrigMarket[_artifactId];
        vrigMarketSize--;
    }

    function buyVrig(uint _artifactId) public {
        uint price = vrigMarket[_artifactId];
        require( vrigMarket[_artifactId] != 0x0, "Artifact with given id does not exist in this market [ ArtifactMarket.buyVrig() ]" );
        address artifactOwner = ERC721Basic(vrigArtifactAddress).ownerOf(_artifactId);
        require( ERC20Interface(erc20TokenAddress).transferFrom(msg.sender, artifactOwner, price), "Failed to transfer tokens from sender to Artifact owner [ ArtifactMarket.buyVrig() ]" );
        ERC721Basic(vrigArtifactAddress).transferFrom(artifactOwner, msg.sender, _artifactId);
        require( ERC721Basic(vrigArtifactAddress).ownerOf(_artifactId) == msg.sender, "Sender has not been assigned owner of this Artifact [ ArtifactMarket.buyVrig() ]" );
        delete vrigMarket[_artifactId];
        vrigMarketSize--;
    }
    
    function offerVgpu(uint _artifactId, uint _sellPriceInMithril) public {
        require( ERC721Basic(vgpuArtifactAddress).ownerOf(_artifactId) == msg.sender, "Sender is not the owner of artifact [ ArtifactMarket.offerVgpu() ]" );
        require( ChildArtifact(vgpuArtifactAddress).getParentArtifact(_artifactId) == 0, "Artifact is attached to a parent [ ArtifactMarket.offerVgpu() ]" );
        vgpuMarket[_artifactId] = _sellPriceInMithril;
        vgpuMarketSize++;
    }
    
    function removeVgpuOffer(uint _artifactId) public {
        require( vgpuMarket[_artifactId] != 0x0, "Artifact is not present in this market [ ArtifactMarket.removeVgpuOffer() ]" );
        require( ERC721Basic(vgpuArtifactAddress).ownerOf(_artifactId) == msg.sender, "Sender is not the owner of artifact [ ArtifactMarket.removeVgpuOffer() ]" );
        delete vgpuMarket[_artifactId];
        vgpuMarketSize--;
    }

    function buyVgpu(uint _artifactId) public {
        uint price = vgpuMarket[_artifactId];
        require( vgpuMarket[_artifactId] != 0x0 );
        address artifactOwner = ERC721Basic(vgpuArtifactAddress).ownerOf(_artifactId);
        require( ERC20Interface(erc20TokenAddress).transferFrom(msg.sender, artifactOwner, price) );
        ERC721Basic(vgpuArtifactAddress).transferFrom(artifactOwner, msg.sender, _artifactId);
        require( ERC721Basic(vgpuArtifactAddress).ownerOf(_artifactId) == msg.sender );
        delete vgpuMarket[_artifactId];
        vgpuMarketSize--;
    }
}