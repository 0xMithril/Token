var MithrilToken = artifacts.require("./MithrilToken.sol");
var ChildArtifact = artifacts.require("./ChildArtifact.sol");
var VirtualMiningBoard = artifacts.require("./VirtualMiningBoard.sol");
var MithrilTokenQuarry = artifacts.require("./MithrilTokenQuarry.sol");
var FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var MineableToken = artifacts.require("./MineableToken.sol");
var MineableTokenFactory = artifacts.require("./MineableTokenFactory.sol");
var MockMineableTokenFactory = artifacts.require("./MockMineableTokenFactory.sol");
var MockMineableToken = artifacts.require("./MockMineableToken.sol");

const initialDiff = 512;
const erc918Metadata = 'https://ipfs.io/ipfs/QmaEA2cB9dKvcPZh49yuNnaa9smhQfw8baBsh4XuT6dqFP';

contract('Minable Tokens Tests [testMineableToken.js]', async (accounts) => {

	function readable(num){
	    return num / Math.pow(10, 18);
	}

	async function createMineable(factory) {
		// call the createMineable transaction
		let mineableTxn = await factory.createMineable("0xNEW","Example New Mineable Token",18, 1000000, 200, 1024, initialDiff, 10, erc918Metadata);
		console.log('mineableTxn.cumulativeGasUsed: ' + mineableTxn.receipt.cumulativeGasUsed);

		// grab the mineable address from the transaction's event log
		var mineableAddress;
		for (var i = 0; i < mineableTxn.logs.length; i++) {
		    var log = mineableTxn.logs[i];
		    if (log.event == "MineableTokenCreated") {
		      mineableAddress = log.args.tokenAddress;
		      break;
		    }
		}

		return mineableAddress;
	}

	it("should create mineable from MineableTokenFactory", async () => {
	    let mineableTokenFactory = await MineableTokenFactory.deployed();
	    let mithrilToken = await MithrilToken.deployed();
		var mineableAddress = await createMineable(mineableTokenFactory);

		let mineableToken = await MineableToken.at(mineableAddress)
		console.log(await mineableToken.name.call())
		let adjustmentInterval = await mineableToken.adjustmentInterval.call()
		assert.equal(600, adjustmentInterval)

		assert.equal(await mineableToken.getMiningDifficulty.call(), initialDiff);

	});

	it("should create and mine a mineable from MockMineableTokenFactory", async () => {
	    let mineableTokenFactory = await MockMineableTokenFactory.deployed();
	    let mithrilToken = await MithrilToken.deployed();

		let mineableTxn = await mineableTokenFactory.createMineable("0xNEW","Example New Mineable Token",18, 1000000, 200, 1024, initialDiff, 10, erc918Metadata);

		var mineableAddress;
		// grab the mineable address from the transaction's event log
		for (var i = 0; i < mineableTxn.logs.length; i++) {
		    var log = mineableTxn.logs[i];
		    if (log.event == "MineableTokenCreated") {
		      mineableAddress = log.args.tokenAddress;
		      break;
		    }
		}

		let mockMineable = await MockMineableToken.at(mineableAddress);
		console.log(await mockMineable.name.call());

	});


	it("should setup and test MineableToken", async () => {
	    let token = await FixedSupplyToken.deployed();
	    let booster = await VirtualMiningBoard.deployed();
	    let mithrilToken = await MithrilToken.deployed();
	    let quarry = await MithrilTokenQuarry.deployed();

	    console.log('quarry.mithrilTokenAddress: ' + await quarry.mithrilTokenAddress.call());
	    console.log('mithrilToken.address: ' + await mithrilToken.address);
	    console.log('mithrilToken.totalSupply: ' + await mithrilToken.totalSupply());
	    console.log('Creating MineableToken...');

	    // create a new Mineable Token
	    let mineable = await MineableToken.new(mithrilToken.address, quarry.address, booster.address,
	    		"0xNEW","Example New Mineable Token",18, 1000000, 200, 1024, initialDiff, 10, erc918Metadata);

	    // register with the quarry
	   	console.log('Registering MineableToken...');
	    await quarry.registerMineable(mineable.address, mineable.address);

	    assert.equal(mineable.address, await quarry.getMineable(mineable.address));

	});

	it("should setup and mine MockMineableToken", async () => {
		let token = await FixedSupplyToken.deployed();
	    let booster = await VirtualMiningBoard.deployed();
	    let mithrilToken = await MithrilToken.deployed();
	    let quarry = await MithrilTokenQuarry.deployed();

		// create a new Mock Mineable Token
	    console.log('Creating MockMineableToken...');
	    var mineableAddress = await createMineable(await MockMineableTokenFactory.deployed());

	    let mockMineable = MockMineableToken.at(mineableAddress);

	    const acctCount = 9;
	    const count = 2;
	    for (var i = 0; i < count; i++) {
	      for (var j = 1; j <= acctCount; j++) {
	        console.log('-------------------------------------------------------------------------------');
	        //console.log('---> difficulty: ' + Number(await mockMineable.getMiningDifficulty.call()) );
	        //console.log('---> remainingSupply: ' + readable(remainingSupply) );
	        //console.log('---> tokensMinted: ' + readable(await mockMineable.tokensMinted.call()));
	        //console.log('---> miningReward: ' + readable(await mockMineable.getMiningReward()));
	        //console.log('----> mithril reward: ' + await quarry.getMithrilMergeReward.call());
	        
	        // workaround - have to call mint with two parameters due to truffle bug re: solidity overloaded functions
	        // https://github.com/trufflesuite/truffle/issues/569 
	        let txn = await mockMineable.mint('0x0','0x0', {from: accounts[j]} );
	        
	        console.log('txn.cumulativeGasUsed: ' + txn.receipt.cumulativeGasUsed);
	      }
	    }

	    for (var i = 1; i <= acctCount; i++) {
	      console.log('-- Account ' + i + ' --');
	      console.log('Booster: ' + await booster.balanceOf(accounts[i]) );
	      console.log('Mithril: ' + readable( await mithrilToken.balanceOf(accounts[i]) ) );
	      console.log('Mithril: ' + await mithrilToken.balanceOf(accounts[i] ) );
	      console.log('Token: ' + readable( await mockMineable.balanceOf(accounts[i])) );
	    }
	});

});
