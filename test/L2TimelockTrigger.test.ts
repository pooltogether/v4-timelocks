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

  let l2TimelockTriggerFactory: ContractFactory

  beforeEach(async () => {
    [wallet1, wallet2] = await getSigners();

    const TsunamiDrawSettingsHistory = await artifacts.readArtifact('IPrizeDistributionHistory');
    prizeDistributionHistory = await deployMockContract(wallet1, TsunamiDrawSettingsHistory.abi)

    const DrawCalculatorTimelock = await artifacts.readArtifact('DrawCalculatorTimelock');
    drawCalculatorTimelock = await deployMockContract(wallet1, DrawCalculatorTimelock.abi)

    l2TimelockTriggerFactory = await ethers.getContractFactory('L2TimelockTrigger');

    l2TimelockTrigger = await l2TimelockTriggerFactory.deploy(
      wallet1.address,
      prizeDistributionHistory.address,
      drawCalculatorTimelock.address
    )
  });

    describe('constructor()', () => {
    it('should emit Deployed event', async () => {
      await expect(l2TimelockTrigger.deployTransaction)
      .to.emit(l2TimelockTrigger, 'Deployed')
      .withArgs(tsunamiDrawSettingsHistory.address, drawCalculatorTimelock.address);

      expect(await l2TimelockTrigger.tsunamiDrawSettingsHistory()).to.equal(tsunamiDrawSettingsHistory.address);
      expect(await l2TimelockTrigger.timelock()).to.equal(drawCalculatorTimelock.address);
    })
  })

  describe('pushDrawSettings()', () => {
    it('should allow a push when no push has happened', async () => {
      await prizeDistributionHistory.mock.pushDrawSettings.returns(true)
      await drawCalculatorTimelock.mock.lock.withArgs(0).returns(true)
      await l2TimelockTrigger.pushDrawSettings(0, newDrawSettings())
    })

    it('should not allow a push from a non-owner', async () => {
      await expect(l2TimelockTrigger.connect(wallet2).pushDrawSettings(0, newDrawSettings())).to.be.revertedWith('Manageable/caller-not-manager-or-owner')
    })

    it('should not allow a push if a draw is still timelocked', async () => {
      await drawCalculatorTimelock.mock.lock.withArgs(0).revertsWithReason('OM/timelock-not-expired')
      await prizeDistributionHistory.mock.pushDrawSettings.returns(true)
      await expect(l2TimelockTrigger.pushDrawSettings(0, newDrawSettings())).to.be.revertedWith('OM/timelock-not-expired')
    })
  })
})
