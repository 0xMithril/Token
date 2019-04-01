pragma solidity ^0.4.24;

// File: contracts/ERC918.sol

contract ERC918  {

    /*
     * @notice Externally facing mint function that is called by miners to validate challenge digests, calculate reward,
     * populate statistics, mutate epoch variables and adjust the solution difficulty as required. Once complete,
     * a Mint event is emitted before returning a success indicator.
     * @param _nonce the solution nonce
     **/
  	function mint(uint256 nonce) public returns (bool success);

    /*
     * Returns the time in seconds between difficulty adjustments
     **/
    function getAdjustmentInterval() public view returns (uint);

	/*
     * Returns the challenge number
     **/
    function getChallengeNumber() public view returns (bytes32);

    /*
     * Returns the mining difficulty. The number of digits that the digest of the PoW solution requires which 
     * typically auto adjusts during reward generation.
     **/
    function getMiningDifficulty() public view returns (uint);

    /*
     * Returns the mining target
     **/
    function getMiningTarget() public view returns (uint);

    /*
     * Return the current reward amount. Depending on the algorithm, typically rewards are divided every reward era 
     * as tokens are mined to provide scarcity
     **/
    function getMiningReward() public view returns (uint);

    /*
     * Public hash function of the mineable token that validates the correct solution nonce against the
     * current mining target. The solution is stored in a local map, to prevent multiple submissions
     *
     * @param _nonce the solution nonce submitted through the mint operation
     * @param _minter the address responsible for resolving the solution
     **/
    function hash(uint256 _nonce, address _minter) public returns (bytes32 digest);
    
    /**
     * Internal function that performs difficulty adjustment phase of the mineable contract.
     * Returns the resulting current difficulty
     */
    function _reward(address _minter) internal returns (uint);
    
    /**
     * Internal function that performs epoch phase updates to the contract. If max supply for the era will be exceeded next 
     * reward round then assign a new era. Once the final era is reached, more tokens will not be given out and the mint operation
     * will fail to execute.
     * 
     * returns the resulting current epoch count
     */
    function _epoch() internal returns (uint);
    
    /*
     * Internal interface function _adjustDifficulty. Overide in implementation to adjust the difficulty
     * of the mining as required
     **/
    function _adjustDifficulty() internal returns (uint);
    
    /*
     * Upon successful verification and reward the mint method dispatches a Mint Event indicating the reward address, 
     * the reward amount, the epoch count and newest challenge number.
     **/
    event Mint(address indexed from, uint rewardAmount, uint epochCount, bytes32 newChallengeNumber);

}

// File: contracts/ECDSA.sol

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

contract ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes signature)
    public
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    public
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

// File: contracts/AbstractERC918.sol

