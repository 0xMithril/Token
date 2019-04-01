**Setup Solidity Development Environment**

---

## Install Development Environment

1. Install Truffle : http://truffleframework.com/
	
	Note: make sure you are on the latest : 
	
		npm uninstall -g truffle 
		npm install -g truffle
		
2. Install Ganache : http://truffleframework.com/ganache/  or Ganache CLI https://github.com/trufflesuite/ganache-cli 

		npm install -g ganache-cli
		
3. Install truffle-flattener : https://www.npmjs.com/package/truffle-flattener 
		
		npm i truffle-flattener
		
4. Execute truffle tests
	
		truffle test test/<testname.js>
		
5. Build flattened solidity deployments files with 
		
		build.sh


---

## Design Notes

Everything revolves around the MithrilTokenQuarry contract. This is where the mineables registry is, it is also where we register TokenMineableFactories, responsible for creating the different Mineable token types. For phase one we will only be installing the MineableTokenFactory, which builds an ERC20 token from scratch and registers it with the MithrilTokenQuarry.

Mithril based mineables provide a couple of neat features: "Antigas rewards" for every mint operation, and Mining Booster hooks. Antigas rewards pay back the user in Mithril the amount of gas that the operation took. This helps to offset the gas price of the ethereum transaction for individual and pool miners. The Mining Booster hooks include functionality for hooking in Mining Boosters for each mineable. Depending on their stats, boosters will perform 2 different types of operations to increase the value of a default mint operation: reward multiplication and difficulty reduction. Any mineable on the Mithril network will be able to install and leverage these powerful artifacts.