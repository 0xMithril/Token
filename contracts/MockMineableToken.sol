pragma solidity ^0.4.24;

import "./MineableToken.sol";

contract MockMineableToken is MineableToken {
    using SafeMath for uint;
    using ExtendedMath for uint;

    constructor(address _mithrilTokenAddress, address _mithrilQuarryAddress, address _boosterAddress, 
                string _symbol, string _name, uint8 _decimals, uint _supply, uint _reward, 
                uint _adjustmentBlockCount, uint _initialDifficulty, uint _blockTimeInMinutes, string _metadataURI) 
        MineableToken( _mithrilTokenAddress, _mithrilQuarryAddress, _boosterAddress, _symbol, 
        				_name, _decimals, _supply, _reward, _adjustmentBlockCount, _initialDifficulty, _blockTimeInMinutes, _metadataURI)
        public { }

    event TestMiningTarget(uint adjustedMiningTarget);
    event TestAdjustedMiningTarget(uint adjustedMiningTarget);

    function hash(uint256 _nonce, address _minter) public returns (bytes32 digest) {
        uint boosterId = getInstalledBooster();
        digest = keccak256( abi.encodePacked(challengeNumber, tx.origin, _nonce) );

        if(boosterId > 0) { 
            // get the adjusted mining target from the booster
            emit TestMiningTarget(miningTarget);
            uint adjustedMiningTarget = IMithrilBooster(boosterAddress).adjustDifficulty(boosterId, miningTarget, adjustmentInterval);
            emit TestAdjustedMiningTarget(adjustedMiningTarget);
           
        }
    }

    // workaround hack because truffle cannot handle overloaded functions
    function mint(uint256 _nonce, bytes32 challenge_digest) public returns (bool success) {
        //the challenge digest must match the expected
        //bytes32 digest = keccak256( abi.encodePacked(challengeNumber, msg.sender, nonce) );
        //require(digest == challenge_digest, "Challenge digest does not match expected digest on token contract");
        return super.mint(_nonce);
    }

}