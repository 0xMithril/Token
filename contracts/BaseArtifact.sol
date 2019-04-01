pragma solidity ^0.4.24;

import "./Owned.sol";
import "./ERC721Token.sol";
import "./ChildArtifact.sol";

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