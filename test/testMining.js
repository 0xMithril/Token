var MithrilToken = artifacts.require("./MithrilToken.sol");
var VirtualMiningBoard = artifacts.require("./VirtualMiningBoard.sol");
var MithrilTokenQuarry = artifacts.require("./MithrilTokenQuarry.sol");
var FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var MineableToken = artifacts.require("./MineableToken.sol");
var MineableTokenFactory = artifacts.require("./MineableTokenFactory.sol");
var MockMineableToken = artifacts.require("./MockMineableToken.sol");
var MockMineableTokenFactory = artifacts.require("./MockMineableTokenFactory.sol");

var ChildArtifact = artifacts.require("./ChildArtifact.sol");

const initialDiff = 512;

let ex = 1000;
let ld = 1;
let ec = 0;
let sok = 10;
let vhash = 0;
let acc = 100;
let lvl = 1;

var statistics = [ex,ld,ec,sok,vhash,acc,lvl];

var metadata = 'https://ipfs.io/ipfs/QmTYHdY87Va7Wkef9EQCHS6d5y7JK8RxeYRgcZXj9niYBQ';
const erc918Metadata = 'https://ipfs.io/ipfs/QmaEA2cB9dKvcPZh49yuNnaa9smhQfw8baBsh4XuT6dqFP';

