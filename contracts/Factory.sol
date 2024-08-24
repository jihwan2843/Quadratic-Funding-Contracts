// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0 <0.9.0;

import "./Grant.sol";
import "./interfaces/IGrantManager.sol";
import "./interfaces/IGrant.sol";
import {Clones} from "./dependencies/openzeppelin/contracts/Clones.sol";

contract Factory {
    using Clones for address;

    event CreateGrant(
        uint32 indexed _grantId,
        address indexed cloneGrantAddr,
        address indexed proposer
    );

    //IGrantManager grantmanager;

    // grant 컨트랙트 배포후 입력
    address immutable masterGrant;

    // 그랜트 제안자가 생성한 그랜트 주소를 저장
    mapping(address => address) private proposerToGrant;

    // 그랜트 제안자가 생성한 그랜트를 grantId => grant 맵핑으로 저장
    mapping(uint256 => address) private grantidToGrant;

    // GrantId들을 배열로 저장
    uint32[] private grantIds;

    constructor(address _addr) {
        //grantmanager = IGrantManager(_addr);
        masterGrant = address(_addr);
    }

    function createGrant(
        address _addr,
        string memory _title,
        string memory _description
    ) public returns (address) {
        // EOA가 Grant컨트랙트에 직접 접근하여 이 함수를 실행하지 못하도록 함
        // EntryPoint를 통해 propose를 할 수 있음
        require(
            msg.sender.code.length != 0,
            "Direct access by EOA is not allowed"
        );
        require(_addr != address(0), "Your Address is 0x");

        address proposer = _addr;

        require(
            proposerToGrant[proposer] == address(0),
            "You have already created the grant"
        );

        // 프록시 패턴을 활용하여 Grant를 생성
        address cloneAddr = Clones.clone(masterGrant);

        uint32 newGrantId = IGrant(cloneAddr).propose(
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

        grantIds.push(newGrantId);

        emit CreateGrant(newGrantId, cloneAddr, proposer);

        //grantmanager.setGrantInfo(newGrantId);

        return cloneAddr;
    }

    function getGrantbyProsper(address _addr) public view returns (address) {
        return proposerToGrant[_addr];
    }

    function getGrantbyGrantId(uint256 _grantId) public view returns (address) {
        return grantidToGrant[_grantId];
    }

    function getListOfGrantId() public view returns (uint32[] memory) {
        return grantIds;
    }
}
