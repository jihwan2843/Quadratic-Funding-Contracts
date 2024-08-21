// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IFactory.sol";
import "./interfaces/IGrant.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GrantManager is Ownable {
    IFactory factory;
    IGrant grant;

    //mapping (uint256=>GrantDonation) private grantInfo;

    uint256 private totalMatchingPool;

    mapping(uint256 => uint256) private sumOfSqrtValue;

    mapping(uint256 => uint256) private distributionRate;

    mapping(uint256 => uint256) private donationAmount;

    // struct GrantDonation{
    //     //uint256 grantId;
    //     uint256 distributionRate;
    //     uint256 donationAmount;
    //     uint256 sumOfSqrtValue;
    // }

    uint256[] grants;

    uint256 sumOfAllSumOfSqrtValue;

    constructor(address _addr) Ownable(msg.sender) {
        factory = IFactory(_addr);
    }

    // Grant가 생성될때 그랜트 배열에 그랜트아이디를 저장하기
    function setGrantInfo(uint256 _grantId) public {
        grants.push(_grantId);
    }

    function setmatchingDistribute() public returns (bool) {
        require(totalMatchingPool > 0, "Not Set MtchingPool");
        setdistributionRate();
        uint length = grants.length;
        for (uint i = 0; i < length; i++) {
            donationAmount[grants[i]] =
                (totalMatchingPool * distributionRate[grants[i]]) /
                10000;
        }
        // 정상적으로 배분이 됬는지 어떻게 확인하지?
        return true;
    }

    function setdistributionRate() public {
        setSumOfSqrtValue();
        uint length = grants.length;
        for (uint i = 0; i < length; i++) {
            uint rate = (sumOfSqrtValue[grants[i]] * 100 * 100) /
                sumOfAllSumOfSqrtValue;
            distributionRate[grants[i]] = rate;
        }
    }

    // 각 그랜트별 사용자가 후원한 후원금액의 루트들 값들의 합을 제곱한 값 구해서 GrantId별로 저장하기
    function setSumOfSqrtValue() private {
        uint length = grants.length;
        for (uint i = 0; i < length; i++) {
            address grantAddr = factory.getGrantbyGrantId(grants[i]);
            grant = IGrant(grantAddr);
            uint256 sqrtAmount = grant.calculateQuadraticFuding();
            sumOfSqrtValue[grants[i]] = sqrtAmount;
            // grantInfo[grants[i]] = GrantDonation(0,0,sqrtAmount);

            sumOfAllSumOfSqrtValue += sqrtAmount;
        }
    }

    function setMatchingPool(uint256 _amount) public {
        // require 설정하기
        totalMatchingPool = _amount;
    }
}
