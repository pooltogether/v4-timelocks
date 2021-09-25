import { expect } from 'chai';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { ethers, artifacts } from 'hardhat';
import { BigNumber, Contract, ContractFactory } from 'ethers';

const { getSigners } = ethers;
const newDebug = require('debug')

describe('L2TimelockTrigger', () => {
  let wallet1: any;
  let wallet2: any;

  let fullTimelockTrigger: Contract

  let tsunamiDrawSettingsHistory: MockContract
  let drawHistory: MockContract
  let drawCalculatorTimelock: MockContract

  let fullTimelockTriggerFactory: ContractFactory

  beforeEach(async () => {
    [wallet1, wallet2] = await getSigners();

    const TsunamiDrawSettingsHistory = await artifacts.readArtifact('ITsunamiDrawSettingsHistory');
    tsunamiDrawSettingsHistory = await deployMockContract(wallet1, TsunamiDrawSettingsHistory.abi)

    const DrawHistory = await artifacts.readArtifact('IDrawHistory');
    drawHistory = await deployMockContract(wallet1, DrawHistory.abi)

    const DrawCalculatorTimelock = await artifacts.readArtifact('DrawCalculatorTimelock');
    drawCalculatorTimelock = await deployMockContract(wallet1, DrawCalculatorTimelock.abi)

    fullTimelockTriggerFactory = await ethers.getContractFactory('L2TimelockTrigger');

    fullTimelockTrigger = await fullTimelockTriggerFactory.deploy(
      wallet1.address,
      drawHistory.address,
      tsunamiDrawSettingsHistory.address,
      drawCalculatorTimelock.address
    )
  });

  describe('push()', () => {
    const debug = newDebug('pt:L2TimelockTrigger.test.ts:push()')

    const draw: any = {
      drawId: BigNumber.from(0),
      winningRandomNumber: BigNumber.from(1),
      timestamp: BigNumber.from(10)
    }

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
      await drawHistory.mock.pushDraw.returns(draw.drawId)
      await tsunamiDrawSettingsHistory.mock.pushDrawSettings.returns(true)
      await drawCalculatorTimelock.mock.lock.withArgs(0).returns(true)
      await fullTimelockTrigger.push(draw, drawSettings)
      // no problemo
    })

    it('should not allow a push from a non-owner', async () => {
      await expect(fullTimelockTrigger.connect(wallet2).push(draw, drawSettings)).to.be.revertedWith('Manageable/caller-not-manager-or-owner')
    })

    it('should not allow a push if a draw is still timelocked', async () => {
      await drawCalculatorTimelock.mock.lock.withArgs(0).revertsWithReason('OM/timelock-not-expired')
      await drawHistory.mock.pushDraw.returns(draw.drawId)
      await tsunamiDrawSettingsHistory.mock.pushDrawSettings.returns(true)
      await expect(fullTimelockTrigger.push(draw, drawSettings)).to.be.revertedWith('OM/timelock-not-expired')
    })
  })
})
