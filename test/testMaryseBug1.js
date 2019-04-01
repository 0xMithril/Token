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
let initialDifficulty = 11445000;
var metadata = 'https://ipfs.io/ipfs/QmTYHdY87Va7Wkef9EQCHS6d5y7JK8RxeYRgcZXj9niYBQ';

contract('Maryse Bug 1 [testMaryseBug1.js]', async (accounts) => {

	var jay = accounts[1];
	var maryse = accounts[2];

	it("should test vRig, vGPU offer, buy and configure", async () => {
	   	let socketArtifact = await ChildArtifact.deployed();
		let booster = await VirtualMiningBoard.deployed();
		let vrigMarket = await VRIGMarket.deployed();
		let vgpuMarket = await VGPUMarket.deployed();
		let mithril = await MithrilToken.deployed();

		// setup
		mithril.transfer(jay, 500000, {from: accounts[0]});
		mithril.transfer(maryse, 500000, {from: accounts[0]});

		// create vRig for jay
	   	let result = await booster.mint.call(jay, "Awesome vRig", statistics, metadata);
	   				 await booster.mint(jay, "Awesome vRig", statistics, metadata);
	   	let rigId = result.toNumber();

	   	// create vGPU
	   	result = await socketArtifact.mint.call(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		   			 await socketArtifact.mint(jay, "Virtual GPU 80 GHs", 1, [1049810], metadata);
		let gpuId1 = result.toNumber();

		// add vgpu to vrig
		// await booster.addChildArtifact(rigId, gpuId1, {from: jay});
		
		// offer vgpu
		await socketArtifact.approve(vgpuMarket.address, gpuId1, {from: jay});
		await vgpuMarket.offer(gpuId1, 7777, {from: jay});
		assert.equal(jay, await socketArtifact.ownerOf(gpuId1));
		console.log( await vgpuMarket.get(gpuId1) );
		assert( await vgpuMarket.get(gpuId1) == 7777 );
		assert( await vgpuMarket.size() == 1 );

		// offer vRig
		await booster.approve(vrigMarket.address, rigId, {from: jay});
		await vrigMarket.offer(rigId, 7777, {from: jay});
		assert.equal(jay, await booster.ownerOf(rigId));
		console.log( await vrigMarket.get(rigId) );
		assert( await vrigMarket.get(rigId) == 7777 );
		assert( await vrigMarket.size() == 1 );
		
		
		// buy vRig
		assert(await mithril.balanceOf(maryse) > 7777);
		await mithril.approve(vrigMarket.address, 7777, {from: maryse});
		await vrigMarket.buy(rigId, {from: maryse});
		assert.equal(maryse, await booster.ownerOf(rigId));
		expectThrow( vrigMarket.get(rigId) );
		
		// buy vgpu
		assert(await mithril.balanceOf(maryse) > 7777);
		await mithril.approve(vgpuMarket.address, 7777, {from: maryse});
		await vgpuMarket.buy(gpuId1, {from: maryse});
		assert.equal(maryse, await socketArtifact.ownerOf(gpuId1));
		expectThrow( vgpuMarket.get(gpuId1) );
		
		let vgpus = [];
		vgpus.push(gpuId1);

		await booster.configureChildren(rigId, vgpus, {from: maryse});



	});

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