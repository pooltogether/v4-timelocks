// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "./interfaces/IReceiverDrawAndPrizeDistributionTimelock.sol";
import "./interfaces/IPrizeDistributionFactory.sol";
import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 ReceiverDrawAndPrizeDistributionTimelock
  * @author PoolTogether Inc Team
  * @notice The ReceiverDrawAndPrizeDistributionTimelock smart contract is an upgrade of the L2TimelockTimelock smart contract.
            Reducing protocol risk by eliminating off-chain computation of PrizeDistribution parameters. The timelock will
            only pass the total supply of all tickets in a "PrizePool Network" to the prize distribution factory contract.
*/
contract ReceiverDrawAndPrizeDistributionTimelock is
    IReceiverDrawAndPrizeDistributionTimelock,
    Manageable
{
    /* ============ Global Variables ============ */

    /// @notice The DrawBuffer contract address.
    IDrawBuffer public immutable drawBuffer;

    /// @notice Internal PrizeDistributionFactory reference.
    IPrizeDistributionFactory public immutable prizeDistributionFactory;

    /// @notice Timelock struct reference.
    IDrawCalculatorTimelock public immutable timelock;

    /* ============ Constructor ============ */

    /**
     * @notice Initialize ReceiverDrawAndPrizeDistributionTimelock smart contract.
     * @param _owner The smart contract owner
     * @param _drawBuffer DrawBuffer address
     * @param _prizeDistributionFactory PrizeDistributionFactory address
     * @param _timelock DrawCalculatorTimelock address
     */
    constructor(
        address _owner,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionFactory _prizeDistributionFactory,
        IDrawCalculatorTimelock _timelock
    ) Ownable(_owner) {
        drawBuffer = _drawBuffer;
        prizeDistributionFactory = _prizeDistributionFactory;
        timelock = _timelock;
        emit Deployed(_drawBuffer, _prizeDistributionFactory, _timelock);
    }

    /// @inheritdoc IReceiverDrawAndPrizeDistributionTimelock
    function push(IDrawBeacon.Draw memory _draw, uint256 _totalNetworkTicketSupply)
        external
        override
        onlyManagerOrOwner
    {
        timelock.lock(_draw.drawId, _draw.timestamp + _draw.beaconPeriodSeconds);
        drawBuffer.pushDraw(_draw);
        prizeDistributionFactory.pushPrizeDistribution(_draw.drawId, _totalNetworkTicketSupply);
        emit DrawAndPrizeDistributionPushed(_draw.drawId, _draw, _totalNetworkTicketSupply);
    }
}
