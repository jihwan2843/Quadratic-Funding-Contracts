// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0 <0.9.0;

import "./Grant.sol";
import "./interfaces/IGrantManager.sol";
import "./interfaces/IGrant.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract Factory {
    using Clones for address;

    IGrantManager grantmanager;

    // grant 컨트랙트 배포후 입력
    address immutable masterGrant;

    // 그랜트 제안자가 생성한 그랜트 주소를 저장
    mapping(address => address) private proposerToGrant;

    mapping(uint256 => address) private grantidToGrant;

    address[] grants;

    constructor(address _addr) {
        grantmanager = IGrantManager(_addr);
    }

    function createGrant(
        address _addr,
        string memory _title,
        string memory _description
    ) public returns (address) {
        require(_addr != address(0), "Your Address is 0x");

        address proposer = _addr;

        address cloneAddr = Clones.clone(masterGrant);

        uint256 newGrantId = IGrant(cloneAddr).propose(
            proposer,
            _title,
            _description
        );

        proposerToGrant[proposer] = cloneAddr;

        grantidToGrant[newGrantId] = cloneAddr;

        require(
            proposerToGrant[proposer] != address(0),
            "The Grant Address is 0x"
        );

        grants.push(cloneAddr);

        grantmanager.setGrantInfo(newGrantId);

        return cloneAddr;
    }

    function getGrantbyProsper(address _addr) public view returns (address) {
        return proposerToGrant[_addr];
    }

    function getGrantbyGrantId(uint256 _grantId) public view returns (address) {
        return grantidToGrant[_grantId];
    }
}
