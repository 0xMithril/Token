pragma solidity ^0.4.24;

import "./ERC20Mineable.sol";
/* Three liner to create an ERC20 mineable token */
contract TestMineable is ERC20Mineable('0xDoge', '0xDoge Mineable Token', 18, 113000000000, 200, 1024, 512, 10, "https://ipfs.io/ipfs/QmaEA2cB9dKvcPZh49yuNnaa9smhQfw8baBsh4XuT6dqFP") { }