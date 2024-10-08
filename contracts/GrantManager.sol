// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IFactory.sol";
import "./interfaces/IGrant.sol";
import {Ownable} from "./dependencies/openzeppelin/contracts/Ownable.sol";

contract GrantManager is Ownable {
    IFactory factory;
    IGrant grant;

    // 펀딩된 총 매칭 풀 금액
    uint256 private totalMatchingPool;
    // grantId별 제곱근들의 합
    mapping(uint32 => uint256) private sumOfSqrtValue;
    // grantId별 분배 비율
    mapping(uint32 => uint256) private distributionRate;
    // grantId별 총 매칭 풀에서 그랜트에게 분배된 금액
    mapping(uint32 => uint256) private donationAmount;

    // 모든 그랜트들의 제곱근의 합들을 모두 더한 값
    uint256 sumOfAllSumOfSqrtValue;

    constructor(address _factoryAddr) Ownable(msg.sender) {
        factory = IFactory(_factoryAddr);
        //grant = IGrant(_grantAddr);
    }

    // grantId별 총 매칭 풀에서 그랜트에게 분배된 금액을 반환
    function getDonationAmount(uint32 _grantId) public view returns(uint256){
        return donationAmount[_grantId];
    }

    // Grant배열들을 반환
    function getGrants() public view returns (uint32[] memory) {
        return factory.getListOfGrantId();
    }

    function setmatchingDistribute(address _addr) public returns (bool) {
        require(_addr == owner(), "You are not admin");
        require(totalMatchingPool > 0, "Not Set MtchingPool");
        setdistributionRate();
        uint length = getGrants().length;
        for (uint i = 0; i < length; i++) {
            donationAmount[getGrants()[i]] =
                (totalMatchingPool * distributionRate[getGrants()[i]]) /
                10000;
        }
        // 정상적으로 배분이 됬는지 어떻게 확인하지?
        return true;
    }

    function setdistributionRate() private {
        setSumOfSqrtValue();
        uint length = getGrants().length;
        for (uint i = 0; i < length; i++) {
            uint rate = (sumOfSqrtValue[getGrants()[i]] * 100 * 100) /
                sumOfAllSumOfSqrtValue;
            distributionRate[getGrants()[i]] = rate;
        }
    }

    // 각 그랜트별 사용자가 후원한 후원금액의 루트들 값들의 합을 제곱한 값 구해서 GrantId별로 저장하기
    function setSumOfSqrtValue() private {
        uint length = getGrants().length;
        for (uint i = 0; i < length; i++) {
            address grantAddr = factory.getGrantbyGrantId(getGrants()[i]);
            grant = IGrant(grantAddr);
            uint256 sqrtAmount = grant.calculateQuadraticFuding();
            sumOfSqrtValue[getGrants()[i]] = sqrtAmount;
            sumOfAllSumOfSqrtValue += sqrtAmount;
        }
    }

    function setMatchingPool(address _address, uint256 _amount) public {
        require(_address == owner(), "You are not admin");
        totalMatchingPool = _amount;
    }

    function getMatchingPool() public view returns (uint256) {
        return totalMatchingPool;
    }
}
