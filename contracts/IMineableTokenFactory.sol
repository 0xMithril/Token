pragma solidity ^0.4.24;

import "./MineableToken.sol";
import "./MithrilTokenQuarry.sol";

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