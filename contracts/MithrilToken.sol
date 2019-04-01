pragma solidity ^0.4.24;

import "./BoostableMineableToken.sol";

/**
 * The MithrilToken (0xMithril Token) contract is an ERC20, ERC918 mineable token that provides base utility for the Mineables network. The token
 * can be mined using ERC918 compatible mining software, providing an initial rewards of 100 and a total supply of 100 million. 0xMithril is used
 * as a rebate currency to pay back Ethereum gas used by mineable mint transactions, further incentivizing miners to mint Mineables network tokens.
 *
 * 0xMithril is also the base currency used when purchasing virtual mining artifacts such as Virtual Rigs and Virtual GPUs/ASICs, providing a closed-loop
 * economy for miners and artifact merchants.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract MithrilToken is 
	ERC20Mineable("0xMTH", "0xMithril Mining Network Token", 
				  18, 100000000, 100, 1024, 0, 5, 
				  "https://ipfs.io/ipfs/QmaEA2cB9dKvcPZh49yuNnaa9smhQfw8baBsh4XuT6dqFP"), 
	BoostableMineableToken 
{

	constructor(address _boosterAddress) 
        BoostableMineableToken(_boosterAddress)
        public 
    {
    	uint preMint = 5000000*10**18;
       	balances[msg.sender] = preMint;
       	tokensMinted += preMint;
        emit Transfer(address(0), msg.sender, preMint);
    }

}