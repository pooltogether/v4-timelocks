interface IPrizeDistributionFactory {
  function pushPrizeDistribution(uint32 _drawId, uint256 _totalNetworkTicketSupply) external;
}