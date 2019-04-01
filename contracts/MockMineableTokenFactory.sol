pragma solidity ^0.4.24;

import "./MockMineableToken.sol";
import "./MithrilTokenQuarry.sol";
import "./IMineableTokenFactory.sol";

contract MockMineableTokenFactory is IMineableTokenFactory {

    constructor(address _quarryAddress, address _mithrilTokenAddress, address _boosterAddress) 
        IMineableTokenFactory(_quarryAddress, _mithrilTokenAddress, _boosterAddress)
        public{}

	function doCreate(string _symbol, string _name, uint8 _decimals, uint _supply, 
                      uint _reward, uint _adjustmentBlockCount, uint _initialDifficulty, uint _blockTimeInMinutes, string _metadataURI) 
        internal returns (address mineable) {

        mineable = new MockMineableToken(mithrilTokenAddress, quarryAddress, boosterAddress, 
             _symbol, _name, _decimals, _supply, _reward, _adjustmentBlockCount, _initialDifficulty, _blockTimeInMinutes, _metadataURI);
    }

}