/**
 * ERC Draft Token Standard #918 Interface
 * Proof of Work Mineable Token
 *
 * This Abstract contract describes a minimal set of behaviors (hash, reward, epoch, and difficulty adjustment) 
 * and state required to build a Proof of Work driven mineable token.
 * 
 * http://eips.ethereum.org/EIPS/eip-918
 */
 contract AbstractERC918 is ERC918, ECDSA {

    // the amount of time between difficulty adjustments
    uint public adjustmentInterval = 10 minutes;
     
    // generate a new challenge number after a new reward is minted
    bytes32 public challengeNumber;
    
    // the current mining target
    uint public miningTarget;

    // cumulative counter of the total minted tokens
    uint public tokensMinted;

    // number of blocks per difficulty readjustment
    uint public blocksPerReadjustment;

    // number of 'blocks' mined
    uint public epochCount;
   
    /*
     * @notice Externally facing mint function that is called by miners to validate challenge digests, calculate reward,
     * populate statistics, mutate epoch variables and adjust the solution difficulty as required. Once complete,
     * a Mint event is emitted before returning a success indicator.
     * @param _nonce the solution nonce
     **/
    function mint(uint256 _nonce) public returns (bool success) {
        success = mintInternal(_nonce, msg.sender);
    }

    /*
     * @notice Internal mint function that is called by miners to validate challenge digests, calculate reward,
     * populate statistics, mutate epoch variables and adjust the solution difficulty as required. Once complete,
     * a Mint event is emitted before returning a success indicator.
     * @param _nonce the solution nonce
     * @param _minter the original minter of the solution
     **/
    function mintInternal(uint256 _nonce, address _minter) internal returns (bool success) {
        require(_minter != address(0), "Invalid address of 0x0 [ AbstractERC918.mintInternal() ]");

        // perform the hash function validation
        hash(_nonce, _minter);
        
        // calculate the current reward
        uint rewardAmount = _reward(_minter);
        
        // increment the minted tokens amount
        tokensMinted += rewardAmount;
        
        // increment state variables of current and new epoch
        epochCount = _epoch();

        //every so often, readjust difficulty. Dont readjust when deploying
        if(epochCount % blocksPerReadjustment == 0){
            _adjustDifficulty();
        }
       
        // send Mint event indicating a successful implementation
        emit Mint(_minter, rewardAmount, epochCount, challengeNumber);
        
        return true;
    }

    /*
     * @notice Externally facing mint function kept for backwards compatability with previous mineables definition
     * @param _nonce the solution nonce
     * @param _challenge_digest the keccak256 encoded challenge number + message sender + solution nonce
     **/
    function mint(uint256 _nonce, bytes32 _challenge_digest) public returns (bool success) {
        //the challenge digest must match the expected
        bytes32 digest = keccak256( abi.encodePacked(challengeNumber, msg.sender, _nonce) );
        require(digest == _challenge_digest, "Challenge digest does not match expected digest on token contract [ AbstractERC918.mint() ]");
        success = mint(_nonce);
    }

    /**
     * @notice Hash (keccak256) of the payload used by delegatedMint
     * @param _nonce the golden nonce
     * @param _origin the original minter
     * @param _signature the original minter's eliptical curve signature
     */
    function delegatedMint(uint256 _nonce, address _origin, bytes _signature) public returns (bool success) {
        bytes32 hashedTx = delegatedMintHashing(_nonce, _origin);
        address minter = recover(hashedTx, _signature);
        require(minter == _origin, "Origin minter address does not match recovered signature address [ AbstractERC918.delegatedMint() ]");
        require(minter != address(0), "Invalid minter address recovered from signature [ AbstractERC918.delegatedMint() ]");
        success = mintInternal(_nonce, minter);
    }

    /**
     * @notice Hash (keccak256) of the payload used by delegatedMint
     * @param _nonce the golden nonce
     * @param _origin the original minter
     */
    function delegatedMintHashing(uint256 _nonce, address _origin) public pure returns (bytes32) {
        /* "0x7b36737a": delegatedMintHashing(uint256,address) */
        return toEthSignedMessageHash(keccak256(abi.encodePacked( bytes4(0x7b36737a), _nonce, _origin)));
    }

}

// File: contracts/SafeMath.sol

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Invalid requirement c >= a [ SafeMath.add() ]");
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Invalid requirement b <= a [ SafeMath.sub() ]");
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Invalid requirement a == 0 || c / a == b [ SafeMath.mul() ]");
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "Invalid requirement b > 0 [ SafeMath.div() ]");
        c = a / b;
    }

}

// File: contracts/ExtendedMath.sol

library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}

// File: contracts/ERC918Metadata.sol

/**
 * @title ERC-918 Mineable Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-918.md
 * 
 * http://eips.ethereum.org/EIPS/eip-918
 */
interface ERC918Metadata {
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a mineable asset.
     */
    function metadataURI() external view returns (string);
}

// File: contracts/0xTokenBase.sol

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

// File: contracts/Owned.sol

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sender is not contract owner [ Owned.onlyOwner() ]");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
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

