// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; 

contract Quiz{
    struct Quiz_item {
        uint id;
        bytes question;
        bytes answer;
        uint min_bet;
        uint max_bet;
    }
    
    address public owner;   // Quiz Owner Contract
    uint public quizsCount; // Quiz Item Trakcing SV
    uint public vault_balance; // Quiz Foundation Vault Tracking SV
    
    
    mapping(uint => Quiz_item) public quizsItems;   // Quit Items SV
    mapping(address => uint256)[] public bets;  // Quiz Solution Bet SV
    mapping (address => uint256) internal _prize;   // Quiz Solution cache prize SV

    // modifier 
    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    constructor () {
        owner = msg.sender;
        bets.push();

        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    /* @getter */
    function getAnswer(uint quizId) public view onlyOwner returns (bytes memory){
        Quiz_item memory quiz = quizsItems[quizId];
        return quiz.answer;
    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        Quiz_item memory quiz = quizsItems[quizId];
        quiz.answer = "";
        return quiz;
    }

    function getQuizNum() public view returns (uint){
        return quizsCount;
    }

    /* @setter */
    function addQuiz(Quiz_item memory q) public onlyOwner{
        {
            uint __quizIndex = q.id;
            require(__quizIndex > 0, "quizId must be greater than 0");
            quizsItems[__quizIndex] = q;
            
        }
        unchecked {
            quizsCount++;
        }

    }
    
    function betToPlay(uint quizId) public payable {
        require(quizId > 0, "quizId must be greater than 0");
        Quiz_item memory quiz = quizsItems[quizId];
        {
            uint __betBalance = msg.value;
            require(quiz.min_bet <= __betBalance && __betBalance <= quiz.max_bet);
            bets[quizId - 1][msg.sender] += __betBalance; 
        }
    }

    function solveQuiz(uint quizId, bytes memory ans) public returns (bool) {
        require(quizId > 0, "quizId must be greater than 0");
        Quiz_item memory quiz = quizsItems[quizId];
        {
            uint __quizIndex = (quizId - 1);
            if(keccak256(bytes(quiz.answer)) != keccak256(bytes(ans))){
                vault_balance += bets[__quizIndex][msg.sender];
                bets[__quizIndex][msg.sender] = 0;
                return false;
            }

            _prize[msg.sender] += (bets[__quizIndex][msg.sender] << 1);
            return true;
        }
    }

    function claim() public {
        require(_prize[msg.sender] > 0, "You have no prize to claim go solve!");
        {
            uint256 __prize = _prize[msg.sender];
            _prize[msg.sender] = 0;
            vault_balance -= __prize;
            payable(msg.sender).transfer(__prize);
        }
    }
    receive() external payable{
        vault_balance += msg.value; // Quiz Foundation deposit ether (donation!)
    }

    /* util functions */
    function _checkOwner() internal view virtual {
        require(msg.sender == owner, "Ownable: caller is not the owner");
    }
}
