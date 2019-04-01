var ChildArtifact = artifacts.require("./ChildArtifact.sol");
var VirtualMiningBoard = artifacts.require("./VirtualMiningBoard.sol");
var MockMineableToken = artifacts.require("./MockMineableToken.sol");
var MockMineableTokenFactory = artifacts.require("./MockMineableTokenFactory.sol");
var MithrilTokenQuarry = artifacts.require("./MithrilTokenQuarry.sol");
var MineableToken = artifacts.require("./MineableToken.sol");


let ex = 1000;
let ld = 1;
let ec = 0;
let sok = 10;
let vhash = 0;
let acc = 100;
let lvl = 1;

var statistics = [ex,ld,ec,sok,vhash,acc,lvl];
let initialDifficulty = 11445000;

var metadata = 'https://ipfs.io/ipfs/QmTYHdY87Va7Wkef9EQCHS6d5y7JK8RxeYRgcZXj9niYBQ';
const erc918Metadata = 'https://ipfs.io/ipfs/QmaEA2cB9dKvcPZh49yuNnaa9smhQfw8baBsh4XuT6dqFP';

contract('vHash tests [testvHash.js]', async (accounts) => {
	var jay = accounts[1];
	var maryse = accounts[2];

	it("should test virtual hashing", async () => {
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();

		// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		let gpuId1 = result.toNumber();

		// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		let gpuId2 = result.toNumber();

		let estimatedStats = await booster.checkMerged(rigId, [gpuId1, gpuId2]);
		console.log("Estimated Statistics: " + estimatedStats);
	});

	it("should test virtual hashing", async () => {
	    
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();
		let mineableTokenFactory = await MockMineableTokenFactory.deployed();

		// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		let gpuId1 = result.toNumber();
		await booster.addChildArtifact(rigId, gpuId1, {from: jay});

		for (var i = 0; i < 3; i++) {
		   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 5, [1049810], metadata);
		   			 	 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 5, [1049810], metadata);
		   	gpuId1 = result.toNumber();
	//	   	displaySocketArtifact( await socketArtifact.artifactAt(gpuId1) );
		  	await booster.addChildArtifact(rigId, gpuId1, {from: jay});
		}

		// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		gpuId1 = result.toNumber();
		await booster.addChildArtifact(rigId, gpuId1, {from: jay});


	//  	displayBaseStats(booster, rigId);
	//  	displayMergedStats(booster, rigId);

	  	var mineableAddress = await createMineable(mineableTokenFactory);
		let mockMineable = await MockMineableToken.at(mineableAddress);
	  	
	  	await mockMineable.installBooster(rigId, {from: jay});

	  	// mining difficulty has been reduced to 908 from 11445000
	  	//assert.equal(await mockMineable.getMiningDifficulty({from: jay}), 908);

	  	// mining difficulty has been reduced to 1 from 11445000
	  	assert.equal(await mockMineable.getMiningDifficulty({from: jay}), 1);

	    await displayMergedStats(booster, rigId);

	    const count = 1;
	    for (var i = 0; i < count; i++) {
	    	//console.log('----> mining diff1: ' + await mockMineable.getMiningDifficulty());
	      	console.log('----> mining diff: ' + await mockMineable.getMiningDifficulty({ from: jay }));
	      	// workaround - have to call mint with two parameters due to truffle bug re: solidity overloaded functions
	        // https://github.com/trufflesuite/truffle/issues/569 
	      	let txn = await mockMineable.mint('0x0', '0x0', { from: jay } );
	        console.log('txn.cumulativeGasUsed: ' + txn.receipt.cumulativeGasUsed);

	       // await displayMergedStats(booster, rigId);

	    }

	   	await displayMergedStats(booster, rigId);
	   	

	});


	it("should test configure Children", async () => {
	    
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();
		let mineableTokenFactory = await MockMineableTokenFactory.deployed();

		var vgpus = [];

		// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		let gpuId1 = result.toNumber();
		vgpus.push(gpuId1);

		for (var i = 0; i < 3; i++) {
		   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 5, [1049810], metadata);
		   			 	 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 5, [1049810], metadata);
		   	gpuId1 = result.toNumber();
		   	vgpus.push(gpuId1);
		}

		// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		gpuId1 = result.toNumber();
		vgpus.push(gpuId1);

		console.log( 'vGPUs: ' + vgpus);

		let confTxn = await booster.configureChildren(rigId, vgpus, {from: jay});

		console.log('confTxn.cumulativeGasUsed: ' + confTxn.receipt.cumulativeGasUsed);


		console.log( 'vRig Children: ' + await booster.childArtifacts(rigId) );
	});


