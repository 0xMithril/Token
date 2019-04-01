const ethUtil = require("ethereumjs-util");

var MithrilToken = artifacts.require("./MithrilToken.sol");
var VirtualMiningBoard = artifacts.require("./VirtualMiningBoard.sol");
var MithrilTokenQuarry = artifacts.require("./MithrilTokenQuarry.sol");
var FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var MineableToken = artifacts.require("./MineableToken.sol");
var MineableTokenFactory = artifacts.require("./MineableTokenFactory.sol");
var MockMineableToken = artifacts.require("./MockMineableToken.sol");
var MockMineableTokenFactory = artifacts.require("./MockMineableTokenFactory.sol");

var ChildArtifact = artifacts.require("./ChildArtifact.sol");

const initialDiff = 0;

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

contract('Delegated Minting Tests [testDelegateMint.js]', async (accounts) => {

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

		var mineableAddress = await createMineable(mineableTokenFactory);
		let mockMineable = await MineableToken.at(mineableAddress);

		// create a new Mock Mineable Token
	    console.log('Creating MockMineableToken...');
	    
	    /* 
	   		Mint a new booster 
	   	*/
	   	let txn = await booster.mint(accounts[1], "Awesome Booster", statistics, metadata);
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

	    // install the booster
	    console.log('install the booster');
	    await mockMineable.installBooster(1, { from: accounts[1]} );

	    console.log('Installed booster: ' + await mockMineable.getInstalledBooster( { from: accounts[1] } ));

	   // txn = await mockMineable.mint(0x0, 0x0, {from: accounts[1]} );

	    //////////////////// build and sign offchain transaction
	    let nonce = 5;
	    // let hash = await mockMineable.delegatedMintHashing(accounts[2], nonce);
	    var functionSig = web3.sha3("delegatedMintHashing(uint256,address)").substring(0,10);
	    console.log('functionSig: ' + functionSig);

	    var hash = web3.sha3( functionSig, nonce, accounts[1], {encoding: 'hex'} )
	    var hashContract = await mockMineable.delegatedMintHashing(nonce, accounts[1]);
	    console.log('Hash:          ' + hash);
	    console.log('Hash(contract):' + hashContract );
	    // assert.equal(hash, hashContract);
	    
		var privateKey = '705a6cdf0971421a29c9fc32ca446f96eb185d35b4532ce7d8f40db8f738e9ae';

	    let sig = signDelegatedMintTxn(nonce, accounts[1], privateKey);

        let recoveredAddress = await mockMineable.recover(hash, sig);
        console.log('accounts[1]:      ' + accounts[1]);
        console.log('recoveredAddress: ' + recoveredAddress);
        assert.equal(accounts[1], recoveredAddress);

        // create a packet to send to third party:
        var packet = {}
        packet.nonce = nonce;
        packet.origin = accounts[1];
        packet.signature = sig;

        console.log(JSON.stringify(packet, null, 4));

	    // Delegate the mint call to account 2
	    txn = await mockMineable.delegatedMint(packet.nonce, packet.origin, packet.signature, { from: accounts[2]} );
	    console.log('delegatedMint -> txn.cumulativeGasUsed: ' + txn.receipt.cumulativeGasUsed);

	    // confirm the adjusted reward was given to account 2
	    assert.equal( (await mockMineable.balanceOf(accounts[2])).toNumber(), 120000000000000000000);
	    // confirm the adjusted reward was not given to account 1
	    assert.equal( (await mockMineable.balanceOf(accounts[1])).toNumber(), 0);

	    for (var i = 0; i <= 3; i++) {
	      console.log('-- Account ' + i + ' --');
	      console.log('Booster: ' + await booster.balanceOf(accounts[i]) );
	      console.log('Mithril: ' + await mithrilToken.balanceOf(accounts[i]));
	      console.log('Mithril: ' + readable( await mithrilToken.balanceOf(accounts[i]) ) );
	      console.log('Token: ' + readable( await mockMineable.balanceOf(accounts[i])) );
	    }

	    console.log('Mithril Supply: ' + readable ( await mithrilToken.totalSupply() ) );
	    console.log('Mithril Minted: ' + readable ( await mithrilToken.tokensMinted.call() ) );

	});

	function signDelegatedMintTxn(nonce, address, privateKey) {
		var functionSig = web3.sha3("delegatedMintHashing(uint256,address)").substring(0,10);
		console.log('functionSig: ' + functionSig)
	    //var hashOf = "0x" + bytes4ToHex(functionSig) + uint256ToHex(nonce) + addressToHex(accounts[1]);
	    //var data = ethUtil.sha3(hashOf);
		//var signature = ethUtil.ecsign(data, new Buffer(privateKey, 'hex')); 
		//var sig = ethUtil.toRpcSig(signature.v, signature.r, signature.s);

		var data = web3.sha3( functionSig, nonce, accounts[1], {encoding: 'hex'} )
		var sig = web3.eth.accounts.sign(web3.utils.toHex(data), privateKey)
		return sig.signature
	}

	function signDelegatedMintTxn2(nonce, address, privateKey) {
		var functionSig = web3.sha3("delegatedMintHashing(uint256,address)").substring(0,10);
		console.log('functionSig: ' + functionSig)
	    var hashOf = "0x" + bytes4ToHex(functionSig) + uint256ToHex(nonce) + addressToHex(accounts[1]);
	    var data = ethUtil.sha3(hashOf);
		var signature = ethUtil.ecsign(data, new Buffer(privateKey, 'hex')); 
		var sig = ethUtil.toRpcSig(signature.v, signature.r, signature.s);
		return sig;
	}

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

	function padLeft0(s, n) {
	  var result = s.toString();
	  while (result.length < n) {
	    result = "0" + result;
	  }
	  return result;
	}

	function bytes4ToHex(bytes4) {
	  if (bytes4.substring(0, 2) == "0x") {
	    return padLeft0(bytes4.substring(2, 10), 8);
	  } else {
	    return padLeft0(bytes4.substring(0, 8), 8);
	  } 
	}

	function addressToHex(address) {
	  if (address.substring(0, 2) == "0x") {
	    return padLeft0(address.substring(2, 42).toLowerCase(), 40);
	  } else {
	    return padLeft0(address.substring(0, 40).toLowerCase(), 40);
	  } 
	}

	function uint256ToHex(number) {
	  var bigNumber = new web3.BigNumber(number).toString(16);
	  if (bigNumber.substring(0, 2) == "0x") {
	    return padLeft0(bigNumber.substring(2, 66).toLowerCase(), 64);
	  } else {
	    return padLeft0(bigNumber.substring(0, 64).toLowerCase(), 64);
	  } 
	}

	function stringToHex(s) {
	  return web3.toHex(s).substring(2);
	}

});
