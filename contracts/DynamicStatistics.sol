pragma solidity ^0.4.24;

import "./Owned.sol";
import "./SafeMath.sol";

contract DynamicStatistics is Owned {
    using SafeMath for uint;
    
    uint [] public baseStatistics;
    mapping(uint => string) public statisticsNames;
    
    constructor() public {
        addStatistic("Power", 100);
        addStatistic("Agility", 100);
        addStatistic("Dexterity", 100);
    }
    
    function addStatistic(string _name, uint _initialValue) public onlyOwner {
        uint pos = baseStatistics.push(_initialValue) - 1;
        statisticsNames[pos] = _name;
    }

    function numDigits(uint number) internal pure returns (uint8) {
        uint8 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }

    function parseModifier(uint num) internal pure returns (uint modifierValue, uint operation) {
        uint remain = num;
        // Modifier
        modifierValue = remain % 10 ** 3;
        remain = remain / 10 ** 3;
        
        // Operation
        operation = remain % 10 ** 1;
        remain = remain / 10 ** 1;
    }
    
    /* 
        Operations:
            1 - addition
            2 - substraction
            3 - multiplication
            4 - division
            5 - add percentage to
            6 - subtract percentage from
            7 - require greater than
            8 - require less than
            9 - set value

            examples:
            1009 -> 1, 009: add 9
            5312 -> 5, 312: add 312%
            6075 -> 1, 075: substract 75%
            7100 -> 7, 100: require greater than 100
    */
    function operate(uint _target, uint _mod) internal pure returns (uint result) {
        uint modifierValue;
        uint operation;
        (modifierValue, operation) = parseModifier(_mod);

        if(operation == 1){
            result = _target.add(modifierValue);
        } else if (operation == 2) {
            result = _target.sub(modifierValue);
        } else if (operation == 3) {
            result = _target.mul(modifierValue);
        } else if (operation == 4) {
            result = _target.div(modifierValue);
        } else if (operation == 5) {
            result = _target.add(_target.mul(modifierValue).div(100));
        } else if (operation == 6) {
            result = _target.sub(_target.mul(modifierValue).div(100));
        } else if (operation == 7) {
            require(_target > modifierValue);
            result = _target;
        } else if (operation == 8) {
            require(_target < modifierValue);
            result = _target;
        }else if (operation == 9) {
        	result = modifierValue;
        } else {
            result = _target;
        }
    }
    
    // dont forget it starts with magic number
    // 1 001009 011010 021011 001020 001023 007099
    // 1001009011010021011001020001023007099
    function split(uint _artifact) public pure returns (uint [] targets_, uint [] ops_) {
        uint8 len = numDigits(_artifact) / 6;
        require(len > 0);
        targets_ = new uint[](len);
        ops_ = new uint[](len);
        uint current = _artifact;
        for (uint j = len; j > 0; j--) {
            uint mod = current % 10 ** 6;
            uint target;
            uint op;
            (target, op) = parseOp(mod);
            targets_[j-1] = target;
            ops_[j-1] = op;
            current = current / 10 ** 6;
        }
    }
    
    function parseOp(uint num) public pure returns (uint target, uint op ) {
        uint remain = num;
        // Modifier
        op = remain % 10 ** 4;
        remain = remain / 10 ** 4;
        
        // Operation
        target = remain % 10 ** 2;
        remain = remain / 10 ** 2;
    }
    
    // start with a magic number to preserve position
    // magic#, records...
    // [1] 001009 011010 021011 001020 001023 007099
    // 1001009011010021011001020001023007099
    function mergeSingle(uint _artifact, uint[] memory merged) internal pure returns (uint [] result) {
        uint8 len = numDigits(_artifact) / 6;
        require(len > 0);
        
        //uint[] memory merged = baseStats;
        uint current = _artifact;
        for (uint j = len; j > 0; j--) {
            uint mod = current % 10 ** 6;
            uint target;
            uint op;
            (target, op) = parseOp(mod);
            merged[target] = operate(merged[target], mod);

            current = current / 10 ** 6;
        }
        result = merged;
    }
    
    // ["1001009011010","1001009011010","1001009011010021011001020001023007099"]
    function merge(uint[] _artifacts) public returns (uint [] result) {
        uint[] memory merged = new uint[](baseStatistics.length);
        merged = baseStatistics;
        for(uint i = 0; i < _artifacts.length; i++) {
            merged = mergeSingle(_artifacts[i], merged);
        }
        baseStatistics = merged;
        result = merged;
    }
    
       
}