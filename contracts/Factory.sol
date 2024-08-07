// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0 <0.9.0;

import "./Grant.sol";
import "./interfaces/IGrantManager.sol";

contract Factory{
    IGrantManager grantmanager; 

    // 그랜트 제안자가 생성한 그랜트 주소를 저장
    mapping (address => address) private proposerToGrant;
    
    mapping (uint256 => address) private grantidToGrant;

    address[] grants;

    constructor(address _addr){
        grantmanager = IGrantManager(_addr);
    }
    
    function createGrant(address _addr, string memory _title, string memory _description) public returns(address){
        require(_addr != address(0),"go back");

        address proposer = _addr;

        Grant grant = new Grant();

        uint256 newGrantId = grant.propose(proposer, _title, _description);

        proposerToGrant[proposer] = address(grant);

        grantidToGrant[newGrantId] = address(grant);
        
        require(proposerToGrant[proposer] != address(0), "go back");

        grants.push(address(grant));

        grantmanager.setGrantInfo(newGrantId);

        return proposerToGrant[proposer];        
    }

    function getGrantbyProsper(address _addr) public view returns(address){
        return proposerToGrant[_addr];
    }

    function getGrantbyGrantId(uint256 _grantId) public view returns(address){
        return grantidToGrant[_grantId];
    }
    

}