// File: contracts/ERC20Mineable.sol

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallback {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// ERC20Mineable Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract ERC20Mineable is _0xTokenBase, ERC20Interface {
    using SafeMath for uint;
    using ExtendedMath for uint;
    
	string public symbol;
    string public name;

	mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor(string _symbol, string _name, uint8 _decimals, uint supply, uint _reward, 
                uint _adjustmentBlockCount, uint _initialDifficulty, uint _blockTimeInMinutes, string _metadataURI) public {
        symbol = _symbol;
        name = _name;
        super._initialize(supply, _decimals, _reward, _adjustmentBlockCount, _initialDifficulty, _blockTimeInMinutes, _metadataURI);
        
    }

    function transferFromOrigin(address to, uint tokens) public returns (bool success) {
        balances[tx.origin] = balances[tx.origin].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(tx.origin, to, tokens);
        return true;
    }
   
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
   
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
   
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallback(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

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

// File: contracts/IMithrilBooster.sol

/**
 * The IMithrilBooster contract is an abstract contract that defines behaviour to adjust rewards and difficulty and provide
 * views into various booster statistics: experience, life decrementor value, exeuction cost, socket count, virtual hash rate,
 * and accuracy.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract IMithrilBooster  {

    function adjustReward(uint _tokenId, uint _miningReward) public returns (uint rewardAmount);

    function adjustDifficulty(uint _tokenId, uint _miningTarget, uint _targetIntervalSeconds) public returns (uint adjustedMiningTarget);

    function experience(uint _id) public view returns (uint);

    function lifeDecrementer(uint _id) public view returns (uint);

    function executionCost(uint _id) public view returns (uint);

    function sockets(uint _id) public view returns (uint);

    function vHash(uint _id) public view returns (uint);

    function accuracy(uint _id) public view returns (uint);

    event AdjustReward(uint boosterId, uint adjustedReward);

    event AdjustDifficulty(uint boosterId, uint difficulty, uint adjustedDifficulty);

}

// File: contracts/BoostableMineableToken.sol

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

// File: contracts/Antigasable.sol

contract IQuarry {
    function rewardAntigas() public;
}

/**
 * The Antigasable contract rewards sub-contract recipients with a 0xMithril anti-gas rebate
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract Antigasable {

	/**
     * Delegates a call to the Mithril Quarry to initiate an anti-gas reward
     *
     * @param _mithrilQuarryAddress the contract address of the Mithril Token Quarry
     */
    function rewardAntigas(address _mithrilQuarryAddress) internal {
        IQuarry(_mithrilQuarryAddress).rewardAntigas();
    }
}

// File: contracts/InitializeOnce.sol

/**
 * The InitializeOnce modifier contract provides a mechanism for initializing a contract once after it has been constructed.
 * This is sometimes necessary, for example, when contracts that are linked to each other, require each other's addresses upon
 * initialization.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract InitializeOnce {
    address public owner;
    bool public initialized = false;

    constructor() public {
        initialized = false;
        owner = tx.origin;
    }

    modifier initializeOnce {
        require(initialized == false && tx.origin == owner, "This object has been initialized or the sender is not the owner [ InitializeOnce.initializeOnce() ]");
        initialized = true;
        _;
    }

    modifier isInitialized() {
	    require(initialized == true && tx.origin == owner, "This object has been initialized or the sender is not the owner [ InitializeOnce.isInitialized() ]");
	    _;
	}
  
    modifier notInitialized() {
    	require(initialized == false && tx.origin == owner, "This object has been initialized or the sender is not the owner [ InitializeOnce.notInitialized() ]");
    	_;
    }
}

// File: contracts/MineableToken.sol

/**
 * The MineableToken contract is contract that provides the functionality to create a new ERC20, ERC918 
 * compliant Mineable Token that issues anti-gas rebates.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract MineableToken is BoostableMineableToken, Antigasable, InitializeOnce {

    using SafeMath for uint;
    
    address public mithrilTokenAddress;

    address public mithrilQuarryAddress;
        
    /**
     * Constructor function
     *
     * Initializes contract with a target booster contract address, a quarry address, the 0xMithril token
     * address and all required ERC20, ERC918 fields
     *
     * @param _mithrilTokenAddress the address of the ERC20/ERC918 0xMithril Token
     * @param _mithrilQuarryAddress the address of the Mithril Quarry
     * @param _boosterAddress the address of the ERC721 base artifact
     * @param _symbol the symbol of the token
     * @param _name the name of the token
     * @param _decimals the number of decimal places of the token
     * @param _supply the initial supply of the token
     * @param _reward the initial reward of the token
     * @param _adjustmentBlockCount the number of mint blocks per difficulty adjustment
     * @param _initialDifficulty the initial difficulty of the token
     * @param _blockTimeInMinutes the target block time in minutes of the token
     * @param _metadataURI optional URI containing ERC918 Token Metadata
     */
    constructor(address _mithrilTokenAddress, address _mithrilQuarryAddress, address _boosterAddress, 
                string _symbol, string _name, uint8 _decimals, uint _supply, uint _reward, 
                uint _adjustmentBlockCount, uint _initialDifficulty, uint _blockTimeInMinutes, string _metadataURI) 
        BoostableMineableToken(_boosterAddress)
        ERC20Mineable(_symbol, _name, _decimals, _supply, _reward, _adjustmentBlockCount, _initialDifficulty, _blockTimeInMinutes, _metadataURI)
        public
    {
        symbol = _symbol;
        name = _name;
        mithrilTokenAddress = _mithrilTokenAddress;
        mithrilQuarryAddress = _mithrilQuarryAddress;
    }

    function setMetadataURI(string _metadataURI) public initializeOnce {
        metadataURI = _metadataURI;
    }

    /**
     * _reward function
     *
     * Internal function that overrides ERC918 _reward function that rewards an additional
     * 0xMithril gas rebate.
     * 
     */
    function _reward(address _minter) internal returns (uint amount) {
        amount = super._reward(_minter);
        rewardAntigas(mithrilQuarryAddress);
    }
    
}

