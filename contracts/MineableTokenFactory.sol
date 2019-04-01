pragma solidity ^0.4.24;

import "./MineableToken.sol";
import "./MithrilTokenQuarry.sol";
import "./IMineableTokenFactory.sol";

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