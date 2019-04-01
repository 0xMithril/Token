pragma solidity ^0.4.24;

interface StatisticsModifier {
    function merge(uint _executionCost, uint _coolDown, uint _reward, uint _target) external 
        returns (uint executionCost, uint coolDown, uint reward, uint target);
    
}