// File: contracts/MithrilToken.sol

/**
 * The MithrilToken (0xMithril Token) contract is an ERC20, ERC918 mineable token that provides base utility for the Mineables network. The token
 * can be mined using ERC918 compatible mining software, providing an initial rewards of 100 and a total supply of 100 million. 0xMithril is used
 * as a rebate currency to pay back Ethereum gas used by mineable mint transactions, further incentivizing miners to mint Mineables network tokens.
 *
 * 0xMithril is also the base currency used when purchasing virtual mining artifacts such as Virtual Rigs and Virtual GPUs/ASICs, providing a closed-loop
 * economy for miners and artifact merchants.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract MithrilToken is 
	ERC20Mineable("0xMTH", "0xMithril Mining Network Token", 
				  18, 100000000, 100, 1024, 0, 5, 
				  "https://ipfs.io/ipfs/QmaEA2cB9dKvcPZh49yuNnaa9smhQfw8baBsh4XuT6dqFP"), 
	BoostableMineableToken 
{

	constructor(address _boosterAddress) 
        BoostableMineableToken(_boosterAddress)
        public 
    {
    	uint preMint = 5000000*10**18;
       	balances[msg.sender] = preMint;
       	tokensMinted += preMint;
        emit Transfer(address(0), msg.sender, preMint);
    }

}

// File: contracts/Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr), "Address does not have required role [ Roles.check() ]");
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

// File: contracts/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It's also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: contracts/RBACWithAdmin.sol

/**
 * @title RBACWithAdmin
 * @author Matt Condon (@Shrugs)
 * @dev It's recommended that you define constants in the contract,
 * @dev like ROLE_ADMIN below, to avoid typos.
 */
contract RBACWithAdmin is RBAC {
  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = "admin";

  /**
   * @dev modifier to scope access to admins
   * // reverts
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

  /**
   * @dev constructor. Sets msg.sender as admin by default
   */
  constructor()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }
}

// File: contracts/Registrar.sol