contract('MithrilTokenQuarry Tests [testMining.js]', async (accounts) => {

	function readable(num){
	    return num / Math.pow(10, 18);
	}

	async function createMineable(factory) {
		// call the createMineable transaction
		let mineableTxn = await factory.createMineable("0xNEW","Example New Mineable Token",18, 1000000, 100, 1024, initialDiff, 10, erc918Metadata);

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

	it("should setup and mine MockMineableToken", async () => {
		let token = await FixedSupplyToken.deployed();
	    let booster = await VirtualMiningBoard.deployed();
	    let socketArtifact = await ChildArtifact.deployed();
	    let mithrilToken = await MithrilToken.deployed();
	    let quarry = await MithrilTokenQuarry.deployed();
	    let mineableTokenFactory = await MockMineableTokenFactory.deployed();

	    console.log('Quarry Mithril Balance: ' + readable( await mithrilToken.balanceOf.call(quarry.address) ) );
	   	console.log('Account 0 Mithril Balance: ' + readable( await mithrilToken.balanceOf.call(accounts[0]) ) );


	    console.log('constructed');
/*
		let mockMineableAddress = await mineableTokenFactory.createMockMineable("0xNEW","Example New Mineable Token",18, 1000000, 200, 1024);
		let mm = await mineableTokenFactory.mineable.call();
		console.log(mm);
		let mockMineable = await MockMineableToken.at(mm);
*/

		var mineableAddress = await createMineable(mineableTokenFactory);
		let mockMineable = await MineableToken.at(mineableAddress);

		// create a new Mock Mineable Token
	    console.log('Creating MockMineableToken...');
	   // let mockMineable = await MockMineableToken.new(mithrilToken.address, quarry.address, booster.address,"0xNEW","Example Mock Mineable Token",18, 1000000, 200, 1024);

	    // register with the quarry
	   // console.log('Registering MockMineableToken...');
	   // await quarry.registerMineable(mockMineable.address, mockMineable.address);
	   // assert.equal(mockMineable.address, await quarry.registry(mockMineable.address));
		
	   	/* 
	   		Mint a new booster 
	   	*/
	   	txn = await booster.mint(accounts[1], "Awesome Booster", statistics, metadata);
	   	console.log('Booster Minting -> txn.cumulativeGasUsed: ' + txn.receipt.cumulativeGasUsed);

	   	// Mint a vGPU
	   	// Note: in this mock set up, it wont effect hashrate
		result = await socketArtifact.mint.call(accounts[1], "Virtual GPU 800 MHs", 100, [1049810], metadata);
	   			 await socketArtifact.mint(accounts[1], "Virtual GPU 800 MHs", 100, [1049810], metadata);
	   	let gpuId1 = result.toNumber();

	   	await booster.addChildArtifact(1, gpuId1, {from: accounts[1]});

	   	// Mint some Mining Mana to increase accuracy (rewards)

	    // create vGPU for jay
	   	result = await socketArtifact.mint.call(accounts[1], "Mining Mana (+ 20% to accuracy)", 100, [1055020], metadata);
	   			 await socketArtifact.mint(accounts[1], "Mining Mana (+ 20% to accuracy)", 100, [1055020], metadata);
	   	let gpuId2 = result.toNumber();
	   	await booster.addChildArtifact(1, gpuId2, {from: accounts[1]});

	   	// merge stats
	   	let REWARD = 100;
	   //	let mergedStats = await booster.merge(1, REWARD, 1e6, {from: accounts[1]});

	   	displayBooster(await booster.mergedStats(1));

/*
	    assert.equal(await booster.ownerOf(1), accounts[1]);
	    console.log('booster.ownerOf(1): ' + await booster.ownerOf(1));
	    console.log('booster.balanceOf(accounts[1]): ' + await booster.balanceOf(accounts[1]));
	    
	    // transfer the booster to user 2
	    await booster.transfer(accounts[2], 1, { from: accounts[1] });
	    assert.equal(await booster.ownerOf(1), accounts[2]);
	    console.log('booster.ownerOf(1): ' + await booster.ownerOf(1));
*/
	    // install the booster
	    console.log('install the booster');
	    await mockMineable.installBooster(1, { from: accounts[1]} );

	    console.log('Installed booster: ' + await mockMineable.getInstalledBooster( { from: accounts[1] } ));

	    const acctCount = 9;
	    const count = 2;
	    for (var i = 0; i < count; i++) {
	      for (var j = 1; j <= acctCount; j++) {
	        console.log('-------------------------------------------------------------------------------');
	        //console.log('---> difficulty: ' + Number(await mockMineable.getMiningDifficulty.call()) );
	        //console.log('---> remainingSupply: ' + readable(remainingSupply) );
	        console.log('---> tokensMinted: ' + readable(await mockMineable.tokensMinted.call()));
	        //console.log('---> miningReward: ' + readable(await mockMineable.getMiningReward()));
	        //console.log('----> mithril reward: ' + await quarry.getMithrilMergeReward.call());

	        console.log('account ' + j);
	        console.log('----> mining target: ' + await mockMineable.getMiningTarget());

	        // workaround - have to call mint with two parameters due to truffle bug re: solidity overloaded functions
	        // https://github.com/trufflesuite/truffle/issues/569 
	        let txn = await mockMineable.mint('0x0', '0x0', {from: accounts[j]} );

	        if(j == 2){
	        	//console.log(txn);
	    	}
	       // console.log('txn.cumulativeGasUsed: ' + txn.receipt.cumulativeGasUsed);
	      }
	    }

	    for (var i = 1; i <= acctCount; i++) {
	      console.log('-- Account ' + i + ' --');
	      console.log('Booster: ' + await booster.balanceOf(accounts[i]) );
	      console.log('Mithril: ' + await mithrilToken.balanceOf(accounts[i] ) );
	      console.log('Mithril: ' + readable( await mithrilToken.balanceOf(accounts[i]) ) );
	      console.log('Token: ' + readable( await mockMineable.balanceOf(accounts[i])) );
	    }

	    console.log('Mithril Supply: ' + readable ( await mithrilToken.totalSupply() ) );
	    console.log('Mithril Minted: ' + readable ( await mithrilToken.tokensMinted.call() ) );

	    displayBooster(await booster.mergedStats(1));

	  //  throw 'bedshit';

	});

	function displayBooster(stats) {

		let name = stats[0];
		let basicStats = stats[1];
	  	let ex = basicStats[0].toNumber();
		let ld = basicStats[1].toNumber();
	   	let ec = basicStats[2].toNumber();
	   	let sok = basicStats[3].toNumber();
	   	let vhash = basicStats[4].toNumber();
	   	let acc = basicStats[5].toNumber();
	   	let lvl = basicStats[6].toNumber();
	   	let childArtifacts = stats[2];

	  	console.log('💎 ----------- Base Artifact ---------- 💎');
        console.log('💎\tName: ' + name);
        console.log('💎\tExperience: ' + ex);
        console.log('💎\tLife Decrement: ' + ld);
        console.log('💎\tExecutionCost: ' + ec);
		console.log('💎\tTotal Socket Slots: ' + sok);
		console.log('💎\tvHash: ' + vhash);
		console.log('💎\tAccuracy: ' + acc);
		console.log('💎\tLevel: ' + lvl);
		console.log('💎\tChildren: ' + childArtifacts);
	  	console.log('💎 ------------------------------------ 💎');


	}

});
