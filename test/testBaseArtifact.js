var ChildArtifact = artifacts.require("./ChildArtifact.sol");
var VirtualMiningBoard = artifacts.require("./VirtualMiningBoard.sol");


/*

	Base Virtual Mining Board Device use to affect Mining statistics

		[0]: experience ( total alltime nubmer of successful mintings )
		[1]: lifeDecrement ( defaulted to 1, this can optionally be increased in 'virtual overclocking' scenarios)
		[2]: executionCost (additional cost in Mithril)
		[3]: sockets ( # of slots for adding vGPUs or other components )
		[4]: vHash ( the combined current Virtual Hashing power, default to 0 )
		[5]: accuracy ( total reward as a percent default to 100 )
		[6]: level

	    Simple Operations :
	        1 - add
	        2 - substract
	        3 - multiply
	        4 - divide
	        5 - add percentage to
	        6 - subtract percentage from
	        7 - require greater than
	        8 - require less than
	        9 - add exp value -> 808 = 8 * 10^8 = 800000000
	                          -> 420 = 4 * 10^20
	                          -> 700 = 7 * 10^0 = 7

	        examples:
	            1009 -> 1, 009: add 9
	            5312 -> 5, 312: add 312%
	            6075 -> 1, 075: substract 75%
	            7100 -> 7, 100: require greater than 100
    
*/

let ex = 1000;
let ld = 1;
let ec = 0;
let sok = 10;
let vhash = 0;
let acc = 100;
let lvl = 1;

var statistics = [ex,ld,ec,sok,vhash,acc,lvl];

// [1000,2000,2000,1,0,3600,10,0,100,1]
var metadata = 'https://ipfs.io/ipfs/QmTYHdY87Va7Wkef9EQCHS6d5y7JK8RxeYRgcZXj9niYBQ';

