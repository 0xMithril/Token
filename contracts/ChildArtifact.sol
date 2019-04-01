pragma solidity ^0.4.24;

import "./Owned.sol";
import "./ERC721Token.sol";

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