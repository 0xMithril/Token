var ChildArtifact = artifacts.require("./ChildArtifact.sol");
var VirtualMiningBoard = artifacts.require("./VirtualMiningBoard.sol");
var VGPUMarket = artifacts.require("./VGPUMarket.sol");
var VRIGMarket = artifacts.require("./VRIGMarket.sol");
var MithrilToken = artifacts.require("./MithrilToken.sol");

let ex = 1000;
let ld = 1;
let ec = 0;
let sok = 10;
let vhash = 0;
let acc = 100;
let lvl = 1;

var statistics = [ex,ld,ec,sok,vhash,acc,lvl];
var initialDifficulty = 11445000;
var metadata = 'https://ipfs.io/ipfs/QmTYHdY87Va7Wkef9EQCHS6d5y7JK8RxeYRgcZXj9niYBQ';

contract('ArtifactMarket Tests [testArtifactMarket.js]', async (accounts) => {
	var jay = accounts[1];
	var maryse = accounts[2];

	it("should setup accounts", async () => {
		let mithril = await MithrilToken.deployed();

		// setup
		mithril.transfer(jay, 500000, {from: accounts[0]});
		mithril.transfer(maryse, 500000, {from: accounts[0]});

	});

	function toHex(n) {
		return '0x' + n.toString(16).padStart(8, '0')
	}

	it("should test vRig offer and buy", async () => {
	    
		let booster = await VirtualMiningBoard.deployed();
		let market = await VRIGMarket.deployed();
		let mithril = await MithrilToken.deployed();

		// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	console.log('result: ' + result);
	   	let rigId = result.toNumber();
	   	console.log('rigId: ' + rigId);
	   	console.log('web3.fromDecimal(rigId): ' + web3.fromDecimal(rigId));
	    console.log('web3.toHex(rigId): ' + web3.toHex(rigId));

		// offer vRig
		await booster.approve(market.address, rigId, {from: jay});
		await market.offer(rigId, 7777, {from: jay});
		assert.equal(jay, await booster.ownerOf(rigId));
		console.log( await market.get(rigId) );
		assert( await market.get(rigId) == 7777 );
		assert( await market.size() == 1 );
		
		
		for(var i = 0; i < await market.size(); i++) {
			let art = await market.getAt(i);
			console.log('market artifact[0]: ' + art[0]);
			console.log('market artifact[1]: ' + art[1]);
		}
		
		// buy vRig
		assert(await mithril.balanceOf(maryse) > 7777);

		//await mithril.approve(market.address, 7777, {from: maryse});
		//await market.buy(rigId, {from: maryse});
		//await mithril.approveAndCall(market.address, 7777, '0x00000001', {from: maryse});
		await mithril.approveAndCall(market.address, 7777, toHex(rigId), {from: maryse});
		console.log('====> approveAndCall WORKED!!');
		/*
		mithril.approveAndCall(market.address, 7777, "0x00012345", {from: maryse})
			.then(function(result) {
		  	// Do something with the result or continue with more transactions.
		  	console.log('====> approveAndCall WORKED!!');
		  	console.log(result);
		}).catch(function(err) {
		    // Easily catch all errors along the whole execution.
		    console.log("ERROR! " + err.message);
		});
		*/
		
		assert.equal(maryse, await booster.ownerOf(rigId));
		expectThrow( market.get(rigId) );
		

	});

	it("should test vrig offer and revoke", async () => {
	    
		let booster = await VirtualMiningBoard.deployed();
		let market = await VRIGMarket.deployed();
		let mithril = await MithrilToken.deployed();

		// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

		// offer vRig
		await booster.approve(market.address, rigId, {from: jay});
		await market.offer(rigId, 7777, {from: jay});
		assert.equal(jay, await booster.ownerOf(rigId));
		console.log( await market.get(rigId) );
		assert( await market.get(rigId) == 7777 );
		assert( await market.size() == 1 );
		
		// revoke
		await market.revoke(rigId, {from: jay});
		expectThrow( market.get(rigId) );
		assert( await market.size() == 0 );

	});


	it("should test vrig offer revoke offer", async () => {
	    
		let booster = await VirtualMiningBoard.deployed();
		let market = await VRIGMarket.deployed();
		let mithril = await MithrilToken.deployed();

		// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

		// offer
		await booster.approve(market.address, rigId, {from: jay});
		await market.offer(rigId, 7777, {from: jay});
		assert.equal(jay, await booster.ownerOf(rigId));
		console.log( await market.get(rigId) );
		assert( await market.get(rigId) == 7777 );
		assert( await market.size() == 1 );
		
		// revoke
		await market.revoke(rigId, {from: jay});
		expectThrow( market.get(rigId) );
		assert( await market.size() == 0 );

		// offer
		await booster.approve(market.address, rigId, {from: jay});
		await market.offer(rigId, 1111, {from: jay});
		assert.equal(jay, await booster.ownerOf(rigId));
		console.log( await market.get(rigId) );
		assert( await market.get(rigId) == 1111 );
		assert( await market.size() == 1 );

	});	

	it("should test vgpu offer and buy", async () => {
	    
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();
		let market = await VGPUMarket.deployed();
		let mithril = await MithrilToken.deployed();

	   	// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		let gpuId1 = result.toNumber();
		
		// offer vgpu
		await socketArtifact.approve(market.address, gpuId1, {from: jay});
		await market.offer(gpuId1, 7777, {from: jay});
		assert.equal(jay, await socketArtifact.ownerOf(gpuId1));
		console.log( await market.get(gpuId1) );
		assert( await market.get(gpuId1) == 7777 );
		assert( await market.size() == 1 );
		
		
		for(var i = 0; i < await market.size(); i++) {
			let art = await market.getAt(i);
			console.log('market artifact[0]: ' + art[0]);
			console.log('market artifact[1]: ' + art[1]);
		}
		

		// buy vgpu
		assert(await mithril.balanceOf(maryse) > 7777);
		//await mithril.approve(market.address, 7777, {from: maryse});
		//await market.buy(gpuId1, {from: maryse});
		await mithril.approveAndCall(market.address, 7777, toHex(gpuId1), {from: maryse});
		assert.equal(maryse, await socketArtifact.ownerOf(gpuId1));
		expectThrow( market.get(gpuId1) );
		

	});

	it("should test vgpu offer and revoke", async () => {
	    
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();
		let market = await VGPUMarket.deployed();
		let mithril = await MithrilToken.deployed();

	   	// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		let gpuId1 = result.toNumber();
		
		// offer vgpu
		await socketArtifact.approve(market.address, gpuId1, {from: jay});
		await market.offer(gpuId1, 7777, {from: jay});
		assert.equal(jay, await socketArtifact.ownerOf(gpuId1));
		console.log( await market.get(gpuId1) );
		assert( await market.get(gpuId1) == 7777 );
		assert( await market.size() == 1 );
		
		// revoke
		await market.revoke(gpuId1, {from: jay});
		expectThrow( market.get(gpuId1) );
		assert( await market.size() == 0 );

	});

	it("should test vgpu offer, revoke, offer", async () => {
	    
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();
		let market = await VGPUMarket.deployed();
		let mithril = await MithrilToken.deployed();

	   	// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		let gpuId1 = result.toNumber();
		
		// offer
		await socketArtifact.approve(market.address, gpuId1, {from: jay});
		await market.offer(gpuId1, 7777, {from: jay});
		assert.equal(jay, await socketArtifact.ownerOf(gpuId1));
		console.log( await market.get(gpuId1) );
		assert( await market.get(gpuId1) == 7777 );
		assert( await market.size() == 1 );
		
		// revoke
		await market.revoke(gpuId1, {from: jay});
		expectThrow( market.get(gpuId1) );
		assert( await market.size() == 0 );

		// offer
		await market.offer(gpuId1, 8888, {from: jay});
		assert.equal(jay, await socketArtifact.ownerOf(gpuId1));
		console.log( await market.get(gpuId1) );
		assert( await market.get(gpuId1) == 8888 );
		assert( await market.size() == 1 );

	});

	it("should fail vgpu offer with children attached", async () => {
	    
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();
		let market = await VGPUMarket.deployed();
		let mithril = await MithrilToken.deployed();

		// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		let gpuId1 = result.toNumber();
		
		await booster.addChildArtifact(rigId, gpuId1, {from: jay});

		// offer vgpu
		await socketArtifact.approve(market.address, gpuId1, {from: jay});
		expectThrow ( market.offer(gpuId1, 7777, {from: jay}) );
		

	});

/*
	it("should test vrig offer and buy", async () => {
	    
		let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();
		let market = await VGPUMarket.deployed();
		let mithril = await MithrilToken.deployed();

		// setup
		mithril.transfer(jay, 500000, {from: accounts[0]});
		mithril.transfer(maryse, 500000, {from: accounts[0]});

		// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics);
	   				 await booster.mint(jay, "Awesome vRig", statistics);
	   	let rigId = result.toNumber();


	   	// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810]);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810]);
		let gpuId1 = result.toNumber();
	
		await booster.addChildArtifact(rigId, gpuId1, {from: jay});

		// offer vrig
		await booster.approve(market.address, rigId, {from: jay});
		await market.offerVrig(rigId, 8888, {from: jay});
		assert.equal(false, await booster.hasChildren(rigId));
		assert.equal(jay, await booster.ownerOf(rigId));
		assert( await market.vrigMarket.call(rigId) == 8888 );

		// buy vrig
		assert(await mithril.balanceOf(maryse) > 8888);
		await mithril.approve(market.address, 8888, {from: maryse});
		await market.buyVrig(rigId, {from: maryse});
		assert.equal(maryse, await booster.ownerOf(rigId));
		assert( await market.vrigMarket.call(rigId) == 0 );

	});
*/

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
