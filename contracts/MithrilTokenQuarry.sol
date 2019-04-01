pragma solidity ^0.4.24;

import "./MithrilToken.sol";
import "./IMithrilBooster.sol";
import "./SafeMath.sol";
import "./ERC721Basic.sol";
import "./ERC20Interface.sol";
import "./Registrar.sol";

contract IMithrilToken is ERC20Interface {
    function transferFromOrigin(address to, uint tokens) public returns (bool success);
}

/**
 * The MithrilTokenQuarry contract is a registrar for the Mineables network. It holds a listing of all 
 * available Mineable Tokens that have been registered, provides access control to underlying token factories,
 * and provisions 0xMithril anti-gas rebates to all mint operations on the Mineables network.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract MithrilTokenQuarry is Registrar {

    using SafeMath for uint;

    // default antigas reward
    uint public MITHRIL_ANTIGAS_REWARD = 82727;

    // 0xMithril token address
    address public mithrilTokenAddress;

    // Base artifact booster address
    address public boosterAddress;

    event AntigasReward(uint amount);

    event Mined(address indexed from,  address tokenContract, bytes32 newChallengeNumber);
    
    event TokenRegistered(address tokenAddress, string tokenSymbol, string tokenName, 
        uint8 tokenDecimals, uint initialReward);

    /**
     * Constructor function
     *
     * Initializes contract with a target booster contract address and the 0xMithril token
     * address, allocating 1 million 0xMithril for anti-gas rewards.
     *
     * @param _boosterToken the address of the ERC721 base artifact
     * @param _mithrilTokenAddress the address of the ERC20/ERC918 0xMithril Token
     */
    constructor(address _boosterToken, address _mithrilTokenAddress) public {
      require(address(0x0) != _boosterToken, "Invalid booster address 0x0 [ MithrilTokenQuarry.constructor() ]");
      require(address(0x0) != _mithrilTokenAddress, "Invalid Mithril address 0x0 [ MithrilTokenQuarry.constructor() ]");
        
      boosterAddress = _boosterToken;
      mithrilTokenAddress = _mithrilTokenAddress;

      // Mithril Mining Network Tokens antigas rewards
      IMithrilToken(mithrilTokenAddress).transferFromOrigin(this, 1000000*10**uint(18));
    }

    /**
     * registerMineable function
     *
     * Public function that registers a mineable token with the quarry, by applying
     * appropriate network permissions and storing the token's address into the registry.
     *
     * @param _targetToken the address of the target token
     * @param _mineableToken the address of the ERC918 Mineable Token
     */
    function registerMineable(address _targetToken, address _mineableToken) 
        public onlyAdminOrMineable
    {   
        addRole(_mineableToken, ROLE_MINEABLE);
        putMineable(_targetToken, _mineableToken);
    }

    /**
     * setAntigasReward function
     *
     * Public protected function that allows the quarry owner to set antigas reward amount.
     *
     * @param _antigasReward the new anti-gas reward
     */
    function setAntigasReward(uint _antigasReward) public onlyAdmin {
        MITHRIL_ANTIGAS_REWARD = _antigasReward;
    }

    /**
     * setAntigasReward function
     *
     * Public protected function that rewards 0xMithril anti-gas to target minter.
     *
     */
    function rewardAntigas()
         public onlyAdminOrMineable
    {
        uint antigas = MITHRIL_ANTIGAS_REWARD.mul(tx.gasprice);
        if( ERC20Interface(mithrilTokenAddress).balanceOf(this) >= antigas ) {
            ERC20Interface(mithrilTokenAddress).transfer(tx.origin, antigas);
            emit AntigasReward(antigas);
        }
    }

    /**
     * upgradeBoosterAddress function
     *
     * Public protected function that allows the contract owner to upgrade the booster address.
     *
     * @param _newBoosterAddress the new booster contract address
     */
    function upgradeBoosterAddress(address _newBoosterAddress) public onlyAdmin {
        boosterAddress = _newBoosterAddress;
    }

    /**
     * addMineableRole function
     *
     * Public protected function that allows the contract owner to add a mineable role
     * to a target user or contract.
     *
     * @param _target the target contract address
     */
    function addMineableRole(address _target)
        onlyAdmin
        public
    {
        addRole(_target, ROLE_MINEABLE);
    }

    /**
     * revokeMineableRole function
     *
     * Public protected function that allows the contract owner to revoke a mineable role
     * from a target user or contract.
     *
     * @param _target the target contract address
     */
    function revokeMineableRole(address _target)
        onlyAdmin
        public
    {
        // revert if the user isn't an advisor
        checkRole(_target, ROLE_MINEABLE);

        // remove the mineable's role
        removeRole(_target, ROLE_MINEABLE);
    }

}