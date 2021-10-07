import { expect } from 'chai';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { ethers, artifacts } from 'hardhat';
import { Contract, ContractFactory } from 'ethers';

const { getSigners } = ethers;

import { newDrawSettings } from './helpers/drawSettings';

const now = () => (new Date().getTime() / 1000) | 0;

describe('L1TimelockTrigger', () => {
    let wallet1: any;
    let wallet2: any;

    let l1TimelockTrigger: Contract;

    let prizeDistributionHistory: MockContract;
    let drawCalculatorTimelock: MockContract;

    let l1TimelockTriggerFactory: ContractFactory;

    beforeEach(async () => {
        [wallet1, wallet2] = await getSigners();

        const PrizeDistributionBuffer = await artifacts.readArtifact('IPrizeDistributionBuffer');
        prizeDistributionHistory = await deployMockContract(wallet1, PrizeDistributionBuffer.abi);

        const DrawCalculatorTimelock = await artifacts.readArtifact('DrawCalculatorTimelock');
        drawCalculatorTimelock = await deployMockContract(wallet1, DrawCalculatorTimelock.abi);

        l1TimelockTriggerFactory = await ethers.getContractFactory('L1TimelockTrigger');

        l1TimelockTrigger = await l1TimelockTriggerFactory.deploy(
            wallet1.address,
            prizeDistributionHistory.address,
            drawCalculatorTimelock.address,
        );
    });

    describe('constructor()', () => {
        it('should emit Deployed event and set variables', async () => {
            await expect(l1TimelockTrigger.deployTransaction)
                .to.emit(l1TimelockTrigger, 'Deployed')
                .withArgs(prizeDistributionHistory.address, drawCalculatorTimelock.address);

            expect(await l1TimelockTrigger.prizeDistributionHistory()).to.equal(
                prizeDistributionHistory.address,
            );

            expect(await l1TimelockTrigger.timelock()).to.equal(drawCalculatorTimelock.address);
        });
    });

    describe('push()', () => {
        it('should allow a push when no push has happened', async () => {
            await prizeDistributionHistory.mock.pushPrizeDistribution.returns(0);
            await drawCalculatorTimelock.mock.lock.withArgs(0).returns(true);
            expect(l1TimelockTrigger.push(0, newDrawSettings()))
                .to.emit(l1TimelockTrigger, 'PrizeDistributionPushed');
        });

        it('should not allow a push from a non-owner', async () => {
            await expect(
                l1TimelockTrigger.connect(wallet2).push(0, newDrawSettings()),
            ).to.be.revertedWith('Manageable/caller-not-manager-or-owner');
        });

        it('should not allow a push if a draw is still timelocked', async () => {
            await drawCalculatorTimelock.mock.lock
                .withArgs(0)
                .revertsWithReason('OM/timelock-not-expired');

            await prizeDistributionHistory.mock.pushPrizeDistribution.returns(0);

            await expect(l1TimelockTrigger.push(0, newDrawSettings())).to.be.revertedWith(
                'OM/timelock-not-expired',
            );
        });
    });
});
