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

// File: contracts/ERC918BackwardsCompatible.sol

/**
 * @title ERC-918 Mineable Token Standard, optional backwards compatibility function
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-918.md
 * 
 */
contract ERC918BackwardsCompatible {

    function getAdjustmentInterval() public view returns (uint);

    function getChallengeNumber() public view returns (bytes32);

    function getMiningDifficulty() public view returns (uint);

    function getMiningTarget() public view returns (uint);

    function getMiningReward() public view returns (uint);

    function mint(uint256 _nonce) public returns (bool success);

    /*
     * @notice Externally facing mint function kept for backwards compatability with previous mint() definition
     * @param _nonce the solution nonce
     * @param _challenge_digest the keccak256 encoded challenge number + message sender + solution nonce
     **/
    function mint(uint256 _nonce, bytes32 _challenge_digest) public returns (bool success) {
        //the challenge digest must match the expected
        bytes32 digest = keccak256( abi.encodePacked(getChallengeNumber(), msg.sender, _nonce) );
        require(digest == _challenge_digest, "Challenge digest does not match expected digest on token contract [ ERC918BackwardsCompatible.mint() ]");
        success = mint(_nonce);
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

// File: contracts/ERC20StandardToken.sol

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
// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC20StandardToken is ERC20Interface {
	using SafeMath for uint;
    using ExtendedMath for uint;
    
	string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;

	mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
   

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

}

// File: contracts/SimpleERC918.sol

/**
 * Simple ERC918 Implementation
 * Proof of Work Mineable Token
 *
 * This Abstract contract implements a minimal set of behaviors (hash, reward, epoch, and difficulty adjustment) 
 * and state required to build a Proof of Work driven mineable token.
 * 
 * https://github.com/ethereum/EIPs/pull/918
 * https://www.ethereum.org/token#proof-of-work
 */
contract SimpleERC918 is ERC918, ERC918BackwardsCompatible, ERC918Metadata, ERC20StandardToken {
    
    uint public MINIMUM_TARGET = 2**16;

    uint public MAXIMUM_TARGET = 2**234;

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
    
    // Variable to keep track of when rewards were given
    uint public timeOfLastProof;    

    // optional metadataURI URI containing ERC918 Token Metadata
    string public metadataURI;

    uint public difficulty = MINIMUM_TARGET;

    uint public miningReward = 50*10**18;

    function mint(uint256 _nonce) public returns (bool success) {

        // perform the hash function validation
        hash(_nonce, msg.sender);
        
        // calculate the current reward
        uint rewardAmount = _reward(msg.sender);
        
        // increment the minted tokens amount
        tokensMinted += rewardAmount;
        
        // increment state variables of current and new epoch
        epochCount = _epoch();

        //every so often, readjust difficulty. Dont readjust when deploying
        if(epochCount % blocksPerReadjustment == 0){
            _adjustDifficulty();
        }
       
        // send Mint event indicating a successful implementation
        emit Mint(msg.sender, rewardAmount, epochCount, challengeNumber);
        
        return true;
    }
    
    function hash(uint256 nonce, address _target) public returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(nonce, _target));    // Generate a random hash based on input
        require(digest >= bytes32(difficulty));                   // Check if it's under the difficulty
    }
    
    function _reward(address _target) internal returns (uint rewardAmount) {
        uint timeSinceLastProof = (now - timeOfLastProof);  // Calculate time since last reward was given
        require(timeSinceLastProof >=  5 seconds);         // Rewards cannot be given too quickly
        rewardAmount = timeSinceLastProof / 60 seconds;
        balances[_target] += rewardAmount;  // The reward to the winner grows by the minute
    }
    
    function _epoch() internal returns (uint) {
        timeOfLastProof = now;  // Reset the counter
        challengeNumber = keccak256(abi.encodePacked(challengeNumber, blockhash(block.number - 1)));  // Save a hash that will be used as the next proof
    }
    
    function _adjustDifficulty() internal returns (uint) {
        uint timeSinceLastProof = (now - timeOfLastProof);  // Calculate time since last reward was given
        difficulty = difficulty * 10 minutes / (timeSinceLastProof + 1);  // Adjusts the difficulty
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a mineable asset.
     */
    function metadataURI() external view returns (string) {
        return metadataURI;
    }

    /**
     * Backwards compatibility with existing Token Mining software
     */
    function getAdjustmentInterval() public view returns (uint) {
        return adjustmentInterval;
    }

    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }

    function getMiningDifficulty() public view returns (uint){
        return MAXIMUM_TARGET.div(getMiningTarget());
    }

    function getMiningTarget() public view returns (uint) {
        return miningTarget;
    }

    function getMiningReward() public view returns (uint) {
        return miningReward;
    }

}
