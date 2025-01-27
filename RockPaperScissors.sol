// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.0;

contract Freezable{
    //inizializzata di default a false
    bool private frozen;

    //notifica per il frontend del freeze
    event Frozen();

    modifier notFrozen() {
        require(!frozen, "Contract is frozen");
        _;
    }

    function freeze() internal {
        frozen = true;
        emit Frozen();
    }

}

contract RockPaperScissors is Freezable{
    enum Move { None, Rock, Paper, Scissors }

    address public player1;
    address public player2;
    address public owner;
    uint256 public betAmount;

    uint256 public deadline;
    uint256 public creationTime;
    bool public gameActive;

    bytes32 public hashedMove1;  //di default è 0x0
    bytes32 public hashedMove2;

    Move public revealedMove1; //di default a None
    Move public revealedMove2;

    constructor(address _player1, address _player2,
     uint256 _betAmount) payable {
        require(_player1 != _player2, 
        "Players must be different addresses");
        owner=msg.sender;
        player1 = _player1;
        player2 = _player2;
        betAmount = _betAmount;
        creationTime = block.timestamp;
    }

    modifier onlyPlayers() {
        require(msg.sender == player1 || 
        msg.sender == player2,
         "Only players can call this function");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner,
         "Only the owner can call this function");
        _;
    }

    event GameResult(string result);
    event GameStarted(string reminder);

    function submitHashedMove(bytes32 _hashedMove)
     external payable onlyPlayers notFrozen {
        require(msg.value == betAmount,
         "Must send the bet amount");

        if (msg.sender == player1) {
            //se il require fallisce i 
            //fondi inviati non sono restituiti
            require(hashedMove1 == bytes32(0),
            "Player 1 has already submitted a move");
            hashedMove1 = _hashedMove;
        } else if (msg.sender == player2) {
            require(hashedMove2 == bytes32(0), 
            "Player 2 has already submitted a move");
            hashedMove2 = _hashedMove;
        }
        if(deadline==0){
            //avverte i player e il frontend che uno
            //dei 2 player ha effettuato la prima mossa
            emit GameStarted("Match started"); 
            gameActive=true;                
        }
        // Imposta la deadline per la partita
        deadline = block.timestamp + 1 hours; 
    }

    function revealMove(Move _move, string calldata _secret)
     external onlyPlayers notFrozen {
        require(deadline != 0 && block.timestamp <= deadline &&
         hashedMove1!=bytes32(0) && hashedMove2!=bytes32(0),
        "Reveal phase has expired or it hasn't started");

        if (msg.sender == player1) {
            require(keccak256(abi.encodePacked
            (uint256(_move), _secret)) == hashedMove1,
             "Invalid move or secret for Player 1");
            require(revealedMove1 == Move.None, 
            "Player 1 has already revealed their move");
            revealedMove1 = _move;
        } else if (msg.sender == player2) {
            require(keccak256(abi.encodePacked
            (uint256(_move), _secret)) == hashedMove2, 
            "Invalid move or secret for Player 2");
            require(revealedMove2 == Move.None, 
            "Player 2 has already revealed their move");
            revealedMove2 = _move;
        }

        if (revealedMove1 != Move.None && 
        revealedMove2 != Move.None) {
            determineWinner();
        }
    }

    //in caso uno dei 2 player non riveli la sua mossa
    // l'altro può richiedere un timeout dopo lo scadere del timer
    function claimTimeout() external onlyPlayers notFrozen {
        require(gameActive==true, "Game is not active yet");
        require(block.timestamp > deadline,
         "Reveal phase has not expired yet");
        // solo player 2 ha rivelato
        if (revealedMove1 == Move.None && revealedMove2!=Move.None) {
            payable(player2).transfer(address(this).balance);
            emit GameResult("Player 2 wins");
        // solo player 1 ha rivelato
        } else if (revealedMove2 == Move.None && revealedMove1!=Move.None) {
            payable(player1).transfer(address(this).balance);
            emit GameResult("Player 1 wins");
        //solo player 2 ha depositato
        } else if(hashedMove1==bytes32(0) && hashedMove2!=bytes32(0)){
            payable(player2).transfer(address(this).balance);
            emit GameResult("Player 2 wins");
        //solo player 1 ha depositato
        }else if(hashedMove2==bytes32(0) && hashedMove1!=bytes32(0)){
            payable(player1).transfer(address(this).balance);
            emit GameResult("Player 1 wins");
        //entrambi hanno depositato, nessuno ha rivelato
        }else if(hashedMove1!=bytes32(0) && hashedMove2!=bytes32(0)){
            payable(player1).transfer(betAmount);
            payable(player2).transfer(betAmount);
            emit GameResult("Draw");
        }
        freeze();
    }

    function determineWinner() private {
        if (revealedMove1 == revealedMove2) {
            // Pareggio: restituisce i depositi
            payable(player1).transfer(betAmount);
            payable(player2).transfer(betAmount);
            emit GameResult("Draw");
        } else if (
            (revealedMove1 == Move.Rock && 
            revealedMove2 == Move.Scissors) ||
            (revealedMove1 == Move.Paper && 
            revealedMove2 == Move.Rock) ||
            (revealedMove1 == Move.Scissors && 
            revealedMove2 == Move.Paper)
        ) {
            // Player 1 vince
            payable(player1).transfer(address(this).balance);
            emit GameResult("Player 1 wins");
        } else {
            // Player 2 vince
            payable(player2).transfer(address(this).balance);
            emit GameResult("Player 2 wins");
        }

        freeze();
    }

    function claimCreationTimeout() 
    external onlyOwner notFrozen{
        require(block.timestamp > (creationTime + 1 days),
        "Creation timeout has not expired");
        emit GameResult("Contract withdrawed");
        freeze();
    }

    //ATTENZIONE:Questi metodi servono SOLO in fase di testing
    //in quanto negli unit test di Remix non è possibile
    //avanzare artificialmente il tempo

    function setDeadline(uint256 _deadline)
    public onlyOwner{
        deadline=_deadline;
    }

    function setCreationTime(uint256 _creationTime) 
    public onlyOwner{
        creationTime=_creationTime;
    }

}
