import { expect } from 'chai';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { ethers, artifacts } from 'hardhat';
import { BigNumber, Contract, ContractFactory } from 'ethers';

const { getSigners } = ethers;
const newDebug = require('debug')

describe('L1TimelockTrigger', () => {
  let wallet1: any;
  let wallet2: any;

  let drawSettingsTimelockTrigger: Contract

  let tsunamiDrawSettingsHistory: MockContract
  let drawCalculatorTimelock: MockContract

  let drawSettingsTimelockTriggerFactory: ContractFactory

  beforeEach(async () => {
    [wallet1, wallet2] = await getSigners();

    const TsunamiDrawSettingsHistory = await artifacts.readArtifact('ITsunamiDrawSettingsHistory');
    tsunamiDrawSettingsHistory = await deployMockContract(wallet1, TsunamiDrawSettingsHistory.abi)

    const DrawCalculatorTimelock = await artifacts.readArtifact('DrawCalculatorTimelock');
    drawCalculatorTimelock = await deployMockContract(wallet1, DrawCalculatorTimelock.abi)

    drawSettingsTimelockTriggerFactory = await ethers.getContractFactory('L1TimelockTrigger');

    drawSettingsTimelockTrigger = await drawSettingsTimelockTriggerFactory.deploy(
      wallet1.address,
      tsunamiDrawSettingsHistory.address,
      drawCalculatorTimelock.address
    )
  });

  describe('pushDrawSettings()', () => {
    const debug = newDebug('pt:L1TimelockTrigger.test.ts:push()')

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
      await drawSettingsTimelockTrigger.pushDrawSettings(0, drawSettings)
      // no problemo
    })

    it('should not allow a push from a non-owner', async () => {
      await expect(drawSettingsTimelockTrigger.connect(wallet2).pushDrawSettings(0, drawSettings)).to.be.revertedWith('Manageable/caller-not-manager-or-owner')
    })

    it('should not allow a push if a draw is still timelocked', async () => {
      await drawCalculatorTimelock.mock.lock.withArgs(0).revertsWithReason('OM/timelock-not-expired')
      await tsunamiDrawSettingsHistory.mock.pushDrawSettings.returns(true)
      await expect(drawSettingsTimelockTrigger.pushDrawSettings(0, drawSettings)).to.be.revertedWith('OM/timelock-not-expired')
    })
  })
})
