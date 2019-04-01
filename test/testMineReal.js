

// 2^234
const initialTarget = '27606985387162255149739023449108101809804435888681546220650096895197184';

contract('Mine Real Tests [testMineReal.js]', async (accounts) => {

	it("mine until it finds a result", async () => {

		/*
		    0x417a6c65687269614dfab46f74e9d9000000000032e1ff57a75e33f84e0b8823, //nonce
            0x000002ff6be41e51468bc7b8e3333fd173517d928a566779da43e0d3127832ea, //challenge_digest
            0xe4112ce87f99d13f6ab26304758f98d9960a40eed21246455915f7de215e6be9, // challenge_number
            2^234,                                                              // testTarget
            0x023aB06c4bb4eBB561631877ec00903473bda5BD,                         // contract
            0x1DA6D6E6Cd1343eC41a5427075b32F2678e0bc8D,                         // sender
            0x1f9c668a86a7a85920c65a0799b3bf120b5d1930                          // resulting xor


            uint256 xor = uint256(testsender) ^ uint256(testContract);
          require(xor == resulting_xor);
           
          bytes32 digest = keccak256(challenge_number, xor, nonce );
		*/

		let challenge_number = 0xe4112ce87f99d13f6ab26304758f98d9960a40eed21246455915f7de215e6be9;
		let xord = 0x023aB06c4bb4eBB561631877ec00903473bda5BD ^ 0x1DA6D6E6Cd1343eC41a5427075b32F2678e0bc8D;
		let nonce = 0x417a6c65687269614dfab46f74e9d9000000000032e1ff57a75e33f84e0b8823;
		
		let res = await web3.sha3( "e4112ce87f99d13f6ab26304758f98d9960a40eed21246455915f7de215e6be9" 
								   + "1f9c668a86a7a85920c65a0799b3bf120b5d1930"
								   + "417a6c65687269614dfab46f74e9d9000000000032e1ff57a75e33f84e0b8823"
								   , {encoding:"hex"});

		// let res = await web3.sha3( web3.toHex("test1") + "0AbdAce70D3790235af448C88547603b945604ea", {encoding:"hex"});

		console.log(res);
	});

});
