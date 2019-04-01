pragma solidity ^0.4.24;

import "./AbstractERC918.sol";
import "./SafeMath.sol";
import "./ExtendedMath.sol";
import "./ERC918Metadata.sol";

/**
  * The 0xTokenBase contract implements the EIP918 Mineable Token Standard. The standard requires implementation of an 
  * externally facing mint function that is called by miners to validate challenges, calculate reward,
  * populate statistics, mutate state variables and adjust the solution difficulty as required. Once complete,
  * a Mint event is emitted before returning a success indicator.
  *
  * This contract can be used as a base contract for tokens that want to integrate mineablility into ERC20, ERC721, 
  * ERC777 (and others) tokens by supplying initialization variables such as inital reward, blocks per adjustment,
  * initial difficulty factors, and target block time in minutes.
  *
  * https://eips.ethereum.org/EIPS/eip-918
  *
  * author: lodge (https://github.com/jlogelin)
  *
  */
contract _0xTokenBase is AbstractERC918, ERC918Metadata {
    using SafeMath for uint;
    using ExtendedMath for uint;
    
    uint public MINIMUM_TARGET = 2**16;
    uint public MAXIMUM_TARGET = 2**234;
    uint public MINING_RATE_FACTOR;
    //difficulty adjustment parameters- be careful modifying these
    uint public MAX_ADJUSTMENT_PERCENT = 100;
    uint public TARGET_DIVISOR = 2000;
    uint public QUOTIENT_LIMIT = TARGET_DIVISOR.div(2);
    
    uint8 public decimals;
    uint public latestDifficultyPeriodStarted;
    uint public baseMiningReward;
    uint public rewardEra;
    uint public maxSupplyForEra;
    uint public MAX_REWARD_ERA = 39;

    uint public ETHER_BLOCKS_PER_MINUTE = 6;

    uint public blockTimeInMinutes;

    uint public _totalSupply;
    
    mapping(bytes32 => bytes32) solutionForChallenge;

    // optional metadataURI URI containing ERC918 Token Metadata
    string public metadataURI;

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a mineable asset.
     */
    function metadataURI() external view returns (string) {
        return metadataURI;
    }
    
    event TokenBaseInitialize(uint256 initialSupply,uint8 tokenDecimals,uint initialReward, 
                              uint blocksPerDifficultyAdjustment, uint blockTimeInMinutes);

    /**
     * Don't accept ETH
    */
    function () public payable {
        revert();
    }

     /**
     * Internal initialize function to set up initial values for Mineable Token
     *
     * @param _initialSupply the initial supply of the token
     * @param _tokenDecimals the number of decimal places of the token
     * @param _initialReward the initial reward of the token
     * @param _blocksPerDifficultyAdjustment the number of mint blocks per difficulty adjustment
     * @param _initialDifficulty the initial difficulty of the token
     * @param _blockTimeInMinutes the target block time in minutes of the token
     * @param _metadataURI optional URI containing ERC918 Token Metadata
     *
     */
    function _initialize(uint256 _initialSupply,
        uint8 _tokenDecimals,
        uint _initialReward,
        uint _blocksPerDifficultyAdjustment, 
        uint _initialDifficulty,
        uint _blockTimeInMinutes,
        string _metadataURI) internal {
        decimals = _tokenDecimals;
        _totalSupply = _initialSupply * 10**uint(decimals);
        baseMiningReward = _initialReward;
        blocksPerReadjustment = _blocksPerDifficultyAdjustment;
        metadataURI = _metadataURI;
        // -- do not change lines below --
        tokensMinted = 0;
        rewardEra = 0;
        maxSupplyForEra = _totalSupply.div(2);
        //miningTarget = MAXIMUM_TARGET;
        miningTarget = _initialDifficulty > 0 ? MAXIMUM_TARGET.div(_initialDifficulty) : MAXIMUM_TARGET;
        if(miningTarget > MAXIMUM_TARGET) {
          miningTarget = MAXIMUM_TARGET;
        }
        blockTimeInMinutes = _blockTimeInMinutes;
        MINING_RATE_FACTOR = _blockTimeInMinutes.mul(ETHER_BLOCKS_PER_MINUTE);
        //miningTarget = MAXIMUM_TARGET.div(initialDifficulty);
        latestDifficultyPeriodStarted = block.number;
        emit TokenBaseInitialize(_initialSupply, _tokenDecimals, _initialReward, _blocksPerDifficultyAdjustment, _blockTimeInMinutes);
        _epoch();
    }

    /**
     * ERC918: Public hash function of the mineable token that validates the correct solution nonce against the
     * current mining target. The solution is stored in a local map, to prevent multiple submissions
     *
     * @param _nonce the solution nonce submitted through the mint operation
     * @param _minter the address responsible for resolving the solution
     *
     */
    function hash(uint256 _nonce, address _minter) public returns (bytes32 digest) {
        digest = keccak256( abi.encodePacked(challengeNumber, _minter, _nonce) );
        //the digest must be smaller than the target
        require(uint256(digest) < getMiningTarget(), "Hash larger than the mining target [ 0xTokenBase.hash() ]");
        //only allow one reward for each challenge        
        bytes32 solution = solutionForChallenge[challengeNumber];
        solutionForChallenge[challengeNumber] = digest;
        //prevent the same answer from awarding twice
        require(solution == 0x0, "Solution has already been rewarded [ 0xTokenBase.hash() ]");
    }
    
    /**
     * ERC918: Internal function that performs epoch phase updates to the contract. If max supply for the era will be exceeded next 
     * reward round then assign a new era. Once the final era is reached, more tokens will not be given out and the mint operation
     * will fail to execute.
     * 
     * returns the resulting current epoch count
     */
    function _epoch() internal returns (uint) {
      //uint _totalSupply = totalSupply();

      //if max supply for the era will be exceeded next reward round then enter the new era before that happens
      //40 is the final reward era, almost all tokens minted
      //once the final era is reached, more tokens will not be given out because the assert function
      if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 39){
        rewardEra = rewardEra + 1;
      }
      
      //set the next minted supply at which the era will change
      maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));
      epochCount = epochCount.add(1);

      //make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
      //do this last since this is a protection mechanism in the mint() function
      challengeNumber = blockhash(block.number - 1);
      return epochCount;
    }

    /**
     * ERC918: Internal function that performs difficulty adjustment phase of the mineable contract. Apart from initialization
     * variables 'target time / adjustment' and 'blocks per adjustment', this function generally follows a readjustment
     * target of up to 50% per bitcoin difficulty adjustment algorithm. 
     * 
     * https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
     * 
     * returns the resulting current difficulty
     */
    function _adjustDifficulty() internal returns (uint) {
        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        //assume 360 ethereum blocks per hour
        //we want miners to spend 10 minutes to mine each 'block', about 60 ethereum blocks = one 0xbitcoin epoch
        uint epochsMined = blocksPerReadjustment;
        uint targetEthBlocksPerDiffPeriod = epochsMined * MINING_RATE_FACTOR;
        //if there were less eth blocks passed in time than expected
        if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
        {
          uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(MAX_ADJUSTMENT_PERCENT)).div( ethBlocksSinceLastDifficultyPeriod );
          uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(QUOTIENT_LIMIT);
          // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.
          //make it harder
          miningTarget = miningTarget.sub(miningTarget.div(TARGET_DIVISOR).mul(excess_block_pct_extra));   //by up to 50 %
        }else{
          uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(MAX_ADJUSTMENT_PERCENT)).div( targetEthBlocksPerDiffPeriod );
          uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(QUOTIENT_LIMIT); //always between 0 and 1000
          //make it easier
          miningTarget = miningTarget.add(miningTarget.div(TARGET_DIVISOR).mul(shortage_block_pct_extra));   //by up to 50 %
        }
        latestDifficultyPeriodStarted = block.number;
        if(miningTarget < MINIMUM_TARGET){ //very difficult
          miningTarget = MINIMUM_TARGET;
        }
        if(miningTarget > MAXIMUM_TARGET){ //very easy
          miningTarget = MAXIMUM_TARGET;
        }
    }

    /*
     * ERC918: Returns the time in seconds between difficulty adjustments
     **/
    function getAdjustmentInterval() public view returns (uint) {
        return blockTimeInMinutes.mul(60);
    }
    
    /*
     * ERC918: Returns the challenge number. This is a recent ethereum block hash, 
     * used to prevent pre-mining future blocks
     **/
    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }
    
    /*
     * ERC918: Returns the mining difficulty. The number of digits that the digest of the PoW solution 
     * requires that auto adjusts during reward generation.
     **/
    function getMiningDifficulty() public view returns (uint) {
        return MAXIMUM_TARGET.div(getMiningTarget());
    }

    /*
     * ERC918: Returns the current mining target
     **/
    function getMiningTarget() public view returns (uint) {
       return miningTarget;
    }

    /*
     * ERC918: Return the current reward amount. Depending on the algorithm, 
     * rewards are divided every reward era as tokens are mined to provide scarcity
     **/
    function getMiningReward() public view returns (uint) {
        //once we get half way thru the coins, only get 25 per block
         //every reward era, the reward amount halves.
         return (baseMiningReward * 10**uint(decimals) ).div( 2**rewardEra ) ;
    }
    
}