// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.0;

import "remix_tests.sol"; 
import "../contracts/RockPaperScissors.sol";
import "./PlayerProxy.sol";

contract RockPaperScissorsTest{
    RockPaperScissors game;
    address player1;
    PlayerProxy Player1;
    address player2;
    PlayerProxy Player2;
    uint256 betAmount = 1 wei;
    
    // Funzione di setup, eseguita prima di ogni test 
    ///#value: 2
    function beforeEach() public payable {
        Assert.equal(msg.value,(2*betAmount),
        "Il valore inviato non sufficiente");
        Player1= new PlayerProxy();
        player1=address (Player1);
        Player2= new PlayerProxy();
        player2=address (Player2);
        Assert.equal(player1,address(Player1),
        "Operation Failed");
        game = new RockPaperScissors(player1,
         player2, betAmount);
    }

    // Test per verificare l'inizializzazione
    function testInitialization() public {
        Assert.equal(game.player1(), player1, 
        "Player 1 should be initialized correctly");
        Assert.equal(game.player2(), player2, 
        "Player 2 should be initialized correctly");
        Assert.equal(game.betAmount(), betAmount, 
        "Bet amount should be initialized correctly");
    }

    //Test per verificare il requirement per
    //2 player diversi
    function testSameAddressPlayers() public{
        try new RockPaperScissors(player1, player1, betAmount){
            Assert.ok(false, "Expected revert");
        }catch Error(string memory reason){
            Assert.equal(reason, 
            "Players must be different addresses",
            "Unexpected revert reason");
        }
    }

    // Test per verificare l'inserimento dell'hash di una mossa
    // per entrambi i player e la loro bet
    function testSubmitHashedMove() public payable {
        //deposito player1
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        Assert.equal(game.hashedMove1(), hashedMove, 
        "Hashed move for Player 1 should be stored");
        //deposito player2
        hashedMove= keccak256(abi.encodePacked
        (uint256(2), "mySecret2"));
        Player2.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        Assert.equal(game.hashedMove2(), hashedMove, 
        "Hashed move for Player 2 should be stored");
        uint256 gameBalance=address(game).balance;
        uint256 expectedBalance=2*betAmount;
        Assert.equal(gameBalance, expectedBalance,
        "The game should have collected the bets");
    }

    //Test per verificare errore dopo l'invio di
    //una mossa 2 volte da parte di un player
    function testDoubleSubmit() public payable{
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        try Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        ){
            Assert.ok(false,"Expected revert");
        }catch Error(string memory reason){
            Assert.equal(reason, 
            "Call to submitHashedMove failed",
            "Reverted for other reasons");
        }

    }

    //Test per verificare il modifier
    //onlyPlayers
    function testWrongSenderAddressOperation() 
    public payable{
        PlayerProxy Player3= new PlayerProxy();
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        //un terzo address tenta di inviare la mossa
        try Player3.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        ){
            Assert.ok(false, "Expected revert");
        }catch{
            Assert.ok(true, "");//se solleva errore ok
        }
    }

    //Test per il modifier notFrozen che 
    //si attiva una volta che è stato determinato
    //il vincitore e non permette più alcuna
    //chiamata a funzione che ha nella firma
    //tale modifier 
    function testFreeze() public payable{
        //deposito player1
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        //deposito player2
        hashedMove= keccak256(abi.encodePacked
        (uint256(3), "mySecret2"));
        Player2.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        //reveal di player1
        Player1.callRevealMove(address(game), 1,
         "mySecret");//1=Rock
        //reveal di player2
        Player2.callRevealMove(address(game), 3,
         "mySecret2");//3=Scissors
        try Player1.callRevealMove(address(game), 1,
         "mySecret"){
            Assert.ok(false,"Expected error");
        }catch{
            Assert.ok(true,"");
        }
    }
}   