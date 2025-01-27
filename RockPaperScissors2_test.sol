// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.0;

import "remix_tests.sol"; 
import "../contracts/RockPaperScissors.sol";
import "./PlayerProxy.sol";

contract RockPaperScissorsTest2{
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

    //Test per revealMove che termina
    //la partita con la vittoria di player1
    function testRevealMove() public payable{
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
        Assert.equal(uint256(game.revealedMove1()),
        uint256(1),"The move should be Rock");
        //reveal di player2
        Player2.callRevealMove(address(game), 3,
         "mySecret2");//3=Scissors
        Assert.equal(uint256(game.revealedMove2()),
        uint256(3),"The move should be Scissors");
        Assert.equal(player1.balance,(2*betAmount),
        "The winner should have collected the bets");
    }

    //Test per documentare l'errore in caso ci sia
    //un tentativo di doppia rivelazione da parte
    //di un player
    function testDoubleReveal() public payable {
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
        //doppio reveal di player1
        Player1.callRevealMove(address(game), 1,
         "mySecret");//1=Rock
        try Player1.callRevealMove(address(game), 1,
         "mySecret"){
            Assert.ok(false,"It should raise an error");
        }catch{
            Assert.ok(true,"");
        }
    }

    function testRevealingBeforeDepositing() public payable{
        try Player1.callRevealMove(address(game), 1,
         "mySecret"){
            Assert.ok(false,"It should raise an error");
        }catch{
            Assert.ok(true,"");
        }
    }

    //Test per il fallimento del require che richiede
    //che entrambi i player abbiano effettuato il submit
    function testRevealingBeforeRevealPhase() public payable{
        //deposito player1
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        try Player1.callRevealMove(address(game), 1,
         "mySecret"){
            Assert.ok(false,"It should raise an error");
        }catch{
            Assert.ok(true,"");
        }
    }

    //Test claim dove solo player2 deposita
    function testClaimTimeout1() public payable{
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player2.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        //simulo il passare del tempo
        game.setDeadline(block.timestamp-1);
        Player2.callClaimTimeout(address(game));
        Assert.equal(player2.balance, betAmount,
        "Player 2 should have got the funds back");
    }

    //Test claim dove solo player1 deposita
    function testClaimTimeout2() public payable{
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        game.setDeadline(block.timestamp-1);
        Player1.callClaimTimeout(address(game));
        Assert.equal(player1.balance, betAmount,
        "Player 1 should have got the funds back");
    }

    //Test claim dove entrambi depositano, nessuno rivela
    function testClaimTimeout3() public payable{
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        Player2.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        game.setDeadline(block.timestamp-1);
        Player1.callClaimTimeout(address(game));
        Assert.equal(player1.balance, betAmount,
        "Player 1 should have got the funds back");
        Assert.equal(player2.balance, betAmount,
        "Player 2 should have got the funds back");
    }
    //Test claim dove solo player2 rivela
    function testClaimTimeout4() public payable{
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
        //reveal di player2
        Player2.callRevealMove(address(game), 3,
         "mySecret2");//1=Rock
        game.setDeadline(block.timestamp-1);
        Player2.callClaimTimeout(address(game));
        Assert.equal(player2.balance, (2*betAmount),
        "Player 2 should have got the funds");
    }
}