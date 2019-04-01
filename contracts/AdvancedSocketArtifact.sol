pragma solidity ^0.4.24;

import "./Owned.sol";
import "./ERC721Token.sol";
import "./StatisticsModifier.sol";

/**
  * The AdvancedSocketArtifact contract
  *
  * author: lodge (https://github.com/jlogelin)
  *
  */
contract AdvancedSocketArtifact is ERC721Token("0xARTIFACT", "Mithril Booster Artifact"), Owned {
    
    struct SocketArtifactStats {
        // Name of artifact
        string name;
        
        // booster parent id
        uint parent;
        
        // StatisticsModifier
        StatisticsModifier artifactModifier;
    }
    
    event MintSocketArtifact(address owner, uint id, string name);
    
    mapping (uint => SocketArtifactStats) artifacts;
    
    function mint(address _owner, string _name, StatisticsModifier _artifactModifier) 
    	public onlyOwner returns (uint _boosterId) 
    {
        _boosterId = totalSupply().add(1);
        
        SocketArtifactStats storage booster = artifacts[_boosterId];
        booster.name = _name;
        booster.artifactModifier = _artifactModifier;
        super._mint(_owner, _boosterId);
        
        emit MintSocketArtifact(_owner, _boosterId, _name);
    }
    
    function merge(uint _id, uint _executionCost, uint _coolDown, uint _reward, uint _target) public 
        returns (uint executionCost, uint coolDown, uint reward, uint target)
    {
        require(ownerOf(_id) == tx.origin, "Sender is not the owner of socketed artifact [ AdvancedSocketArtifact.merge() ]");
        
        executionCost = _executionCost;
        coolDown = _coolDown;
        reward = _reward;
        target = _target;
        
        artifacts[_id].artifactModifier.merge(_executionCost, _coolDown, _reward, _target);

    }

}
