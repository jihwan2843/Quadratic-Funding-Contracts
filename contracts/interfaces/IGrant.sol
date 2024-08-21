// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IGrant {
    function calculateQuadraticFuding() external returns (uint256);

    function funding(address _addr, uint256 _amount) external returns (uint256);

    function propose(
        address _addr,
        string memory _title,
        string memory _description
    ) external returns (uint32);
}