/*	

	it("should test virtual hashing when vGPU power is greater than network hash", async () => {
	    
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();
		let mineableTokenFactory = await MockMineableTokenFactory.deployed();

		// vGPU 1
	   	let result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", [1079810]);
	   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", [1079810]);
	   	let gpuId1 = result.toNumber();

	   	displaySocketArtifact( await socketArtifact.artifactAt(gpuId1) );

	   	// vGPU 2
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", [1079810]);
	   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", [1079810]);
	   	let gpuId2 = result.toNumber();

	   	displaySocketArtifact( await socketArtifact.artifactAt(gpuId2) );

	   	// create vRig for jay
	   	result = await booster.mint.call(jay, "Awesome vRig", statistics);
	   				 await booster.mint(jay, "Awesome vRig", statistics);
	   	let rigId = result.toNumber();

	  	await booster.addChildArtifact(rigId, gpuId1, {from: jay});
	  	await booster.addChildArtifact(rigId, gpuId2, {from: jay});
	  	displayBaseStats(booster, rigId);
	  	displayMergedStats(booster, rigId);


	  	var mineableAddress = await createMineable(mineableTokenFactory);
		let mockMineable = await MockMineableToken.at(mineableAddress);
	  	
	  	await mockMineable.installBooster(rigId, {from: jay});

	  	// mining difficulty has been reduced to 1 from 11445000
	  	assert.equal(await mockMineable.getMiningDifficulty({from: jay}), 1);

	});

*/

	async function createMineable(factory) {
		// call the createMineable transaction
		let mineableTxn = await factory.createMineable("0xNEW","Example New Mineable Token",18, 1000000, 100, 1024, initialDifficulty, 10, erc918Metadata);

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

	
	/* Helper functions */
	async function displaySocketArtifact(stats) {

		//console.log(stats);

	  	let name = stats[0];
        let parent = stats[1].toNumber();
        let life = stats[2];
        let modifiers = stats[3];

        console.log('\t💎 ------- Socket Artifact -------- 💎');
        console.log('\t💎\tName: ' + name);
        console.log('\t💎\tParent: ' + parent);
        console.log('\t💎\tLife: ' + life);
        //console.log('\t💎\tModifiers: ' + modifiers);
        console.log('\t💎\tModifiers: ');
        for(var j = 0; j < modifiers.length; j++){
        	displayModifier(modifiers[j]);
        }  
        console.log('\t💎 -------------------------------- 💎');
        console.log();

	}

	async function displayBaseStats(booster, id) {
		displayBoosterStats(await booster.baseStats(id), '💎 ----------- Base Statistics ---------- 💎');
	}

	async function displayMergedStats(booster, id) {
		displayBoosterStats(await booster.mergedStats(id), '💎 ----------- Merged Statistics ---------- 💎');
	}

	async function displayBoosterStats(stats, title) {

		let socketArtifact = await ChildArtifact.deployed();


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

	  	console.log(title);
        console.log('💎\tName: ' + name);
        console.log('💎\tExperience: ' + ex);
        console.log('💎\tLife Decrement: ' + ld);
        console.log('💎\tExecutionCost: ' + ec);
		console.log('💎\tTotal Socket Slots: ' + sok);
		console.log('💎\tvHash: ' + vhash);
		console.log('💎\tAccuracy: ' + acc);		
		console.log('💎\tLevel: ' + lvl);
		console.log('💎\tChildren: ' + childArtifacts);
		for(var i = 0 ; i < childArtifacts.length; i++){
			displaySocketArtifact( await socketArtifact.artifactAt( childArtifacts[i] ) );
		}

	  	console.log('💎 ------------------------------------ 💎');


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
            9 - add exp value -> 808 = 8 * 10^8 = 800000000
                              -> 420 = 4 * 10^20

            examples:
            1009 -> 1, 009: add 9
            5312 -> 5, 312: add 312%
            6075 -> 1, 075: substract 75%
            7100 -> 7, 100: require greater than 100
    */
	function displayModifier(modifier){
		var tuple = parseCommand(modifier);
		var position = tuple[0];
		var value = tuple[1];
		var op = tuple[2];
		var mod = tuple[3];

		if(op == 1) console.log('\t💎\t[+] Add '+ mod +' to ' + getPositionName(position) );
		if(op == 2) console.log('\t💎\t[-] Subtract '+ mod +' from ' + getPositionName(position) );
		if(op == 3) console.log('\t💎\t[*] Multiply '+ getPositionName(position) +' by ' + mod );
		if(op == 4) console.log('\t💎\t[/] Divide '+ getPositionName(position) +' by ' + mod );
		if(op == 5) console.log('\t💎\t[+%] Add '+ mod +'% to ' + getPositionName(position) );
		if(op == 6) console.log('\t💎\t[-%] Subtract '+ mod +'% from ' + getPositionName(position) );
		if(op == 7) console.log('\t💎\tRequire '+ getPositionName(position) +' > ' + mod );
		if(op == 8) console.log('\t💎\tRequire '+ getPositionName(position) +' < ' + mod );
		if(op == 9) console.log('\t💎\tAdd ' + parseExponent(mod)  + ' to ' +  getPositionName(position));	

	}

	function getPositionName(position) {
		if(position == 0){
			return 'Experience';
		}else if (position == 1){
			return 'Life Decrement';
		}else if (position == 2){
			return 'Execution Cost';
		}else if (position == 3){
			return 'Socket Count';
		}else if (position == 4){
			return 'Virtual Hash';
		}else if (position == 5){
			return 'Accuracy';
		}else if (position == 6){
			return 'Level';
		}else{
			return '[' + position + ']';
		}
	}

	function parseExponent(op) {
		var s = new String(op);

		var multiplier = s.substring(0,1);
		var exp = s.substring(1,3);

		return new Number(multiplier) + '*10^' + new Number(exp);
	}

	function parseCommand(command) {
		var s = new String(command);
		var position = s.substring(1, 3);
		var value = s.substring(3);

		var op = value.substring(0,1);
		var modValue = value.substring(1,4);

        return [new Number(position), new Number(value), new Number(op), new Number(modValue)];
	}

	async function expectThrow(promise) {
	  try {
	    await promise;
	  } catch (error) {
	    // TODO: Check jump destination to destinguish between a throw
	    //       and an actual invalid jump.
	    const invalidOpcode = error.message.search('invalid opcode') >= 0;
	    // TODO: When we contract A calls contract B, and B throws, instead
	    //       of an 'invalid jump', we get an 'out of gas' error. How do
	    //       we distinguish this from an actual out of gas event? (The
	    //       ganache log actually show an 'invalid jump' event.)
	    const outOfGas = error.message.search('out of gas') >= 0;
	    const revert = error.message.search('revert') >= 0;
	    assert(
	      invalidOpcode || outOfGas || revert,
	      'Expected throw, got \'' + error + '\' instead',
	    );
	    return;
	  }
	  assert.fail('Expected throw not received');
	};


});
