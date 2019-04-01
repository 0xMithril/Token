pragma solidity ^0.4.24;

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