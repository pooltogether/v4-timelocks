import { expect } from 'chai';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { ethers, artifacts } from 'hardhat';
import { BigNumber, Contract, ContractFactory } from 'ethers';

const { getSigners } = ethers;

describe('L2TimelockTrigger', () => {
  let wallet1: any;
  let wallet2: any;

  let l2TimelockTrigger: Contract

  let tsunamiDrawSettingsHistory: MockContract
  let drawCalculatorTimelock: MockContract

  let l2TimelockTriggerFactory: ContractFactory

  beforeEach(async () => {
    [wallet1, wallet2] = await getSigners();

    const TsunamiDrawSettingsHistory = await artifacts.readArtifact('ITsunamiDrawSettingsHistory');
    tsunamiDrawSettingsHistory = await deployMockContract(wallet1, TsunamiDrawSettingsHistory.abi)

    const DrawCalculatorTimelock = await artifacts.readArtifact('DrawCalculatorTimelock');
    drawCalculatorTimelock = await deployMockContract(wallet1, DrawCalculatorTimelock.abi)

    l2TimelockTriggerFactory = await ethers.getContractFactory('L2TimelockTrigger');

    l2TimelockTrigger = await l2TimelockTriggerFactory.deploy(
      wallet1.address,
      tsunamiDrawSettingsHistory.address,
      drawCalculatorTimelock.address
    )
  });

  describe('pushDrawSettings()', () => {
    const drawSettings: any = {
      matchCardinality: BigNumber.from(5),
      numberOfPicks: ethers.utils.parseEther('1'),
      distributions: [ethers.utils.parseUnits('0.5', 9)],
      bitRangeSize: BigNumber.from(3),
      prize: ethers.utils.parseEther('100'),
      drawStartTimestampOffset: BigNumber.from(0),
      drawEndTimestampOffset: BigNumber.from(3600),
      maxPicksPerUser: BigNumber.from(10)
    }

    it('should allow a push when no push has happened', async () => {
      await tsunamiDrawSettingsHistory.mock.pushDrawSettings.returns(true)
      await drawCalculatorTimelock.mock.lock.withArgs(0).returns(true)
      await l2TimelockTrigger.pushDrawSettings(0, drawSettings)
    })

    it('should not allow a push from a non-owner', async () => {
      await expect(l2TimelockTrigger.connect(wallet2).pushDrawSettings(0, drawSettings)).to.be.revertedWith('Manageable/caller-not-manager-or-owner')
    })

    it('should not allow a push if a draw is still timelocked', async () => {
      await drawCalculatorTimelock.mock.lock.withArgs(0).revertsWithReason('OM/timelock-not-expired')
      await tsunamiDrawSettingsHistory.mock.pushDrawSettings.returns(true)
      await expect(l2TimelockTrigger.pushDrawSettings(0, drawSettings)).to.be.revertedWith('OM/timelock-not-expired')
    })
  })
})
