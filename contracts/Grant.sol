// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

contract Grant {
    using Math for uint256;

    // 각 후원자 주소별로 후원금액을 나타냄
    mapping (address => uint256) private amountPerSponsor;

    // 후원자 목록
    address[] private sponsors;
    
    // 이 그랜트에 후원된 총 후원 금액
    uint256 private totalAmount;
    
    // 이 그랜트에 후원한 총 후원자 수
    //uint256 private totalSponsors;

    event GrantFunding(address indexed sponsor, uint256 indexed amount, uint256 indexed grantTime);
    event GrantPropose(address indexed proposer, uint256 indexed grantId, uint256 indexed grantStart);
    
    modifier StatusChange{
        if(block.timestamp>grantDeadline()){
            proposalstatus = ProposalStatus.Distributed;
        }else if(block.timestamp >= grantStart()){
            proposalstatus = ProposalStatus.Active;
        }else{
            proposalstatus = ProposalStatus.Pending;
        }
        _;
    }
    
    constructor() {}

    struct Proposal {
        address owner;
        uint256 grantId;
        uint256 grantStart;
        uint grantDeadline;
    }

    Proposal proposal;

    enum ProposalStatus{
        Pending,
        Active,
        Distributed,
        Canceld
    }
    ProposalStatus proposalstatus;


    // Hash를 이용하여 각 Grant를 구별할 수 있는 고유한 Id를 만듦
    function hashGrant(address _addr, string memory _title, string memory _description) private pure returns(uint256){
        return uint256(keccak256(abi.encodePacked(_addr,_title,_description)));
    } 

    // Grant를 올리고 나서 7일 후부터 후원을 시작할 수 있다
    function grantDelay() public pure returns (uint256) {
        return 604800;
    }

    // 실제로 후원이 가능한 기간 30일
    function grantPeriod() public pure returns(uint256){
        return 2419200;
    }

    function grantStart() public view returns(uint256){
        return proposal.grantStart;
    }

    // 후원이 종료되는 날짜(timestamp로 반환)
    function grantDeadline() public view returns(uint256){
        return proposal.grantDeadline;
    }

    // 이 그랜트의 제안자를 반환
    function grantProposer() public view returns(address){
        return proposal.owner;
    }

    // 특정 사용자가 이 Grant에 후원한 금액을 반환
    function balanceOf(address _addr) public view returns(uint256){
        return amountPerSponsor[_addr];
    }

    // 이 Grant에 후원한 총 금액을 반환
    function getTotalAmount() public view returns(uint256){
        return totalAmount;
    }
    // 이 Grant에 후원한 총 사람의 수를 반환
    function getTotalSponsors() public view returns(uint256){
        return sponsors.length;
    }

    // 그랜트를 제안하기
    function propose(address _addr, string memory _title, string memory _description) public StatusChange returns(uint256){
        // 사용자 접근제어 만들기
        address proposer = _addr;
        uint256 grantId = hashGrant(proposer,_title,_description);
        uint256 currentTime = block.timestamp;

        proposal.grantStart = currentTime + grantDelay();
        proposal.grantDeadline = currentTime + grantDelay() + grantPeriod();
        proposal.owner = proposer;
        proposal.grantId = grantId;

        emit GrantPropose(proposer, grantId, grantStart());
    
        return grantId;
    }

    // 그랜트에 후원하기
    function funding(address _addr, uint256 _amount) public StatusChange returns(uint256){
        require(_amount > 0, "amount is zero");
        require(proposalstatus == ProposalStatus.Active, "The Status of The Grant is not Active");

        address sponsor = _addr;

        // 처음 후원한 후원자
        if(amountPerSponsor[sponsor]==0){
            sponsors.push(sponsor);
            //totalSponsors++;
        }
        amountPerSponsor[sponsor] += _amount;
        totalAmount += _amount;
        

        emit GrantFunding(sponsor, _amount, block.timestamp);

        return _amount;
    }

    // 이 Grant의 현재 상태를 반환
    function state() public view returns (string memory) {

        if(proposalstatus == ProposalStatus.Active){
            return "Active";
        }else if(proposalstatus == ProposalStatus.Pending){
            return "Pending";
        }else if(proposalstatus == ProposalStatus.Distributed){
            return "Distributed";
        }else{
            return "Canceld";
        }

    }

    
    // 후원이 시작되기전 그랜트를 취소하기
    function cancel() public view returns(uint256){
        require(msg.sender == proposal.owner, "go back");
        require(proposalstatus == ProposalStatus.Pending, "go back");

        proposalstatus == ProposalStatus.Canceld;
        return proposal.grantId;
    }

    function calculateQuadraticFuding() public StatusChange returns(uint256){
        require(proposalstatus == ProposalStatus.Distributed);

        uint256 sum = 0;
        uint256 length = sponsors.length;
        for(uint i=0; i<length; i++){
            
            uint256 sqrtAmount = Math.sqrt(amountPerSponsor[sponsors[i]]);
            sum += sqrtAmount;
        }
        (bool success, uint256 result) = Math.tryMul(sum,sum);
        require(success,"Overflowed");
        
        return result;
    }
}