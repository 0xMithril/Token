var MithrilToken = artifacts.require("./MithrilToken.sol");
//var MithrilMiningBooster = artifacts.require("./MithrilMiningBooster.sol");

var VirtualMiningBoard = artifacts.require("./VirtualMiningBoard.sol");

var MithrilTokenQuarry = artifacts.require("./MithrilTokenQuarry.sol");
var FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var MineableToken = artifacts.require("./MineableToken.sol");
var MineableTokenFactory = artifacts.require("./MineableTokenFactory.sol");
var MockMineableTokenFactory = artifacts.require("./MockMineableTokenFactory.sol");
var ChildArtifact = artifacts.require("./ChildArtifact.sol");
var VirtualMiningBoard = artifacts.require("./VirtualMiningBoard.sol");
var VGPUMarket = artifacts.require("./VGPUMarket.sol");
var VRIGMarket = artifacts.require("./VRIGMarket.sol");

module.exports = function (deployer, network, accounts) {

  deployer.then(async () => {

    console.log('network: ' + network)
    console.log(accounts)
    const owner = accounts[0]
    console.log('owner: ' + owner)
    
    let vgpu = await deployer.deploy(ChildArtifact)
    let vrig = await deployer.deploy(VirtualMiningBoard, ChildArtifact.address, "0xVBD", "Virtual Mining Board")
    let mithril = await deployer.deploy(MithrilToken, VirtualMiningBoard.address)
    let quarry = await deployer.deploy(MithrilTokenQuarry, VirtualMiningBoard.address, MithrilToken.address)
    let factory = await deployer.deploy(MineableTokenFactory, MithrilTokenQuarry.address, MithrilToken.address, VirtualMiningBoard.address)
    await quarry.addMineableRole(factory.address)
    let vgpuMarket = await deployer.deploy(VGPUMarket, MithrilToken.address, ChildArtifact.address)
    let vrigMarket = await deployer.deploy(VRIGMarket, MithrilToken.address, VirtualMiningBoard.address)

    if(network === 'development') {
      let mockFactory = await deployer.deploy(MockMineableTokenFactory, MithrilTokenQuarry.address, MithrilToken.address, VirtualMiningBoard.address)
      await quarry.addMineableRole(mockFactory.address)
      await deployer.deploy(FixedSupplyToken)
    }

    if(network !== 'development') {

      // Virtual GPUs
      for (let i = 0; i < 5; i++) {
        let gpu = await vgpu.mint.call(owner, 'Virtual GPU 1 GHs',1000,[1049109],'https://ipfs.io/ipfs/QmPi1hMtExAxk4pFrUncmbYcskrax2K4nDH7bKG5m8MWYC')
                   await vgpu.mint(owner, 'Virtual GPU 1 GHs',1000,[1049109],'https://ipfs.io/ipfs/QmPi1hMtExAxk4pFrUncmbYcskrax2K4nDH7bKG5m8MWYC')
        console.log('vgpu: ' + gpu.toNumber())
        await vgpu.approve(vgpuMarket.address, gpu.toNumber())
        await vgpuMarket.offer(gpu.toNumber(), '100000000000000000000')
      }

      // Virtual Rigs
      for (let i = 0; i < 2; i++) {
        let rig1 = await vrig.mint.call(owner,'vRig #'+i,[1000,1,0,4,0,100,1],'https://ipfs.infura.io/ipfs/QmTYHdY87Va7Wkef9EQCHS6d5y7JK8RxeYRgcZXj9niYBQ')
                 await vrig.mint(owner,'vRig #'+i,[1000,1,0,4,0,100,1],'https://ipfs.infura.io/ipfs/QmTYHdY87Va7Wkef9EQCHS6d5y7JK8RxeYRgcZXj9niYBQ')
        console.log('vrig: ' + rig1.toNumber())
        await vrig.approve(vrigMarket.address, rig1.toNumber())
        await vrigMarket.offer(rig1.toNumber(), '10000000000000000000')
      }

    }
    var output = {
        VGPU: vgpu.address,
        VRIG: vrig.address,
        MITHRIL: mithril.address,
        QUARRY: quarry.address,
        FACTORY: factory.address,
        VGPU_MARKET: vgpuMarket.address,
        VRIG_MARKET: vrigMarket.address,
    }

    console.log('completed deployment')
    console.log(JSON.stringify(output, null, 2))

  })

};
