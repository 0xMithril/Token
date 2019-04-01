#!/usr/bin/env bash

rm -rf flats/*

truffle-flattener contracts/ChildArtifact.sol > flats/ChildArtifact.sol
truffle-flattener contracts/VirtualMiningBoard.sol > flats/VirtualMiningBoard.sol
truffle-flattener contracts/MithrilToken.sol > flats/MithrilToken.sol
truffle-flattener contracts/MithrilTokenQuarry.sol > flats/MithrilTokenQuarry.sol
truffle-flattener contracts/MineableTokenFactory.sol > flats/MineableTokenFactory.sol
truffle-flattener contracts/VGPUMarket.sol > flats/VGPUMarket.sol
truffle-flattener contracts/VRIGMarket.sol > flats/VRIGMarket.sol

truffle-flattener contracts/SimpleERC918.sol > flats/SimpleERC918.sol