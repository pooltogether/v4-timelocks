import { expect } from 'chai';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { ethers, artifacts } from 'hardhat';
import { Contract, ContractFactory } from 'ethers';

import { newDrawSettings } from './helpers/drawSettings';

const { getSigners } = ethers;

describe('L2TimelockTrigger', () => {
  let wallet1: any;
  let wallet2: any;

  let l2TimelockTrigger: Contract

  let prizeDistributionHistory: MockContract
  let drawCalculatorTimelock: MockContract
  let drawHistory: MockContract

  let l2TimelockTriggerFactory: ContractFactory

  beforeEach(async () => {
    [wallet1, wallet2] = await getSigners();

    const PrizeDistributionHistory = await artifacts.readArtifact('IPrizeDistributionHistory');
    prizeDistributionHistory = await deployMockContract(wallet1, PrizeDistributionHistory.abi)

    const DrawHistory = await artifacts.readArtifact('IDrawHistory');
    drawHistory = await deployMockContract(wallet1, DrawHistory.abi)

    const DrawCalculatorTimelock = await artifacts.readArtifact('DrawCalculatorTimelock');
    drawCalculatorTimelock = await deployMockContract(wallet1, DrawCalculatorTimelock.abi)

    l2TimelockTriggerFactory = await ethers.getContractFactory('L2TimelockTrigger');

    l2TimelockTrigger = await l2TimelockTriggerFactory.deploy(
      wallet1.address,
      drawHistory.address,
      prizeDistributionHistory.address,
      drawCalculatorTimelock.address
    )
  });

  describe('constructor()', () => {
    it('should emit Deployed event', async () => {
      await expect(l2TimelockTrigger.deployTransaction)
      .to.emit(l2TimelockTrigger, 'Deployed')
      .withArgs(drawHistory.address, prizeDistributionHistory.address, drawCalculatorTimelock.address);

      expect(await l2TimelockTrigger.drawHistory()).to.equal(drawHistory.address);
      expect(await l2TimelockTrigger.prizeDistributionHistory()).to.equal(prizeDistributionHistory.address);
      expect(await l2TimelockTrigger.timelock()).to.equal(drawCalculatorTimelock.address);
    })
  })

  describe('push()', () => {
    const draw: any = {
      drawId: ethers.BigNumber.from(0),
      winningRandomNumber: ethers.BigNumber.from(1),
      timestamp: ethers.BigNumber.from(10),
      beaconPeriodStartedAt: Math.floor(new Date().getTime() / 1000),
      beaconPeriodSeconds: 1000
    }

    it('should allow a push when no push has happened', async () => {
      await drawHistory.mock.pushDraw.returns(draw.drawId)
      await prizeDistributionHistory.mock.pushPrizeDistribution.returns(true)
      await drawCalculatorTimelock.mock.lock.withArgs(0).returns(true)
      await l2TimelockTrigger.push(draw, newDrawSettings())
    })

    it('should not allow a push from a non-owner', async () => {
      await expect(l2TimelockTrigger.connect(wallet2).push(draw, newDrawSettings())).to.be.revertedWith('Manageable/caller-not-manager-or-owner')
    })

    it('should not allow a push if a draw is still timelocked', async () => {
      await drawCalculatorTimelock.mock.lock.withArgs(0).revertsWithReason('OM/timelock-not-expired')
      await drawHistory.mock.pushDraw.returns(draw.drawId)
      await prizeDistributionHistory.mock.pushPrizeDistribution.returns(true)
      await expect(l2TimelockTrigger.push(draw, newDrawSettings())).to.be.revertedWith('OM/timelock-not-expired')
    })
  })

})
