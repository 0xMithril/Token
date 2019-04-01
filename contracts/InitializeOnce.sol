pragma solidity ^0.4.24;

/**
 * The InitializeOnce modifier contract provides a mechanism for initializing a contract once after it has been constructed.
 * This is sometimes necessary, for example, when contracts that are linked to each other, require each other's addresses upon
 * initialization.
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract InitializeOnce {
    address public owner;
    bool public initialized = false;

    constructor() public {
        initialized = false;
        owner = tx.origin;
    }

    modifier initializeOnce {
        require(initialized == false && tx.origin == owner, "This object has been initialized or the sender is not the owner [ InitializeOnce.initializeOnce() ]");
        initialized = true;
        _;
    }

    modifier isInitialized() {
	    require(initialized == true && tx.origin == owner, "This object has been initialized or the sender is not the owner [ InitializeOnce.isInitialized() ]");
	    _;
	}
  
    modifier notInitialized() {
    	require(initialized == false && tx.origin == owner, "This object has been initialized or the sender is not the owner [ InitializeOnce.notInitialized() ]");
    	_;
    }
}