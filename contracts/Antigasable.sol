pragma solidity ^0.4.24;

import "./ERC20Interface.sol";
import "./SafeMath.sol";

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