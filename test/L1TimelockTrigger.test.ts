import { expect } from 'chai';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { ethers, artifacts } from 'hardhat';
import { BigNumber, Contract, ContractFactory } from 'ethers';

const { getSigners } = ethers;

import { newDrawSettings } from './helpers/drawSettings';

const now = () => (new Date().getTime() / 1000) | 0;

describe('L1TimelockTrigger', () => {
  let wallet1: any;
  let wallet2: any;

  let l1TimelockTrigger: Contract

  let prizeDistributionHistory: MockContract
  let drawHistory: MockContract
  let drawCalculatorTimelock: MockContract

  let l1TimelockTriggerFactory: ContractFactory

  beforeEach(async () => {
    [wallet1, wallet2] = await getSigners();

    const PrizeDistributionHistory = await artifacts.readArtifact('IPrizeDistributionHistory');
    prizeDistributionHistory = await deployMockContract(wallet1, PrizeDistributionHistory.abi)

    const DrawHistory = await artifacts.readArtifact('IDrawHistory');
    drawHistory = await deployMockContract(wallet1, DrawHistory.abi)

    const DrawCalculatorTimelock = await artifacts.readArtifact('DrawCalculatorTimelock');
    drawCalculatorTimelock = await deployMockContract(wallet1, DrawCalculatorTimelock.abi)

    l1TimelockTriggerFactory = await ethers.getContractFactory('L1TimelockTrigger');

    l1TimelockTrigger = await l1TimelockTriggerFactory.deploy(
      wallet1.address,
      drawHistory.address,
      prizeDistributionHistory.address,
      drawCalculatorTimelock.address
    )
  });

  describe('constructor()', () => {
    it('should emit Deployed event and set variables', async () => {
      await expect(l1TimelockTrigger.deployTransaction)
      .to.emit(l1TimelockTrigger, 'Deployed')
      .withArgs(drawHistory.address, prizeDistributionHistory.address, drawCalculatorTimelock.address);

      expect(await l1TimelockTrigger.drawHistory()).to.equal(drawHistory.address);
      expect(await l1TimelockTrigger.prizeDistributionHistory()).to.equal(prizeDistributionHistory.address);
      expect(await l1TimelockTrigger.timelock()).to.equal(drawCalculatorTimelock.address);
    });
  });

  describe('push()', () => {
    const draw: any = {
      drawId: BigNumber.from(0),
      winningRandomNumber: BigNumber.from(1),
      timestamp: BigNumber.from(10),
      beaconPeriodStartedAt: now(),
      beaconPeriodSeconds: 1000
    }

    it('should allow a push when no push has happened', async () => {
      await drawHistory.mock.pushDraw.returns(draw.drawId)
      await prizeDistributionHistory.mock.pushDrawSettings.returns(true)
      await drawCalculatorTimelock.mock.lock.withArgs(0).returns(true)
      await l1TimelockTrigger.push(draw, newDrawSettings())
    })

    it('should not allow a push from a non-owner', async () => {
      await expect(l1TimelockTrigger.connect(wallet2).push(draw, newDrawSettings())).to.be.revertedWith('Manageable/caller-not-manager-or-owner')
    })

    it('should not allow a push if a draw is still timelocked', async () => {
      await drawCalculatorTimelock.mock.lock.withArgs(0).revertsWithReason('OM/timelock-not-expired')
      await drawHistory.mock.pushDraw.returns(draw.drawId)
      await prizeDistributionHistory.mock.pushDrawSettings.returns(true)
      await expect(l1TimelockTrigger.push(draw, newDrawSettings())).to.be.revertedWith('OM/timelock-not-expired')
    })
  })
})
