pragma solidity ^0.4.24;

import "./ERC20Mineable.sol";
import "./ERC721Basic.sol";
import "./IMithrilBooster.sol";

/**
 * The BoostableMineableToken contract is a standard ERC20 token with ERC918 mining capabilities
 * and Boostable Virtual artifact capabilities converged. It relies on the ERC20Mineable base contract
 * to supply standardized token, mining behaviour, and implements behaviour to add/remove artifacts to/from
 * it's contract. The mining target and reward is adjusted based upon the installed artifact, allowing
 * installed artifacts to affect underlying mining parameters.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract BoostableMineableToken is ERC20Mineable {

    // address of the underlying booster
	address public boosterAddress;
    
    // list of installed boosters on this mineable contract. Note only one base artifact installed per contract
    mapping (address => uint) public installedBoosters;

    /**
     * Constructor function
     *
     * Initializes contract with a target booster contract address
     *
     * @param _boosterAddress the address of the ERC721 base artifact
     */
    constructor(address _boosterAddress) public {
    	boosterAddress = _boosterAddress;
    }

    /**
     * installBooster function
     *
     * Public function that installs a base booster (Virtual Rig, for example)
     * to this mining contract. Note that there can only be one booster per
     * contract installed.
     *
     * @param _boosterId the artifact id of the base booster
     */
    function installBooster(uint _boosterId) public {
        require(ERC721Basic(boosterAddress).ownerOf(_boosterId) == msg.sender, "Sender is not the owner of artifact [ BoostableMineableToken.installBooster() ]");
        installedBoosters[msg.sender] = _boosterId;
    }

    /**
     * uninstallBooster function
     *
     * Public function that uninstalls the base booster (Virtual Rig, for example)
     * from this mining contract. Note that there can only be one booster per
     * contract installed.
     *
     */
    function uninstallBooster() public {
        delete installedBoosters[msg.sender];
    }

    /**
     * getInstalledBooster function
     *
     * Public view function that returns the id of the installed booster of
     * the sender
     *
     */
    function getInstalledBooster() public view returns (uint) {
        return installedBoosters[msg.sender];
    }

    /**
     * getInstalledBooster function
     *
     * Public view function that returns the id of the installed booster of
     * the sender
     *
     */
    function getInstalledBoosterFor(address _minter) public view returns (uint) {
        return installedBoosters[_minter];
    }

    /**
     * getMiningTarget function
     *
     * Inherits from ERC918 getMiningTarget and additionally returns the difficulty 
     * target depending on the combined virtual hash power of the attached booster,
     * if any.
     *
     */
    function getMiningTarget() public view returns (uint) {
        // check for target booster
        uint boosterId = getInstalledBooster();
        if(boosterId > 0) {
            return IMithrilBooster(boosterAddress).adjustDifficulty(boosterId, miningTarget, adjustmentInterval);
        } else {
            return miningTarget;
        }
    }

    /**
     * _reward function
     *
     * Inherits from ERC918 _reward and additionally adjusts the mint reward
     * depending on the combined virtual accuracy of the attached booster, if
     * any.
     *
     */
    function _reward(address _minter) internal returns (uint amount) {
        // check for reward booster
        uint boosterId = getInstalledBoosterFor(_minter);
        if(boosterId > 0) {
            amount = IMithrilBooster(boosterAddress).adjustReward(boosterId, getMiningReward());
        } else {
        	amount = getMiningReward();
        }

        balances[msg.sender] = balances[msg.sender].add(amount);

        RewardIssued(msg.sender, amount);
        //Cannot mint more tokens than there are
        assert(tokensMinted <= maxSupplyForEra);
    }

    event RewardIssued(address receiver, uint amount);

    /**
     * hash function
     *
     * Inherits from ERC918 hash and additionally adjusts difficulty
     * depending on the combined virtual hash power of the attached booster, if
     * any.
     *
     */
    function hash(uint256 _nonce, address _minter) public returns (bytes32 digest) {
        uint boosterId = getInstalledBooster();
        if(boosterId > 0) {     
            digest = keccak256( abi.encodePacked(challengeNumber, _minter, _nonce) );

            // get the adjusted mining target from the booster
            uint adjustedMiningTarget = IMithrilBooster(boosterAddress).adjustDifficulty(boosterId, miningTarget, adjustmentInterval);

            //the digest must be smaller than the target
            if(uint256(digest) > adjustedMiningTarget) revert();
                        
            //only allow one reward for each challenge
            bytes32 solution = solutionForChallenge[challengeNumber];
            solutionForChallenge[challengeNumber] = digest;
            //prevent the same answer from awarding twice
            if(solution != 0x0) revert();
           
        } else {
            digest = super.hash(_nonce, _minter);
        }
    } 
    
}