pragma solidity ^0.4.24;

import "./IMithrilBooster.sol";
import "./BaseArtifact.sol";

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