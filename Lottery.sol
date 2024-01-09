// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public participants;

    uint public roundEndTime;
    bool public isRoundActive;

    event WinnerSelected(address indexed winner, uint prizeAmount);

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }

    modifier onlyBeforeRoundEnd() {
        require(block.timestamp < roundEndTime, "Round has ended");
        _;
    }

    modifier onlyAfterRoundEnd() {
        require(block.timestamp >= roundEndTime, "Round has not ended yet");
        _;
    }

    constructor(uint _roundDurationDays) {
        manager = payable(msg.sender);
        roundEndTime = block.timestamp + _roundDurationDays * 1 days;
        isRoundActive = true;
    }

    receive() external payable {
        require(msg.value == 1 ether, "Must send 1 ether to participate");
        require(isRoundActive, "Round is not active");
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        require(msg.sender == manager, "Only the manager can call this function");
        return address(this).balance;
    }

    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.basefee, block.timestamp, participants.length)));
    }

    function selectWinner() public onlyManager onlyAfterRoundEnd {
        require(participants.length >= 3, "Not enough participants to select a winner");
        uint r = random();
        address payable winner = participants[r % participants.length];
        emit WinnerSelected(winner, getBalance());
        winner.transfer(getBalance() * 9 / 10); // 90% to the winner
        payable(manager).transfer(getBalance()); // 10% to the manager for organizing
        participants = new address payable[](0);
        roundEndTime += 7 days; // Extend the round duration for the next round
        isRoundActive = true;
    }

    function endRound() public onlyManager onlyBeforeRoundEnd {
        isRoundActive = false;
        roundEndTime = block.timestamp; // End the round immediately
    }
}
