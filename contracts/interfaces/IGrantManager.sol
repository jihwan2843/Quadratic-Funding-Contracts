// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IGrantManager {
    function setGrantInfo(uint256 _grantId) external;
    function setmatchingDistribute() external;
    function setMatchingPool(uint256 _amount) external;
    
}