/**
 * The Registrar contract is a registrar for the Mineables network. It holds a listing of all 
 * available Mineable Tokens that have been registered and provides access control to underlying token factories.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract Registrar is RBACWithAdmin {

  string constant ROLE_MINEABLE = "mineable";

  modifier onlyAdminOrMineable()
  {
      require(
        hasRole(msg.sender, ROLE_ADMIN) ||
        hasRole(msg.sender, ROLE_MINEABLE), 
        "Insufficent priviledges to execute this function [ Registrar.onlyAdminOrMineable() ]"
      );
      _;
  }

  /* Mineables Registry Entry */
  struct MineableEntry {
    address mineable;
    uint listPointer;
  }

  mapping(address => MineableEntry) public mineableEntries;
  address[] public mineableKeyList;

  function isMineableEntry(address tokenAddress) public constant returns(bool isIndeed) {
    if(mineableKeyList.length == 0) return false;
    return (mineableKeyList[mineableEntries[tokenAddress].listPointer] == tokenAddress);
  }

  function mineableSize() public constant returns(uint entityCount) {
    return mineableKeyList.length;
  }

  function getMineableTuple(uint index) public constant
    returns(address token, address mineable)
  {
    token = mineableKeyList[index];
    mineable = mineableEntries[token].mineable;
  }

  function getMineable(address tokenAddress)
    public
    constant
    returns(address mineable)
  { 
    require(isMineableEntry(tokenAddress), "Invalid, entry exists [ Registrar.getMineable() ]");
    return mineableEntries[tokenAddress].mineable;
  }

  function getMineableKeyAt(uint index)
    public
    constant
    returns(address token)
  { 
    return mineableKeyList[index];
  }

  function getMineableAt(uint index)
    public
    constant
    returns(address mineable)
  { 
    return mineableEntries[mineableKeyList[index]].mineable;
  }

  function putMineable(address tokenAddress, address mineable) 
    public onlyAdminOrMineable returns(bool success) 
  {
    require(!isMineableEntry(tokenAddress), "Entry already exists [ Registrar.putMineable() ]");
    mineableEntries[tokenAddress].mineable = mineable;
    mineableEntries[tokenAddress].listPointer = mineableKeyList.push(tokenAddress) - 1;
    return true;
  }

  function updateMineable(address tokenAddress, address mineable) 
    public onlyAdmin returns(bool success) 
  {
    require(isMineableEntry(tokenAddress), "Invalid, entry exists [ Registrar.updateMineable() ]");
    mineableEntries[tokenAddress].mineable = mineable;
    return true;
  }

  function removeMineable(address tokenAddress) 
    public onlyAdmin returns(bool success) 
  {
    require(isMineableEntry(tokenAddress), "Invalid, entry exists [ Registrar.removeMineable() ]");
    uint rowToDelete = mineableEntries[tokenAddress].listPointer;
    address keyToMove   = mineableKeyList[mineableKeyList.length-1];
    mineableKeyList[rowToDelete] = keyToMove;
    mineableEntries[keyToMove].listPointer = rowToDelete;
    mineableKeyList.length--;
    return true;
  }

}

// File: contracts/MithrilTokenQuarry.sol

contract IMithrilToken is ERC20Interface {
    function transferFromOrigin(address to, uint tokens) public returns (bool success);
}

