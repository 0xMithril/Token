pragma solidity ^0.4.24;

import "./BoostableMineableToken.sol";
import "./Antigasable.sol";
import "./InitializeOnce.sol";

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