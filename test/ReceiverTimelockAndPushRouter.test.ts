import { expect } from 'chai';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { ethers, artifacts } from 'hardhat';
import { BigNumber, Contract, ContractFactory } from 'ethers';
const { getSigners } = ethers;

describe('ReceiverTimelockTrigger', () => {
    let wallet1: any;
    let wallet2: any;

    let drawAndPrizeDistributionTimelock: Contract;

    let prizeDistributionFactory: MockContract;
    let drawCalculatorTimelock: MockContract;
    let drawBuffer: MockContract;

    let ReceiverTimelockTriggerFactory: ContractFactory;

    beforeEach(async () => {
        [wallet1, wallet2] = await getSigners();

        const PrizeDistributionFactory = await artifacts.readArtifact('IPrizeDistributionFactory');
        prizeDistributionFactory = await deployMockContract(wallet1, PrizeDistributionFactory.abi);

        const DrawBufferArtifact = await artifacts.readArtifact('IDrawBuffer');
        drawBuffer = await deployMockContract(wallet1, DrawBufferArtifact.abi);

        const DrawCalculatorTimelock = await artifacts.readArtifact('DrawCalculatorTimelock');
        drawCalculatorTimelock = await deployMockContract(wallet1, DrawCalculatorTimelock.abi);

        ReceiverTimelockTriggerFactory = await ethers.getContractFactory(
            'ReceiverTimelockTrigger',
        );

        drawAndPrizeDistributionTimelock = await ReceiverTimelockTriggerFactory.deploy(
            wallet1.address,
            drawBuffer.address,
            prizeDistributionFactory.address,
            drawCalculatorTimelock.address,
        );
    });

    describe('constructor()', () => {
        it('should emit Deployed event', async () => {
            await expect(drawAndPrizeDistributionTimelock.deployTransaction)
                .to.emit(drawAndPrizeDistributionTimelock, 'Deployed')
                .withArgs(
                    drawBuffer.address,
                    prizeDistributionFactory.address,
                    drawCalculatorTimelock.address,
                );

            expect(await drawAndPrizeDistributionTimelock.drawBuffer()).to.equal(
                drawBuffer.address,
            );

            expect(await drawAndPrizeDistributionTimelock.prizeDistributionFactory()).to.equal(
                prizeDistributionFactory.address,
            );
            expect(await drawAndPrizeDistributionTimelock.timelock()).to.equal(
                drawCalculatorTimelock.address,
            );
        });
    });

    describe('push()', () => {
        const draw: any = {
            drawId: ethers.BigNumber.from(0),
            winningRandomNumber: ethers.BigNumber.from(1),
            timestamp: ethers.BigNumber.from(10),
            beaconPeriodStartedAt: Math.floor(new Date().getTime() / 1000),
            beaconPeriodSeconds: 1000,
        };

        it('should allow a push when no push has happened', async () => {
            await drawBuffer.mock.pushDraw.returns(draw.drawId);
            await prizeDistributionFactory.mock.pushPrizeDistribution.returns();
            await drawCalculatorTimelock.mock.lock.returns(true);
            await expect(
                drawAndPrizeDistributionTimelock.push(draw, BigNumber.from(1000000)),
            ).to.emit(
                drawAndPrizeDistributionTimelock,
                'DrawLockedPushedAndTotalNetworkTicketSupplyPushed',
            );
        });

        it('should not allow a push from a non-owner', async () => {
            await expect(
                drawAndPrizeDistributionTimelock
                    .connect(wallet2)
                    .push(draw, BigNumber.from(1000000)),
            ).to.be.revertedWith('Manageable/caller-not-manager-or-owner');
        });

        it('should not allow a push if a draw is still timelocked', async () => {
            await drawCalculatorTimelock.mock.lock.revertsWithReason('OM/timelock-not-expired');

            await drawBuffer.mock.pushDraw.returns(draw.drawId);
            await prizeDistributionFactory.mock.pushPrizeDistribution.returns();

            await expect(
                drawAndPrizeDistributionTimelock.push(draw, BigNumber.from(1000000)),
            ).to.be.revertedWith('OM/timelock-not-expired');
        });
    });
});
