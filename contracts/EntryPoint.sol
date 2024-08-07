// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IGrantManager.sol";
import "./interfaces/IGrant.sol";
import "./interfaces/IFactory.sol";

contract EntryPoint{

    IGrantManager grantmanager;
    IGrant grant;
    IFactory factory;


    uint256 private totalMatchingPool;

    constructor(address _grantManagerAddr, address _factoryAddr){
        grantmanager = IGrantManager(_grantManagerAddr);
        factory = IFactory(_factoryAddr);
    }


    // 특정 그랜트에 후원하기. Grant.sol 함수를 호출하여 후원하기
    function funding(address _addr, uint256 _amount) public returns(uint256){
        require(_addr != address(0), "Invalid Address");
        //       후원할 그랜트의 주소
        grant = IGrant(_addr);
        uint256 fundingAmount = grant.funding(msg.sender, _amount);

        return fundingAmount;
    }
    // function funding(address _addr, uint256 _amount) public {
    //     require(_addr != address(0), "Invalid Address");
    //     //              후원할 그랜트의 주소
    //     (bool success, ) = _addr.call(abi.encodeWithSignature("funding(address,uint256)", msg.sender,_amount));

    //     require(success, "Funding Failed");
    // }

    // Factory 함수를 호출하여 그랜트를 생성하기
    function createGrant(string memory _title, string memory _description) public returns(address){
        
        address grantAddr = factory.createGrant(msg.sender, _title, _description);

        return grantAddr;
    }
    // function createGrant(address _addr, string memory _title, string memory _description) public{
    //     require(_addr != address(0), "Invalid Address");
    //     address factoryAddress = _addr;

    //     (bool success,) = factoryAddress.call(abi.encodeWithSignature("createGrant(address,string,string)",msg.sender,_title,_description));

    //     require(success,"CreateGrant Failed");
    // }

    // Grant가 끝나면 관리자가 각 그랜트에 매칭풀을 비율만큼 분배 
    function matchingDistribute() public{
        // only administrator
        grantmanager.setmatchingDistribute();

    }

    // 관리자가 총 매칭 풀 금액을 설정
    function setMatchingPool(uint256 _amount) public {
        // require 설정하기
        grantmanager.setMatchingPool(_amount);
    }


}