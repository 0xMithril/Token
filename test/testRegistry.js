var MithrilTokenQuarry = artifacts.require("./MithrilTokenQuarry.sol");

contract('Quarry Registry Tests [testRegistry.js]', async (accounts) => {

	it("should populate Mineables Registry and query all values", async () => {
	    let quarry = await MithrilTokenQuarry.deployed();

	    await quarry.putMineable("0x0", "0x0b");
	    await quarry.putMineable("0x1", "0x1b");
	    await quarry.putMineable("0x2", "0x2b");
	    await quarry.putMineable("0x3", "0x3b");
	    await quarry.putMineable("0x4", "0x4b");

	    let count = await quarry.mineableSize.call();
	    let c = count.toNumber();
	    console.log(c);

	    assert.equal(5, c);

	    for (i = 0; i < c; i++) {
	    	console.log('------------------------------------------------------------------------------------------------');
	    	// test get by index
	    	let getKeyAt = await quarry.getMineableKeyAt(i);
		    console.log('getKeyAt : ' + getKeyAt);

		    let getAt = await quarry.getMineableAt(i);
		    console.log('getAt : ' + getAt);

		    let tuple = await quarry.getMineableTuple(i);
		    console.log('getTuple : ' + tuple);
		    console.log(tuple[0]);
		    console.log(tuple[1]);

		    // test get with key
		    let get = await quarry.getMineable(getKeyAt);
		   	console.log('get : ' + get);
		   	assert.equal(getAt, get);

		}

	});

});