/**
 * The MithrilTokenQuarry contract is a registrar for the Mineables network. It holds a listing of all 
 * available Mineable Tokens that have been registered, provides access control to underlying token factories,
 * and provisions 0xMithril anti-gas rebates to all mint operations on the Mineables network.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract MithrilTokenQuarry is Registrar {

    using SafeMath for uint;

    // default antigas reward
    uint public MITHRIL_ANTIGAS_REWARD = 82727;

    // 0xMithril token address
    address public mithrilTokenAddress;

    // Base artifact booster address
    address public boosterAddress;

    event AntigasReward(uint amount);

    event Mined(address indexed from,  address tokenContract, bytes32 newChallengeNumber);
    
    event TokenRegistered(address tokenAddress, string tokenSymbol, string tokenName, 
        uint8 tokenDecimals, uint initialReward);

    /**
     * Constructor function
     *
     * Initializes contract with a target booster contract address and the 0xMithril token
     * address, allocating 1 million 0xMithril for anti-gas rewards.
     *
     * @param _boosterToken the address of the ERC721 base artifact
     * @param _mithrilTokenAddress the address of the ERC20/ERC918 0xMithril Token
     */
    constructor(address _boosterToken, address _mithrilTokenAddress) public {
      require(address(0x0) != _boosterToken, "Invalid booster address 0x0 [ MithrilTokenQuarry.constructor() ]");
      require(address(0x0) != _mithrilTokenAddress, "Invalid Mithril address 0x0 [ MithrilTokenQuarry.constructor() ]");
        
      boosterAddress = _boosterToken;
      mithrilTokenAddress = _mithrilTokenAddress;

      // Mithril Mining Network Tokens antigas rewards
      IMithrilToken(mithrilTokenAddress).transferFromOrigin(this, 1000000*10**uint(18));
    }

    /**
     * registerMineable function
     *
     * Public function that registers a mineable token with the quarry, by applying
     * appropriate network permissions and storing the token's address into the registry.
     *
     * @param _targetToken the address of the target token
     * @param _mineableToken the address of the ERC918 Mineable Token
     */
    function registerMineable(address _targetToken, address _mineableToken) 
        public onlyAdminOrMineable
    {   
        addRole(_mineableToken, ROLE_MINEABLE);
        putMineable(_targetToken, _mineableToken);
    }

    /**
     * setAntigasReward function
     *
     * Public protected function that allows the quarry owner to set antigas reward amount.
     *
     * @param _antigasReward the new anti-gas reward
     */
    function setAntigasReward(uint _antigasReward) public onlyAdmin {
        MITHRIL_ANTIGAS_REWARD = _antigasReward;
    }

    /**
     * setAntigasReward function
     *
     * Public protected function that rewards 0xMithril anti-gas to target minter.
     *
     */
    function rewardAntigas()
         public onlyAdminOrMineable
    {
        uint antigas = MITHRIL_ANTIGAS_REWARD.mul(tx.gasprice);
        if( ERC20Interface(mithrilTokenAddress).balanceOf(this) >= antigas ) {
            ERC20Interface(mithrilTokenAddress).transfer(tx.origin, antigas);
            emit AntigasReward(antigas);
        }
    }

    /**
     * upgradeBoosterAddress function
     *
     * Public protected function that allows the contract owner to upgrade the booster address.
     *
     * @param _newBoosterAddress the new booster contract address
     */
    function upgradeBoosterAddress(address _newBoosterAddress) public onlyAdmin {
        boosterAddress = _newBoosterAddress;
    }

    /**
     * addMineableRole function
     *
     * Public protected function that allows the contract owner to add a mineable role
     * to a target user or contract.
     *
     * @param _target the target contract address
     */
    function addMineableRole(address _target)
        onlyAdmin
        public
    {
        addRole(_target, ROLE_MINEABLE);
    }

    /**
     * revokeMineableRole function
     *
     * Public protected function that allows the contract owner to revoke a mineable role
     * from a target user or contract.
     *
     * @param _target the target contract address
     */
    function revokeMineableRole(address _target)
        onlyAdmin
        public
    {
        // revert if the user isn't an advisor
        checkRole(_target, ROLE_MINEABLE);

        // remove the mineable's role
        removeRole(_target, ROLE_MINEABLE);
    }

}

// File: contracts/IMineableTokenFactory.sol