contract('Booster tests [testBaseArtifact.js]', async (accounts) => {
	var jay = accounts[1];
	var maryse = accounts[2];

	it("should test add % statistic", async () => {
		
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();

	   	// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	assert.equal(await booster.ownerOf(rigId), jay);

	   	// create vGPU for jay
	   	result = await socketArtifact.mint.call(jay, "Blue Gem", 100, [1055005], metadata);
	   			 await socketArtifact.mint(jay, "Blue Gem", 100, [1055005], metadata);
	   	let gpuId = result.toNumber();

	   	await booster.addChildArtifact(rigId, gpuId, {from: jay});

	   	let stats = await booster.mergedStats(gpuId);
	   	let name = stats[0];
	   	let accuracy = stats[1][5].toNumber();

	   	assert.equal(accuracy, acc*1.05);
	   	
	});

	it("should test minus % statistic", async () => {
		
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();

	   	// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	assert.equal(await booster.ownerOf(rigId), jay);

	   	// create vGPU for jay
	   	result = await socketArtifact.mint.call(jay, "Blue Gem", 100, [1056005], metadata);
	   			 await socketArtifact.mint(jay, "Blue Gem", 100, [1056005], metadata);
	   	let gpuId = result.toNumber();

	   	await booster.addChildArtifact(rigId, gpuId, {from: jay});

	   	let stats = await booster.mergedStats(gpuId);
	   	let name = stats[0];
	   	let accuracy = stats[1][5].toNumber();

	   	assert.equal(accuracy, acc*0.95);
	   	
	});

	it("GPU requires rig level 5", async () => {
		
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();

	   	// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	assert.equal(await booster.ownerOf(rigId), jay);

	   	// create vGPU that requires rig level 5
	   	result = await socketArtifact.mint.call(jay, "Blue Gem", 100, [1066005,1077005], metadata);
	   			 await socketArtifact.mint(jay, "Blue Gem", 100, [1066005,1077005], metadata);
	   	let gpuId = result.toNumber();

	  	await expectThrow( booster.addChildArtifact(rigId, gpuId, {from: jay}) );

	  	// create vGPU that requires rig level 1
	   	result = await socketArtifact.mint.call(jay, "Blue Gem", 100, [1086005], metadata);
	   			 await socketArtifact.mint(jay, "Blue Gem", 100, [1066005], metadata);
	   	gpuId = result.toNumber();

	   	booster.addChildArtifact(rigId, gpuId, {from: jay});
	   	
	});

	it("should add 3 vGPUs to 1 vRig and test statistics", async () => {
	    
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();

	   	let result = await socketArtifact.mint.call(jay, "Virtual GPU 800 MHs", 100, [1059808], metadata);
	   			 await socketArtifact.mint(jay, "Virtual GPU 800 MHs", 100, [1059808], metadata);
	   	let gpuId1 = result.toNumber();

	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 200 MHs", 100, [1059208], metadata);
	   			 await socketArtifact.mint(jay, "Virtual GPU 200 MHs", 100, [1059208], metadata);
	   	let gpuId2 = result.toNumber();

	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 600 MHs", 100, [1059608], metadata);
	   			 await socketArtifact.mint(jay, "Virtual GPU 600 MHs", 100, [1059608], metadata);
	   	let gpuId3 = result.toNumber();

	   	displaySocketArtifact( await socketArtifact.artifactAt(gpuId1) );
	   	displaySocketArtifact( await socketArtifact.artifactAt(gpuId2) );
	   	displaySocketArtifact( await socketArtifact.artifactAt(gpuId3) );

	   	/* 
	   		Mint a new booster 
	   	*/
	   	// create vRig for jay
	   	result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	//console.log(await booster.hello());

	  	await booster.addChildArtifact(rigId, gpuId1, {from: jay});
	  	displayBaseStats(booster, rigId);
	  	displayMergedStats(booster, rigId);
	  	await booster.addChildArtifact(rigId, gpuId2, {from: jay});
	  	displayBaseStats(booster, rigId);
	  	displayMergedStats(booster, rigId);
	  	await booster.addChildArtifact(rigId, gpuId3, {from: jay});
	  	displayBaseStats(booster, rigId);
	  	displayMergedStats(booster, rigId);

	  	// remove one (this removes by index) - so we remove from position [1]
	  	await booster.removeChildArtifact(rigId, 1, {from: jay});
	  	displayBaseStats(booster, rigId);
	  	displayMergedStats(booster, rigId);

	});

	it("should transfer a vRig to another user", async () => {
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();

	   	// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	console.log('result: ' + result);
	   	let rigId = result.toNumber();
	   	console.log('rigId: ' + rigId);

	   	assert.equal(await booster.ownerOf(rigId), jay);

	   	// transfer booster to maryse
	   	await booster.transfer(maryse, rigId, { from: jay });
	    assert.equal(await booster.ownerOf(rigId), maryse);

	});

	it("should transfer a vRig with vGPUs to another user", async () => {
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();

	   	// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	assert.equal(await booster.ownerOf(rigId), jay);

	   	// create vGPU for jay
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 800 MHs", 100, [1059808], metadata);
	   			 await socketArtifact.mint(jay, "Virtual GPU 800 MHs", 100, [1059808], metadata);
	   	let gpuId = result.toNumber();

	   	// assert vGPU ownership
	   	assert.equal(await socketArtifact.ownerOf(gpuId), jay);

	   	// expect this to fail from a user that is not the owner
	   	await expectThrow( booster.addChildArtifact(rigId, gpuId, {from: maryse}) );

	   	await booster.addChildArtifact(rigId, gpuId, {from: jay});
	   	displayBaseStats(booster, rigId);


	   	// transfer rig to maryse
	   	await booster.transfer(maryse, rigId, { from: jay });
	   	// assert rig ownership
	    assert.equal(await booster.ownerOf(rigId), maryse);
	    // assert vGPU ownership - the vGPU should still belong to jay, since only
	    // the rig was transferred
	   	assert.equal(await socketArtifact.ownerOf(gpuId), jay);

	   	displayBaseStats(booster, rigId);

	   	// transfer vGPU
	   	await socketArtifact.transfer(maryse, gpuId, { from: jay });
	   	assert.equal(await socketArtifact.ownerOf(gpuId), maryse);

	   	await expectThrow( booster.addChildArtifact(rigId, gpuId, {from: jay}) );
	   	await booster.addChildArtifact(rigId, gpuId, {from: maryse});
	   	displayBaseStats(booster, rigId);

	});



	/*
		Helper functions
	*/
	function displaySocketArtifact(stats) {

		//console.log(stats);

	  	let name = stats[0];
        let parent = stats[1].toNumber();
        let modifiers = stats[2];

        console.log('💎 ------- Socket Artifact -------- 💎');
        console.log('💎\tName: ' + name);
        console.log('💎\tParent: ' + parent);
        console.log('💎\tModifiers: ' + modifiers);
        for(var j = 0; j < modifiers.length; j++){
        	//console.log('💎\t Mod: ' + modifiers[j]);
        	displayModifier(modifiers[j]);
        }  
        console.log('💎 -------------------------------- 💎');
        console.log();

	}

	async function displayBaseStats(booster, id) {
		displayBoosterStats(await booster.baseStats(id), '💎 ----------- Base Statistics ---------- 💎');
	}

	async function displayMergedStats(booster, id) {
		displayBoosterStats(await booster.mergedStats(id), '💎 ----------- Merged Statistics ---------- 💎');
	}

	function displayBoosterStats(stats, title) {

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

		if(op == 1) console.log('💎\t\t[+] '+ mod +', stat[' + position + ']' );
		if(op == 2) console.log('💎\t\t[-] '+ mod +', stat[' + position + ']' );
		if(op == 3) console.log('💎\t\t[*] '+ mod +', stat[' + position + ']' );
		if(op == 4) console.log('💎\t\t[/] '+ mod +', stat[' + position + ']' );
		if(op == 5) console.log('💎\t\t[+%] '+ mod +', stat[' + position + ']' );
		if(op == 6) console.log('💎\t\t[-%] '+ mod +', stat[' + position + ']' );
		if(op == 7) console.log('💎\t\t[require >] '+ mod +', stat[' + position + ']' );
		if(op == 8) console.log('💎\t\t[require <] '+ mod +', stat[' + position + ']' );
		if(op == 9) console.log('💎\t\t[set] '+ parseExponent(mod) +', stat[' + position + ']' );
		

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
