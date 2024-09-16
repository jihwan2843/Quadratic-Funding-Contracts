// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IGrantManager.sol";
import "./interfaces/IGrant.sol";
import "./interfaces/IFactory.sol";

contract EntryPoint {
    IGrantManager grantmanager;
    IGrant grant;
    IFactory factory;

    uint256 private totalMatchingPool;

    constructor(address _grantManagerAddr, address _factoryAddr) {
        grantmanager = IGrantManager(_grantManagerAddr);
        factory = IFactory(_factoryAddr);
    }

    // 특정 그랜트에 후원하기. Grant.sol 함수를 호출하여 후원하기
    function funding(
        address _addr,
        uint256 _amount
    ) public payable returns (uint256) {
        require(_addr != address(0), "Invalid Address");
        //       후원할 그랜트의 주소
        grant = IGrant(_addr);
        uint256 fundingAmount = grant.funding{value: msg.value}(
            msg.sender,
            _amount
        );

        return fundingAmount;
    }

    // Factory 함수를 호출하여 그랜트를 생성하기
    function createGrant(
        string memory _title,
        string memory _description
    ) public returns (address) {
        address grantAddr = factory.createGrant(
            msg.sender,
            _title,
            _description
        );

        return grantAddr;
    }

    // Grant가 끝나면 관리자가 각 그랜트에 매칭풀을 비율만큼 분배
    function matchingDistribute() public {
        grantmanager.setmatchingDistribute(msg.sender);
    }

    // 관리자가 총 매칭 풀 금액을 설정
    function setMatchingPool(uint256 _amount) public {
        grantmanager.setMatchingPool(msg.sender, _amount);
    }
}