/**
 * The IMineableTokenFactory contract is an abstract connector contract that provides the functionality to create a new Mineable Token and register
 * that token against the Mithril Token Quarry. This contract must have the explicit required permissions with the quarry when initially set up, or
 * else the call to create a new mineable token will fail.
 * Implementors are expected to define behavior for the internal function doCreate()
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract IMineableTokenFactory {

    // the address of the token quarry
	address public quarryAddress;

    // the adddress of the 0xMithril token
	address public mithrilTokenAddress;

    // the address of the primary base artifact booster contract
    address public boosterAddress;

    event MineableTokenCreated(address tokenAddress, string symbol, string name, uint8 decimals, 
                                uint supply, uint reward, uint adjustmentBlockCount, uint _initialDifficulty, 
                                uint _blockTimeInMinutes, string metadataURI);

    /**
     * Constructor function
     *
     * Initializes contract with a target booster contract address, a quarry address and the 0xMithril token
     * address.
     *
     * @param _quarryAddress the address of the Mithril Quarry
     * @param _mithrilTokenAddress the address of the ERC20/ERC918 0xMithril Token
     * @param _boosterAddress the address of the ERC721 base artifact
     */
	constructor(address _quarryAddress, address _mithrilTokenAddress, address _boosterAddress) 
		public 
	{
		require(address(0x0) != _quarryAddress, "Invalid quarry address 0x0 [ IMineableTokenFactory.constructor() ]");
		require(address(0x0) != _boosterAddress, "Invalid booster address 0x0 [ IMineableTokenFactory.constructor() ]");
      	require(address(0x0) != _mithrilTokenAddress, "Invalid Mithril address 0x0 [ IMineableTokenFactory.constructor() ]");
		
		quarryAddress = _quarryAddress;
		boosterAddress = _boosterAddress;
        mithrilTokenAddress = _mithrilTokenAddress;
	}

    /**
     * createMineable function
     *
     * Calls the delgated doCreate() function to create a new mineable token and registers the token with the token quarry.
     *
     * @param _symbol the symbol of the token
     * @param _name the name of the token
     * @param _decimals the number of decimal places of the token
     * @param _supply the initial supply of the token
     * @param _reward the initial reward of the token
     * @param _adjustmentBlockCount the number of mint blocks per difficulty adjustment
     * @param _initialDifficulty the initial difficulty of the token
     * @param _blockTimeInMinutes the target block time in minutes of the token
     */
    function createMineable(string _symbol, string _name, uint8 _decimals, uint _supply, 
                            uint _reward, uint _adjustmentBlockCount, uint _initialDifficulty, uint _blockTimeInMinutes, string _metadataURI) 
    	public
        returns (address mineable) 
    {
        mineable = doCreate(_symbol, _name, _decimals, _supply, _reward, _adjustmentBlockCount, _initialDifficulty, _blockTimeInMinutes, _metadataURI);

        MithrilTokenQuarry(quarryAddress).registerMineable(mineable, mineable);
        emit MineableTokenCreated(mineable, _symbol, _name, _decimals, _supply, _reward, _adjustmentBlockCount, _initialDifficulty, _blockTimeInMinutes, _metadataURI);
    }

    /**
     * doCreate function
     *
     * Abstract internal function meant to be overridden in an inherited class to perform the mechanics of creating
     * a mineable token.
     *
     * @param _symbol the symbol of the token
     * @param _name the name of the token
     * @param _decimals the number of decimal places of the token
     * @param _supply the initial supply of the token
     * @param _reward the initial reward of the token
     * @param _adjustmentBlockCount the number of mint blocks per difficulty adjustment
     * @param _initialDifficulty the initial difficulty of the token
     * @param _blockTimeInMinutes the target block time in minutes of the token
     */
    function doCreate(string _symbol, string _name, uint8 _decimals, uint _supply, 
                      uint _reward, uint _adjustmentBlockCount, uint _initialDifficulty, uint _blockTimeInMinutes, string _metadataURI) 
    	internal returns (address mineable); 

   

}

// File: contracts/MineableTokenFactory.sol

/**
 * The MineableTokenFactory contract is a connector contract that provides the functionality to create a new Mineable Token
 * via required doCreate() method. The base class provides internal registration functionality and housekeeping for the
 * new token.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract MineableTokenFactory is IMineableTokenFactory {

	/**
     * Constructor function
     *
     * Initializes contract with a target booster contract address, a quarry address and the 0xMithril token
     * address.
     *
     * @param _quarryAddress the address of the Mithril Quarry
     * @param _mithrilTokenAddress the address of the ERC20/ERC918 0xMithril Token
     * @param _boosterAddress the address of the ERC721 base artifact
     */
    constructor(address _quarryAddress, address _mithrilTokenAddress, address _boosterAddress) 
        IMineableTokenFactory(_quarryAddress, _mithrilTokenAddress, _boosterAddress)
        public{}

    /**
     * doCreate function
     *
     * Required internal function, overridding IMineableTokenFactory.doCreate that provides functionality
     * to instance a new MineableToken.
     *
     * @param _symbol the symbol of the token
     * @param _name the name of the token
     * @param _decimals the number of decimal places of the token
     * @param _supply the initial supply of the token
     * @param _reward the initial reward of the token
     * @param _adjustmentBlockCount the number of mint blocks per difficulty adjustment
     * @param _initialDifficulty the initial difficulty of the token
     * @param _blockTimeInMinutes the target block time in minutes of the token
     */
    function doCreate(string _symbol, string _name, uint8 _decimals, uint _supply, 
                      uint _reward, uint _adjustmentBlockCount, uint _initialDifficulty, uint _blockTimeInMinutes, string _metadataURI) 
        internal returns (address mineable) {

         mineable = new MineableToken(mithrilTokenAddress, quarryAddress, boosterAddress, 
             _symbol, _name, _decimals, _supply, _reward, _adjustmentBlockCount, _initialDifficulty, _blockTimeInMinutes, _metadataURI);

    }

}
