// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IFactory {
    function getGrantbyGrantId(
        uint256 _grantId
    ) external view returns (address);

    function createGrant(
        address _addr,
        string memory _title,
        string memory _description
    ) external returns (address);

    function getListOfGrantId() external view returns (uint32[] memory);
}
